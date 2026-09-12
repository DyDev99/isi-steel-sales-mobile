import 'package:equatable/equatable.dart';

class CheckInRecord extends Equatable {
  const CheckInRecord({
    required this.id,
    required this.stopId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.distanceFromCustomerMeters,
    required this.isMocked,
    this.overrideReason,
  });

  final String id;
  final String stopId;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final double distanceFromCustomerMeters;
  final bool isMocked;

  /// What the rep wrote when checking in from outside the geofence.
  ///
  /// Null on an ordinary check-in, and the two are meaningfully different on
  /// the server: an `OutsideGeofence` verdict with no reason is a rep who was
  /// not there, one with a reason is a rep who said why. Carried on this row
  /// rather than as a separate note so the reason and the verdict it explains
  /// are the same record.
  final String? overrideReason;

  @override
  List<Object?> get props => [
        id,
        stopId,
        timestamp,
        latitude,
        longitude,
        accuracyMeters,
        distanceFromCustomerMeters,
        isMocked,
        overrideReason,
      ];
}
