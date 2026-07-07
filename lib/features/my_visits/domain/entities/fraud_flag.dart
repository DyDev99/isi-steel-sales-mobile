import 'package:equatable/equatable.dart';

enum FraudFlagType { mockLocation, impossibleSpeed, poorAccuracy, vpnDetected }

class FraudFlag extends Equatable {
  const FraudFlag({
    required this.id,
    required this.routeId,
    required this.type,
    required this.detail,
    required this.timestamp,
    required this.blocked,
    this.stopId,
  });

  final String id;
  final String routeId;
  final String? stopId;
  final FraudFlagType type;
  final String detail;
  final DateTime timestamp;
  final bool blocked;

  @override
  List<Object?> get props => [id, routeId, stopId, type, timestamp, blocked];
}
