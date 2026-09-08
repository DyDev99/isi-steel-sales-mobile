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
    this.skipReasons = const {},
    this.repLatitude,
    this.repLongitude,
    this.customerLocationKnown = true,
    this.checkInOverridable = false,
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

  /// Reasons the rep gave when skipping a stop, keyed by stop id. Session-scoped
  /// display data (the skip itself persists as [VisitStatus.missed]).
  final Map<String, String> skipReasons;

  /// The rep's own last known position, from the live GPS stream.
  ///
  /// **Null until a fix arrives**, which is the state that matters: a check-in
  /// written before the first fix has no evidence of where the rep was, and
  /// recording the shop's own coordinates in its place — which is what this
  /// used to do — makes every visit look perfectly on-location and renders the
  /// geofence evidence in api.md §8.2 incapable of catching anything.
  final double? repLatitude;
  final double? repLongitude;

  /// False when the selected stop's customer has no recorded coordinates.
  ///
  /// Distinct from [insideGeofence] being false. There is nothing to be
  /// outside of, so check-in proceeds and records itself as unverifiable
  /// rather than blocking a rep standing in the right place at a shop nobody
  /// has geotagged.
  final bool customerLocationKnown;

  /// True once the device has produced at least one position.
  bool get hasFix => repLatitude != null && repLongitude != null;

  /// True when the current [blockedCheckInReason] is one a written reason
  /// could carry the rep past — outside the geofence, or a fix too coarse to
  /// judge, and no integrity rule among the blocks.
  ///
  /// The screen reads this to decide between offering "Check in anyway" and
  /// simply reporting the block. Carried as a flag rather than re-derived in
  /// the UI, because the alternative is matching on the text of the reason
  /// string, which breaks the first time someone rewords it or translates it.
  final bool checkInOverridable;

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
    Map<String, String>? skipReasons,
    double? repLatitude,
    double? repLongitude,
    bool? customerLocationKnown,
    bool? checkInOverridable,
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
      skipReasons: skipReasons ?? this.skipReasons,
      repLatitude: repLatitude ?? this.repLatitude,
      repLongitude: repLongitude ?? this.repLongitude,
      customerLocationKnown:
          customerLocationKnown ?? this.customerLocationKnown,
      checkInOverridable: checkInOverridable ?? this.checkInOverridable,
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
        skipReasons,
        repLatitude,
        repLongitude,
        customerLocationKnown,
        checkInOverridable,
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
