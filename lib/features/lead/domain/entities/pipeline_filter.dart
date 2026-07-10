import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/priority.dart';

enum SortBy { newest, oldest, revenue, priority }

class PipelineFilter extends Equatable {
  const PipelineFilter({
    this.search = '',
    this.territory,
    this.assignedRepName,
    this.priority,
    this.visibleStages = const {
      PipelineStage.leads,
      PipelineStage.opportunities,
      PipelineStage.won,
    },
    this.sortBy = SortBy.newest,
  });

  final String search;
  final String? territory;
  final String? assignedRepName;
  final Priority? priority;

  /// Which columns are shown. All three by default; narrowing this lets the
  /// "filter by stage" requirement double as a single-column mobile view.
  final Set<PipelineStage> visibleStages;
  final SortBy sortBy;

  bool get isEmpty =>
      search.isEmpty &&
      territory == null &&
      assignedRepName == null &&
      priority == null &&
      visibleStages.length == PipelineStage.values.length;

  PipelineFilter copyWith({
    String? search,
    String? Function()? territory,
    String? Function()? assignedRepName,
    Priority? Function()? priority,
    Set<PipelineStage>? visibleStages,
    SortBy? sortBy,
  }) {
    return PipelineFilter(
      search: search ?? this.search,
      territory: territory != null ? territory() : this.territory,
      assignedRepName:
          assignedRepName != null ? assignedRepName() : this.assignedRepName,
      priority: priority != null ? priority() : this.priority,
      visibleStages: visibleStages ?? this.visibleStages,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  List<Object?> get props =>
      [search, territory, assignedRepName, priority, visibleStages, sortBy];
}
