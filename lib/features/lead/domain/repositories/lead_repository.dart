import 'package:isi_steel_sales_mobile/features/lead/domain/entities/activity_log_item.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead_document.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/notification_item.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/opportunity_info.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_summary.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/won_info.dart';

abstract interface class LeadRepository {
  Future<List<Lead>> fetchLeads();
  Future<Lead> getById(String id);
  Future<void> createLead(Lead lead);
  Future<void> updateLead(Lead lead);
  Future<void> deleteLead(String id);
  Future<void> moveStage({
    required String id,
    required PipelineStage toStage,
    OpportunityInfo? opportunityInfo,
    WonInfo? wonInfo,
  });
  Future<void> reorder({
    required PipelineStage stage,
    required int oldIndex,
    required int newIndex,
  });
  Future<PipelineSummary> fetchSummary();
  Future<List<ActivityLogItem>> fetchActivity(String leadId);
  Future<void> addActivity(String leadId, ActivityLogItem item);
  Future<void> addDocument(String leadId, LeadDocument document);
  Future<void> addNote(String leadId, String note);
  Future<List<NotificationItem>> fetchNotifications();
}
