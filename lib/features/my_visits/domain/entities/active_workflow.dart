import 'package:equatable/equatable.dart';

/// Persisted pointer to the rep's in-progress route, used purely to resume
/// them onto [RouteDispatchScreen] after a force-close/crash — never the
/// source of truth for stop-level progress (that's [RouteStop.status],
/// re-read fresh from the DB on every load). At most one row ever exists;
/// see `WorkflowStateLocalDataSource`.
class ActiveWorkflow extends Equatable {
  const ActiveWorkflow({
    required this.routeId,
    this.currentStopId,
    required this.dayStarted,
    required this.updatedAt,
  });

  final String routeId;
  final String? currentStopId;
  final bool dayStarted;
  final DateTime updatedAt;

  ActiveWorkflow copyWith(
          {String? currentStopId, bool? dayStarted, DateTime? updatedAt}) =>
      ActiveWorkflow(
        routeId: routeId,
        currentStopId: currentStopId ?? this.currentStopId,
        dayStarted: dayStarted ?? this.dayStarted,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [routeId, currentStopId, dayStarted, updatedAt];
}
