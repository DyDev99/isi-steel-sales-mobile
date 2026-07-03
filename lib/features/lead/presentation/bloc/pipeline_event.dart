import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/opportunity_info.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/priority.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_filter.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/won_info.dart';

sealed class PipelineEvent extends Equatable {
  const PipelineEvent();
  @override
  List<Object?> get props => const [];
}

final class PipelineLoadRequested extends PipelineEvent {
  const PipelineLoadRequested();
}

/// [opportunityInfo] is attached when moving Leads -> Opportunities and
/// [wonInfo] when moving Opportunities -> Won, so the one-time value
/// captured in those conversion sheets lands on the lead in the same
/// optimistic update as the stage change.
final class LeadMoved extends PipelineEvent {
  const LeadMoved({
    required this.leadId,
    required this.toStage,
    this.opportunityInfo,
    this.wonInfo,
  });
  final String leadId;
  final PipelineStage toStage;
  final OpportunityInfo? opportunityInfo;
  final WonInfo? wonInfo;
  @override
  List<Object?> get props => [leadId, toStage, opportunityInfo, wonInfo];
}

final class LeadReordered extends PipelineEvent {
  const LeadReordered({required this.stage, required this.oldIndex, required this.newIndex});
  final PipelineStage stage;
  final int oldIndex;
  final int newIndex;
  @override
  List<Object?> get props => [stage, oldIndex, newIndex];
}

final class LeadDeleted extends PipelineEvent {
  const LeadDeleted(this.leadId);
  final String leadId;
  @override
  List<Object?> get props => [leadId];
}

final class LeadCreated extends PipelineEvent {
  const LeadCreated(this.lead);
  final Lead lead;
  @override
  List<Object?> get props => [lead];
}

final class LeadUpdated extends PipelineEvent {
  const LeadUpdated(this.lead);
  final Lead lead;
  @override
  List<Object?> get props => [lead];
}

final class SearchChanged extends PipelineEvent {
  const SearchChanged(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

final class FilterChanged extends PipelineEvent {
  const FilterChanged({this.territory, this.assignedRepName, this.priority, this.visibleStages});
  final String? Function()? territory;
  final String? Function()? assignedRepName;
  final Priority? Function()? priority;
  final Set<PipelineStage>? visibleStages;
  @override
  List<Object?> get props => [territory, assignedRepName, priority, visibleStages];
}

final class SortChanged extends PipelineEvent {
  const SortChanged(this.sortBy);
  final SortBy sortBy;
  @override
  List<Object?> get props => [sortBy];
}
