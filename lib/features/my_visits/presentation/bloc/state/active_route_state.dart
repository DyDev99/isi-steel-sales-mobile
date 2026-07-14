import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_plan.dart';

sealed class ActiveRouteState extends Equatable {
  const ActiveRouteState();
  @override
  List<Object?> get props => [];
}

final class ActiveRouteLoading extends ActiveRouteState {
  const ActiveRouteLoading();
}

final class ActiveRouteReady extends ActiveRouteState {
  const ActiveRouteReady({
    required this.route,
    required this.dayStarted,
    required this.currentStopIndex,
    this.insideGeofence = true,
    this.distanceMeters = 0,
    this.accuracyMeters = 0,
    this.isMocked = false,
    this.blockedCheckInReason,
    this.checkInWarnings = const [],
  });

  final RoutePlan route;
  final bool dayStarted;
  final int currentStopIndex;
  final bool insideGeofence;
  final double distanceMeters;
  final double accuracyMeters;
  final bool isMocked;
  final String? blockedCheckInReason;
  final List<String> checkInWarnings;

  bool get hasCurrentStop =>
      currentStopIndex >= 0 && currentStopIndex < route.stops.length;

  ActiveRouteReady copyWith({
    RoutePlan? route,
    bool? dayStarted,
    int? currentStopIndex,
    bool? insideGeofence,
    double? distanceMeters,
    double? accuracyMeters,
    bool? isMocked,
    String? Function()? blockedCheckInReason,
    List<String>? checkInWarnings,
  }) {
    return ActiveRouteReady(
      route: route ?? this.route,
      dayStarted: dayStarted ?? this.dayStarted,
      currentStopIndex: currentStopIndex ?? this.currentStopIndex,
      insideGeofence: insideGeofence ?? this.insideGeofence,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      isMocked: isMocked ?? this.isMocked,
      blockedCheckInReason: blockedCheckInReason != null
          ? blockedCheckInReason()
          : this.blockedCheckInReason,
      checkInWarnings: checkInWarnings ?? this.checkInWarnings,
    );
  }

  @override
  List<Object?> get props => [
        route,
        dayStarted,
        currentStopIndex,
        insideGeofence,
        distanceMeters,
        isMocked,
        blockedCheckInReason,
        checkInWarnings,
      ];
}

final class ActiveRouteCompleted extends ActiveRouteState {
  const ActiveRouteCompleted(this.route);
  final RoutePlan route;
  @override
  List<Object?> get props => [route];
}

final class ActiveRouteError extends ActiveRouteState {
  const ActiveRouteError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
