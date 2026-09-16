import 'package:isi_steel_sales_mobile/core/utils/enum_parse.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/depot_stop_info.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';

class RouteStopModel extends RouteStop {
  const RouteStopModel({
    required super.id,
    required super.routeId,
    required super.depot,
    required super.sequence,
    required super.plannedArrival,
    required super.plannedDeparture,
    required super.status,
    super.actualArrival,
    super.actualDeparture,
  });

  /// The remote payload only carries `depotId`; `depots` arrives as a
  /// flat de-duplicated list alongside it. The caller
  /// (`ApiRouteRemoteDataSource`) resolves the join and passes the full
  /// depot record in, so this model never needs its own lookup path.
  factory RouteStopModel.fromJson(DataMap json,
          {required DepotStopInfo depot}) =>
      RouteStopModel(
        id: json['id'] as String,
        routeId: json['routeId'] as String,
        depot: depot,
        sequence: (json['sequence'] as num).toInt(),
        plannedArrival: DateTime.parse(json['plannedArrival'] as String),
        plannedDeparture: DateTime.parse(json['plannedDeparture'] as String),
        // Read the execution state the payload carries instead of hardcoding
        // `pending`. Hardcoding here meant the dashboard summary always computed
        // 0 completed / 0% progress regardless of the data — the "mock data
        // doesn't drive the UI" bug. Falls back to `pending` when absent so a
        // payload without a status still parses.
        status: json['status'] != null
            ? VisitStatus.values.asNameMap()[json['status']] ??
                VisitStatus.pending
            : VisitStatus.pending,
        actualArrival: json['actualArrival'] != null
            ? DateTime.parse(json['actualArrival'] as String)
            : null,
        actualDeparture: json['actualDeparture'] != null
            ? DateTime.parse(json['actualDeparture'] as String)
            : null,
      );

  factory RouteStopModel.fromRow(DataMap row, {required DepotStopInfo depot}) =>
      RouteStopModel(
        id: row['id'] as String,
        routeId: row['route_id'] as String,
        depot: depot,
        sequence: (row['sequence'] as num).toInt(),
        plannedArrival: DateTime.parse(row['planned_arrival'] as String),
        plannedDeparture: DateTime.parse(row['planned_departure'] as String),
        status: VisitStatus.values.byNameOr(
            row['status'] as String?, VisitStatus.values.first,
            context: 'stop.row.status'),
        actualArrival: row['actual_arrival'] == null
            ? null
            : DateTime.parse(row['actual_arrival'] as String),
        actualDeparture: row['actual_departure'] == null
            ? null
            : DateTime.parse(row['actual_departure'] as String),
      );

  DataMap toRow() => {
        'id': id,
        'route_id': routeId,
        'depot_id': depot.id,
        'sequence': sequence,
        'planned_arrival': plannedArrival.toIso8601String(),
        'planned_departure': plannedDeparture.toIso8601String(),
        'status': status.name,
        'actual_arrival': actualArrival?.toIso8601String(),
        'actual_departure': actualDeparture?.toIso8601String(),
      };
}
