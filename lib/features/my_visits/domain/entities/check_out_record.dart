import 'package:equatable/equatable.dart';

class CheckOutRecord extends Equatable {
  const CheckOutRecord({
    required this.id,
    required this.stopId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.durationMinutes,
    required this.visitSummary,
  });

  final String id;
  final String stopId;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final int durationMinutes;
  final String visitSummary;

  @override
  List<Object?> get props => [
        id,
        stopId,
        timestamp,
        latitude,
        longitude,
        durationMinutes,
        visitSummary
      ];
}
