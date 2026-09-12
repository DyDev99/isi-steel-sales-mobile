import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/active_workflow.dart';

abstract interface class ActiveWorkflowRepository {
  ResultFuture<ActiveWorkflow?> getActiveWorkflow();
  ResultFuture<void> saveActiveWorkflow(ActiveWorkflow workflow);
  ResultFuture<void> clearActiveWorkflow();
}
