import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/customer_stop_info.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';

class RouteStopModel extends RouteStop {
  const RouteStopModel({
    required super.id,
    required super.routeId,
    required super.customer,
    required super.sequence,
    required super.plannedArrival,
    required super.plannedDeparture,
    required super.status,
    super.actualArrival,
    super.actualDeparture,
  });

  /// The mock remote payload only carries `customerId` — the caller
  /// (`MockRouteRemoteDataSource`) resolves and passes the full customer
  /// record in, so this model never needs its own lookup path.
  factory RouteStopModel.fromJson(DataMap json, {required CustomerStopInfo customer}) => RouteStopModel(
        id: json['id'] as String,
        routeId: json['routeId'] as String,
        customer: customer,
        sequence: (json['sequence'] as num).toInt(),
        plannedArrival: DateTime.parse(json['plannedArrival'] as String),
        plannedDeparture: DateTime.parse(json['plannedDeparture'] as String),
        status: VisitStatus.pending,
      );

  factory RouteStopModel.fromRow(DataMap row, {required CustomerStopInfo customer}) => RouteStopModel(
        id: row['id'] as String,
        routeId: row['route_id'] as String,
        customer: customer,
        sequence: (row['sequence'] as num).toInt(),
        plannedArrival: DateTime.parse(row['planned_arrival'] as String),
        plannedDeparture: DateTime.parse(row['planned_departure'] as String),
        status: VisitStatus.values.byName(row['status'] as String),
        actualArrival: row['actual_arrival'] == null ? null : DateTime.parse(row['actual_arrival'] as String),
        actualDeparture:
            row['actual_departure'] == null ? null : DateTime.parse(row['actual_departure'] as String),
      );

  DataMap toRow() => {
        'id': id,
        'route_id': routeId,
        'customer_id': customer.id,
        'sequence': sequence,
        'planned_arrival': plannedArrival.toIso8601String(),
        'planned_departure': plannedDeparture.toIso8601String(),
        'status': status.name,
        'actual_arrival': actualArrival?.toIso8601String(),
        'actual_departure': actualDeparture?.toIso8601String(),
      };
}
