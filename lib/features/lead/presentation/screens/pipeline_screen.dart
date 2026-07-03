import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/aurora_background.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user_role.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/lead_detail_cubit.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_bloc.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_event.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_state.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/screens/lead_detail_screen.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/lead_card.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/lead_form_sheet.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/move_stage_sheet.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/pipeline_column.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/pipeline_filter_sheet.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/pipeline_search_filter_bar.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/pipeline_summary_row.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/send_to_hq_sheet.dart';

/// The Kanban sales-pipeline board: Leads -> Opportunities -> Won.
/// [initialStage] just decides which column the mobile single-column view
/// opens on (used so the "Leads" and "Opps" bottom-nav tabs both land on
/// this same board, focused on their respective stage).
class PipelineScreen extends StatelessWidget {
  const PipelineScreen({super.key, this.initialStage = PipelineStage.leads});
  final PipelineStage initialStage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vibe.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          SafeArea(
            child: BlocConsumer<PipelineBloc, PipelineState>(
              listenWhen: (prev, curr) =>
                  curr is PipelineLoaded && curr.blockedMoveMessage != null,
              listener: (context, state) {
                if (state is PipelineLoaded && state.blockedMoveMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.blockedMoveMessage!)),
                  );
                }
              },
              builder: (context, state) => switch (state) {
                PipelineLoaded() => _Board(state: state, initialStage: initialStage),
                PipelineError(:final message) => _ErrorView(
                    message: message,
                    onRetry: () => context.read<PipelineBloc>().add(const PipelineLoadRequested()),
                  ),
                _ => const Center(child: CircularProgressIndicator(color: Vibe.pink)),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.state, required this.initialStage});
  final PipelineLoaded state;
  final PipelineStage initialStage;

  bool get _isAdmin => sl<SessionManager>().can(UserRole.admin);

  void _openDetail(BuildContext context, Lead lead) {
    final pipelineBloc = context.read<PipelineBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: pipelineBloc),
            BlocProvider(create: (_) => sl<LeadDetailCubit>()..load(lead.id)),
          ],
          child: LeadDetailScreen(leadId: lead.id),
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, Lead lead, LeadCardAction action) async {
    final bloc = context.read<PipelineBloc>();
    switch (action) {
      case LeadCardAction.view:
        _openDetail(context, lead);
      case LeadCardAction.edit:
        final updated = await showLeadFormSheet(context: context, existing: lead);
        if (updated != null) bloc.add(LeadUpdated(updated));
      case LeadCardAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Vibe.bgSoft,
            title: const Text('Delete lead?', style: TextStyle(color: Vibe.text)),
            content: Text('This removes ${lead.companyName} from the pipeline.',
                style: const TextStyle(color: Vibe.muted)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Vibe.danger)),
              ),
            ],
          ),
        );
        if (confirmed == true) bloc.add(LeadDeleted(lead.id));
      case LeadCardAction.move:
        final result = await showMoveStageSheet(context: context, lead: lead, isAdmin: _isAdmin);
        if (result != null) {
          bloc.add(LeadMoved(
            leadId: lead.id,
            toStage: result.toStage,
            opportunityInfo: result.opportunityInfo,
            wonInfo: result.wonInfo,
          ));
        }
      case LeadCardAction.sendToHq:
        final updated = await showSendToHqSheet(context: context, lead: lead);
        if (updated != null) bloc.add(LeadUpdated(updated));
    }
  }

  Future<void> _handleDrop(BuildContext context, Lead dragged, PipelineStage toStage) async {
    if (dragged.stage == toStage) return;
    // The bloc re-validates via canMoveStage and surfaces a snackbar itself
    // if the transition isn't allowed. Dropping straight onto a target
    // stage already tells us the target, so this skips the picker list and
    // goes straight to whichever conversion sheet (if any) that stage needs.
    final result = await resolveStageMove(context: context, lead: dragged, toStage: toStage);
    if (result == null || !context.mounted) return;
    context.read<PipelineBloc>().add(LeadMoved(
          leadId: dragged.id,
          toStage: result.toStage,
          opportunityInfo: result.opportunityInfo,
          wonInfo: result.wonInfo,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final territories = state.allLeads.map((l) => l.territory).toSet().toList()..sort();
    final reps = state.allLeads.map((l) => l.assignedRepName).toSet().toList()..sort();

    return RefreshIndicator(
      color: Vibe.pink,
      backgroundColor: Vibe.bgSoft,
      onRefresh: () async => context.read<PipelineBloc>().add(const PipelineLoadRequested()),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 0.h, 20.w, 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PipelineSearchFilterBar(
              onSearchChanged: (q) => context.read<PipelineBloc>().add(SearchChanged(q)),
              onFilterTap: () => showPipelineFilterSheet(
                context: context,
                filter: state.filter,
                territories: territories,
                reps: reps,
                onApply: (f) {
                  final bloc = context.read<PipelineBloc>();
                  bloc.add(FilterChanged(
                    territory: () => f.territory,
                    assignedRepName: () => f.assignedRepName,
                    priority: () => f.priority,
                    visibleStages: f.visibleStages,
                  ));
                  bloc.add(SortChanged(f.sortBy));
                },
              ),
              hasActiveFilters: !state.filter.isEmpty,
              onAddLead: () async {
                final created = await showLeadFormSheet(context: context);
                if (created != null && context.mounted) {
                  context.read<PipelineBloc>().add(LeadCreated(created));
                }
              },
            ),
            SizedBox(height: 16.h),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 760;
                final columns = PipelineStage.values
                    .map((stage) => PipelineColumn(
                          stage: stage,
                          leads: state.columns[stage] ?? const [],
                          onCardTap: (lead) => _openDetail(context, lead),
                          onCardAction: (lead, action) => _handleAction(context, lead, action),
                          onDroppedOnColumn: (dragged) => _handleDrop(context, dragged, stage),
                          onDroppedOnCard: (dragged, index) {
                            if (dragged.stage == stage) {
                              final oldIndex = (state.columns[stage] ?? const [])
                                  .indexWhere((l) => l.id == dragged.id);
                              if (oldIndex != -1) {
                                context
                                    .read<PipelineBloc>()
                                    .add(LeadReordered(stage: stage, oldIndex: oldIndex, newIndex: index));
                              }
                            } else {
                              _handleDrop(context, dragged, stage);
                            }
                          },
                        ))
                    .toList();

                const boardHeight = 720.0;
                if (isWide) {
                  return SizedBox(
                    height: boardHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < columns.length; i++) ...[
                          if (i > 0) const SizedBox(width: 14),
                          Expanded(child: columns[i]),
                        ],
                      ],
                    ),
                  );
                }
                return SizedBox(
                  height: boardHeight,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: columns.length,
                    controller: ScrollController(
                      initialScrollOffset: PipelineStage.values.indexOf(initialStage) * 300.0,
                    ),
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) => SizedBox(width: 300, child: columns[i]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: Vibe.muted, size: 40),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Vibe.muted)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text('Try again', style: TextStyle(color: Vibe.pink, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
