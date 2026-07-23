import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user_role.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_filter.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_summary.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/pipeline_rules.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/create_lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/delete_lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/fetch_leads.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/fetch_pipeline_summary.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/lead_id_params.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/lead_usecase.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/move_lead_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/reorder_leads.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/update_lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_event.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_state.dart';

class PipelineBloc extends Bloc<PipelineEvent, PipelineState> {
  PipelineBloc({
    required FetchLeads fetchLeads,
    required FetchPipelineSummary fetchPipelineSummary,
    required MoveLeadStage moveLeadStage,
    required ReorderLeads reorderLeads,
    required DeleteLead deleteLead,
    required CreateLead createLead,
    required UpdateLead updateLead,
    required SessionManager sessionManager,
  })  : _fetchLeads = fetchLeads,
        _fetchPipelineSummary = fetchPipelineSummary,
        _moveLeadStage = moveLeadStage,
        _reorderLeads = reorderLeads,
        _deleteLead = deleteLead,
        _createLead = createLead,
        _updateLead = updateLead,
        _sessionManager = sessionManager,
        super(const PipelineInitial()) {
    on<PipelineLoadRequested>(_onLoad);
    on<LeadMoved>(_onMoved, transformer: droppable());
    on<LeadReordered>(_onReordered, transformer: droppable());
    on<LeadDeleted>(_onDeleted, transformer: droppable());
    on<LeadCreated>(_onCreated, transformer: droppable());
    on<LeadUpdated>(_onUpdated, transformer: droppable());
    on<SearchChanged>(_onSearchChanged);
    on<FilterChanged>(_onFilterChanged);
    on<SortChanged>(_onSortChanged);
  }

  final FetchLeads _fetchLeads;
  final FetchPipelineSummary _fetchPipelineSummary;
  final MoveLeadStage _moveLeadStage;
  final ReorderLeads _reorderLeads;
  final DeleteLead _deleteLead;
  final CreateLead _createLead;
  final UpdateLead _updateLead;
  final SessionManager _sessionManager;

  bool get _isAdmin => _sessionManager.can(UserRole.admin);

  Future<void> _onLoad(
      PipelineLoadRequested event, Emitter<PipelineState> emit) async {
    emit(const PipelineLoading());
    try {
      final leads = await _fetchLeads(const NoParams());
      final summary = await _fetchPipelineSummary(const NoParams());
      const filter = PipelineFilter();
      emit(PipelineLoaded(
        allLeads: leads,
        columns: _computeColumns(leads, filter),
        filter: filter,
        summary: summary,
      ));
    } catch (_) {
      emit(const PipelineError("Couldn't load the pipeline"));
    }
  }

  Future<void> _onMoved(LeadMoved event, Emitter<PipelineState> emit) async {
    final current = state;
    if (current is! PipelineLoaded) return;

    final lead = current.allLeads.firstWhere((l) => l.id == event.leadId,
        orElse: () => current.allLeads.first);
    if (!canMoveStage(lead.stage, event.toStage, isAdmin: _isAdmin)) {
      emit(current.copyWith(
        blockedMoveMessage: () =>
            moveBlockedReason(lead.stage, event.toStage, isAdmin: _isAdmin),
      ));
      return;
    }

    // Optimistic update first, repository call second. Converting to an
    // Opportunity or marking Won carries the one value captured in that
    // sheet along with the stage change; it also keeps the card's revenue
    // figure (expectedRevenue/currentRevenue) consistent with it.
    final updatedLeads = [
      for (final l in current.allLeads)
        if (l.id == event.leadId)
          l.copyWith(
            stage: event.toStage,
            opportunityInfo: event.opportunityInfo,
            wonInfo: event.wonInfo,
            expectedRevenue: event.opportunityInfo?.estimatedValue,
            currentRevenue: event.wonInfo?.finalValue,
          )
        else
          l,
    ];
    emit(current.copyWith(
      allLeads: updatedLeads,
      columns: _computeColumns(updatedLeads, current.filter),
      summary: _computeSummary(updatedLeads),
      blockedMoveMessage: () => null,
    ));

    try {
      await _moveLeadStage(MoveLeadStageParams(
        leadId: event.leadId,
        toStage: event.toStage,
        opportunityInfo: event.opportunityInfo,
        wonInfo: event.wonInfo,
      ));
    } catch (_) {
      // Roll back on failure.
      emit(current.copyWith(
          blockedMoveMessage: () =>
              'leads.couldnt_move'.trParams({'company': lead.companyName})));
    }
  }

  Future<void> _onReordered(
      LeadReordered event, Emitter<PipelineState> emit) async {
    final current = state;
    if (current is! PipelineLoaded) return;

    final column = List<Lead>.from(current.columns[event.stage] ?? const []);
    if (event.oldIndex < 0 || event.oldIndex >= column.length) return;
    final moved = column.removeAt(event.oldIndex);
    column.insert(event.newIndex.clamp(0, column.length), moved);

    emit(current.copyWith(columns: {...current.columns, event.stage: column}));

    try {
      await _reorderLeads(
        ReorderLeadsParams(
            stage: event.stage,
            oldIndex: event.oldIndex,
            newIndex: event.newIndex),
      );
    } catch (_) {
      // Best-effort; the in-memory mock backend doesn't fail in practice.
    }
  }

  Future<void> _onDeleted(
      LeadDeleted event, Emitter<PipelineState> emit) async {
    final current = state;
    if (current is! PipelineLoaded) return;

    final updatedLeads =
        current.allLeads.where((l) => l.id != event.leadId).toList();
    emit(current.copyWith(
      allLeads: updatedLeads,
      columns: _computeColumns(updatedLeads, current.filter),
      summary: _computeSummary(updatedLeads),
    ));

    try {
      await _deleteLead(LeadIdParams(event.leadId));
    } catch (_) {
      // Best-effort; the in-memory mock backend doesn't fail in practice.
    }
  }

  Future<void> _onCreated(
      LeadCreated event, Emitter<PipelineState> emit) async {
    final current = state;
    if (current is! PipelineLoaded) return;

    final updatedLeads = [event.lead, ...current.allLeads];
    emit(current.copyWith(
      allLeads: updatedLeads,
      columns: _computeColumns(updatedLeads, current.filter),
      summary: _computeSummary(updatedLeads),
    ));

    try {
      await _createLead(event.lead);
    } catch (_) {
      // Best-effort; the in-memory mock backend doesn't fail in practice.
    }
  }

  Future<void> _onUpdated(
      LeadUpdated event, Emitter<PipelineState> emit) async {
    final current = state;
    if (current is! PipelineLoaded) return;

    final updatedLeads = [
      for (final l in current.allLeads)
        if (l.id == event.lead.id) event.lead else l,
    ];
    emit(current.copyWith(
      allLeads: updatedLeads,
      columns: _computeColumns(updatedLeads, current.filter),
      summary: _computeSummary(updatedLeads),
    ));

    try {
      await _updateLead(event.lead);
    } catch (_) {
      // Best-effort; the in-memory mock backend doesn't fail in practice.
    }
  }

  void _onSearchChanged(SearchChanged event, Emitter<PipelineState> emit) {
    final current = state;
    if (current is! PipelineLoaded) return;
    final filter = current.filter.copyWith(search: event.query);
    emit(current.copyWith(
        filter: filter, columns: _computeColumns(current.allLeads, filter)));
  }

  void _onFilterChanged(FilterChanged event, Emitter<PipelineState> emit) {
    final current = state;
    if (current is! PipelineLoaded) return;
    final filter = current.filter.copyWith(
      territory: event.territory,
      assignedRepName: event.assignedRepName,
      priority: event.priority,
      visibleStages: event.visibleStages,
    );
    emit(current.copyWith(
        filter: filter, columns: _computeColumns(current.allLeads, filter)));
  }

  void _onSortChanged(SortChanged event, Emitter<PipelineState> emit) {
    final current = state;
    if (current is! PipelineLoaded) return;
    final filter = current.filter.copyWith(sortBy: event.sortBy);
    emit(current.copyWith(
        filter: filter, columns: _computeColumns(current.allLeads, filter)));
  }

  Map<PipelineStage, List<Lead>> _computeColumns(
      List<Lead> leads, PipelineFilter filter) {
    Iterable<Lead> filtered = leads;

    if (filter.search.trim().isNotEmpty) {
      final q = filter.search.trim().toLowerCase();
      filtered = filtered.where((l) =>
          l.companyName.toLowerCase().contains(q) ||
          l.ownerName.toLowerCase().contains(q));
    }
    if (filter.territory != null) {
      filtered = filtered.where((l) => l.territory == filter.territory);
    }
    if (filter.assignedRepName != null) {
      filtered =
          filtered.where((l) => l.assignedRepName == filter.assignedRepName);
    }
    if (filter.priority != null) {
      filtered = filtered.where((l) => l.priority == filter.priority);
    }

    final sorted = filtered.toList()..sort(_comparator(filter.sortBy));

    return {
      for (final stage in PipelineStage.values)
        stage: filter.visibleStages.contains(stage)
            ? sorted.where((l) => l.stage == stage).toList()
            : const [],
    };
  }

  int Function(Lead, Lead) _comparator(SortBy sortBy) {
    return switch (sortBy) {
      SortBy.newest => (a, b) => b.createdDate.compareTo(a.createdDate),
      SortBy.oldest => (a, b) => a.createdDate.compareTo(b.createdDate),
      SortBy.revenue => (a, b) =>
          b.expectedRevenue.compareTo(a.expectedRevenue),
      SortBy.priority => (a, b) => b.priority.index.compareTo(a.priority.index),
    };
  }

  PipelineSummary _computeSummary(List<Lead> leads) {
    final totalLeads =
        leads.where((l) => l.stage == PipelineStage.leads).length;
    final totalOpportunities =
        leads.where((l) => l.stage == PipelineStage.opportunities).length;
    final wonCustomers =
        leads.where((l) => l.stage == PipelineStage.won).length;
    final potentialRevenue = leads
        .where((l) => l.stage != PipelineStage.won)
        .fold<double>(0, (sum, l) => sum + l.expectedRevenue);
    final wonRevenue = leads
        .where((l) => l.stage == PipelineStage.won)
        .fold<double>(0, (sum, l) => sum + l.currentRevenue);
    final conversionRate = leads.isEmpty ? 0.0 : wonCustomers / leads.length;

    return PipelineSummary(
      totalLeads: totalLeads,
      totalOpportunities: totalOpportunities,
      wonCustomers: wonCustomers,
      potentialRevenue: potentialRevenue,
      wonRevenue: wonRevenue,
      conversionRate: conversionRate,
    );
  }
}
