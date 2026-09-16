import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/depot_stop_info.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';

/// One planned stop on a route, denormalized with its [depot] the same
/// way `order`'s `Product` is a joined read-model — the UI never has to
/// separately look up the depot for a stop.
class RouteStop extends Equatable {
  const RouteStop({
    required this.id,
    required this.routeId,
    required this.depot,
    required this.sequence,
    required this.plannedArrival,
    required this.plannedDeparture,
    required this.status,
    this.actualArrival,
    this.actualDeparture,
  });

  final String id;
  final String routeId;
  final DepotStopInfo depot;
  final int sequence;
  final DateTime plannedArrival;
  final DateTime plannedDeparture;
  final VisitStatus status;
  final DateTime? actualArrival;
  final DateTime? actualDeparture;

  RouteStop copyWith(
          {VisitStatus? status,
          DateTime? actualArrival,
          DateTime? actualDeparture}) =>
      RouteStop(
        id: id,
        routeId: routeId,
        depot: depot,
        sequence: sequence,
        plannedArrival: plannedArrival,
        plannedDeparture: plannedDeparture,
        status: status ?? this.status,
        actualArrival: actualArrival ?? this.actualArrival,
        actualDeparture: actualDeparture ?? this.actualDeparture,
      );

  @override
  List<Object?> get props => [
        id,
        routeId,
        depot,
        sequence,
        plannedArrival,
        status,
        actualArrival,
        actualDeparture
      ];
}
