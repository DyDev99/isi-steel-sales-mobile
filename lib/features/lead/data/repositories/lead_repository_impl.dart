import 'package:isi_steel_sales_mobile/features/lead/data/datasources/mock/mock_lead_data.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/activity_log_item.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead_document.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/notification_item.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/opportunity_info.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_summary.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/won_info.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/repositories/lead_repository.dart';

/// In-memory mock backend for the sales pipeline. Seeded once at
/// construction and mutated in place, so state (moves, notes, documents)
/// persists across navigation for the lifetime of the app session. This is
/// a singleton in DI (unlike the `const` HomeRepositoryImpl) precisely
/// because it needs to hold mutable state.
class LeadRepositoryImpl implements LeadRepository {
  LeadRepositoryImpl() : _leads = MockLeadData.generate() {
    _notifications = MockLeadData.buildNotifications(_leads);
    for (final lead in _leads) {
      _activity[lead.id] = MockLeadData.buildActivity(lead);
    }
  }

  final List<Lead> _leads;
  final Map<String, List<ActivityLogItem>> _activity = {};
  late List<NotificationItem> _notifications;

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 300));

  @override
  Future<List<Lead>> fetchLeads() async {
    await _latency();
    return List.unmodifiable(_leads);
  }

  @override
  Future<Lead> getById(String id) async {
    await _latency();
    return _leads.firstWhere((l) => l.id == id);
  }

  @override
  Future<void> createLead(Lead lead) async {
    await _latency();
    _leads.insert(0, lead);
    _activity[lead.id] = MockLeadData.buildActivity(lead);
  }

  @override
  Future<void> updateLead(Lead lead) async {
    await _latency();
    final index = _leads.indexWhere((l) => l.id == lead.id);
    if (index != -1) _leads[index] = lead;
  }

  @override
  Future<void> deleteLead(String id) async {
    await _latency();
    _leads.removeWhere((l) => l.id == id);
    _activity.remove(id);
  }

  @override
  Future<void> moveStage({
    required String id,
    required PipelineStage toStage,
    OpportunityInfo? opportunityInfo,
    WonInfo? wonInfo,
  }) async {
    await _latency();
    final index = _leads.indexWhere((l) => l.id == id);
    if (index == -1) return;
    final lead = _leads[index];
    _leads[index] = lead.copyWith(
      stage: toStage,
      opportunityInfo: opportunityInfo,
      wonInfo: wonInfo,
      expectedRevenue: opportunityInfo?.estimatedValue,
      currentRevenue: wonInfo?.finalValue,
    );
    _activity[id] = [
      ActivityLogItem(
        id: '$id-ACT-${DateTime.now().microsecondsSinceEpoch}',
        kind: ActivityLogKind.stageChanged,
        title: 'Stage changed',
        description:
            '${lead.companyName} moved from ${lead.stage.label} to ${toStage.label}.',
        timestamp: DateTime.now(),
        actor: 'You',
      ),
      ...?_activity[id],
    ];
  }

  @override
  Future<void> reorder({
    required PipelineStage stage,
    required int oldIndex,
    required int newIndex,
  }) async {
    await _latency();
    final columnLeads = _leads.where((l) => l.stage == stage).toList();
    if (oldIndex < 0 || oldIndex >= columnLeads.length) return;
    final moved = columnLeads.removeAt(oldIndex);
    columnLeads.insert(newIndex.clamp(0, columnLeads.length), moved);

    // Splice the reordered column back into the flat list, preserving the
    // relative order of every other stage untouched.
    final result = <Lead>[];
    final columnIterator = columnLeads.iterator;
    for (final lead in _leads) {
      if (lead.stage == stage) {
        columnIterator.moveNext();
        result.add(columnIterator.current);
      } else {
        result.add(lead);
      }
    }
    _leads
      ..clear()
      ..addAll(result);
  }

  @override
  Future<PipelineSummary> fetchSummary() async {
    await _latency();
    final totalLeads =
        _leads.where((l) => l.stage == PipelineStage.leads).length;
    final totalOpportunities =
        _leads.where((l) => l.stage == PipelineStage.opportunities).length;
    final wonCustomers =
        _leads.where((l) => l.stage == PipelineStage.won).length;
    final potentialRevenue = _leads
        .where((l) => l.stage != PipelineStage.won)
        .fold<double>(0, (sum, l) => sum + l.expectedRevenue);
    final wonRevenue = _leads
        .where((l) => l.stage == PipelineStage.won)
        .fold<double>(0, (sum, l) => sum + l.currentRevenue);
    final conversionRate = _leads.isEmpty ? 0.0 : wonCustomers / _leads.length;

    return PipelineSummary(
      totalLeads: totalLeads,
      totalOpportunities: totalOpportunities,
      wonCustomers: wonCustomers,
      potentialRevenue: potentialRevenue,
      wonRevenue: wonRevenue,
      conversionRate: conversionRate,
    );
  }

  @override
  Future<List<ActivityLogItem>> fetchActivity(String leadId) async {
    await _latency();
    return List.unmodifiable(_activity[leadId] ?? const []);
  }

  @override
  Future<void> addActivity(String leadId, ActivityLogItem item) async {
    await _latency();
    _activity[leadId] = [item, ...?_activity[leadId]];
  }

  @override
  Future<void> addDocument(String leadId, LeadDocument document) async {
    await _latency();
    final index = _leads.indexWhere((l) => l.id == leadId);
    if (index == -1) return;
    final lead = _leads[index];
    _leads[index] = lead.copyWith(documents: [...lead.documents, document]);
  }

  @override
  Future<void> addNote(String leadId, String note) async {
    await _latency();
    final index = _leads.indexWhere((l) => l.id == leadId);
    if (index == -1) return;
    final lead = _leads[index];
    _leads[index] = lead.copyWith(notes: [...lead.notes, note]);
  }

  @override
  Future<List<NotificationItem>> fetchNotifications() async {
    await _latency();
    return List.unmodifiable(_notifications);
  }
}
