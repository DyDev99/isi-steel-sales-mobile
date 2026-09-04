import 'package:equatable/equatable.dart';

sealed class ActiveRouteEvent extends Equatable {
  const ActiveRouteEvent();
  @override
  List<Object?> get props => [];
}

final class ActiveRouteLoadRequested extends ActiveRouteEvent {
  const ActiveRouteLoadRequested(this.routeId);
  final String routeId;
  @override
  List<Object?> get props => [routeId];
}

final class StartDayRequested extends ActiveRouteEvent {
  const StartDayRequested();
}

final class StopSelected extends ActiveRouteEvent {
  const StopSelected(this.index);
  final int index;
  @override
  List<Object?> get props => [index];
}

/// Fed continuously by the screen's `BlocListener<LocationTrackingCubit,...>`
/// — recomputed via `GeofenceService` on every GPS sample, so the bloc
/// always knows whether the rep is currently inside the selected stop's
/// geofence without depending on `LocationTrackingCubit` directly.
final class GeofenceStatusChanged extends ActiveRouteEvent {
  const GeofenceStatusChanged({
    required this.insideGeofence,
    required this.distanceMeters,
    required this.accuracyMeters,
    required this.isMocked,
    required this.latitude,
    required this.longitude,
  });

  final bool insideGeofence;
  final double distanceMeters;
  final double accuracyMeters;
  final bool isMocked;
  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [
        insideGeofence,
        distanceMeters,
        accuracyMeters,
        isMocked,
        latitude,
        longitude
      ];
}

final class CheckInRequested extends ActiveRouteEvent {
  const CheckInRequested();
}

final class CheckOutRequested extends ActiveRouteEvent {
  const CheckOutRequested(this.visitSummary);
  final String visitSummary;
  @override
  List<Object?> get props => [visitSummary];
}

final class NextStopRequested extends ActiveRouteEvent {
  const NextStopRequested();
}

/// Skip a specific stop [index] (before or during the route), recording the
/// rep's [reason]. The stop is marked [VisitStatus.missed]; the reason is kept
/// in state so the timeline can show why it was skipped.
final class SkipStopRequested extends ActiveRouteEvent {
  const SkipStopRequested({required this.index, required this.reason});
  final int index;
  final String reason;
  @override
  List<Object?> get props => [index, reason];
}

final class EndDayRequested extends ActiveRouteEvent {
  const EndDayRequested();
}
