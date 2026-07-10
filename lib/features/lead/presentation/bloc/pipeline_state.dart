import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_filter.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_summary.dart';

sealed class PipelineState extends Equatable {
  const PipelineState();
  @override
  List<Object?> get props => const [];
}

final class PipelineInitial extends PipelineState {
  const PipelineInitial();
}

final class PipelineLoading extends PipelineState {
  const PipelineLoading();
}

final class PipelineError extends PipelineState {
  const PipelineError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

final class PipelineLoaded extends PipelineState {
  const PipelineLoaded({
    required this.allLeads,
    required this.columns,
    required this.filter,
    required this.summary,
    this.blockedMoveMessage,
  });

  /// Full unfiltered set — needed to recompute [columns] when filter/sort change.
  final List<Lead> allLeads;

  /// Filtered + sorted leads per column, ready for the board to render.
  final Map<PipelineStage, List<Lead>> columns;
  final PipelineFilter filter;
  final PipelineSummary summary;

  /// One-shot message (e.g. a blocked drag) for the UI to surface as a
  /// snackbar, then clear.
  final String? blockedMoveMessage;

  PipelineLoaded copyWith({
    List<Lead>? allLeads,
    Map<PipelineStage, List<Lead>>? columns,
    PipelineFilter? filter,
    PipelineSummary? summary,
    String? Function()? blockedMoveMessage,
  }) {
    return PipelineLoaded(
      allLeads: allLeads ?? this.allLeads,
      columns: columns ?? this.columns,
      filter: filter ?? this.filter,
      summary: summary ?? this.summary,
      blockedMoveMessage: blockedMoveMessage != null
          ? blockedMoveMessage()
          : this.blockedMoveMessage,
    );
  }

  @override
  List<Object?> get props =>
      [allLeads, columns, filter, summary, blockedMoveMessage];
}
