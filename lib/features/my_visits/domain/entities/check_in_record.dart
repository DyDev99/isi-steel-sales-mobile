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
  });

  final String id;
  final String stopId;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final double distanceFromCustomerMeters;
  final bool isMocked;

  @override
  List<Object?> get props =>
      [id, stopId, timestamp, latitude, longitude, accuracyMeters, distanceFromCustomerMeters, isMocked];
}
