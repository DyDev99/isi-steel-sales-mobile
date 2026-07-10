import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/active_workflow.dart';

class ActiveWorkflowModel extends ActiveWorkflow {
  const ActiveWorkflowModel({
    required super.routeId,
    super.currentStopId,
    required super.dayStarted,
    required super.updatedAt,
  });

  factory ActiveWorkflowModel.fromRow(DataMap row) => ActiveWorkflowModel(
        routeId: row['route_id'] as String,
        currentStopId: row['current_stop_id'] as String?,
        dayStarted: (row['day_started'] as int) == 1,
        updatedAt: DateTime.parse(row['updated_at'] as String),
      );

  DataMap toRow() => {
        'id': 'active',
        'route_id': routeId,
        'current_stop_id': currentStopId,
        'day_started': dayStarted ? 1 : 0,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory ActiveWorkflowModel.fromEntity(ActiveWorkflow e) =>
      ActiveWorkflowModel(
        routeId: e.routeId,
        currentStopId: e.currentStopId,
        dayStarted: e.dayStarted,
        updatedAt: e.updatedAt,
      );
}
