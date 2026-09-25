import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/workflow_state_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/active_workflow_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/active_workflow.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/repositories/active_workflow_repository.dart';

class ActiveWorkflowRepositoryImpl implements ActiveWorkflowRepository {
  const ActiveWorkflowRepositoryImpl(this._local);
  final WorkflowStateLocalDataSource _local;

  @override
  ResultFuture<ActiveWorkflow?> getActiveWorkflow() async {
    try {
      return Success(await _local.getActiveWorkflow());
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<void> saveActiveWorkflow(ActiveWorkflow workflow) async {
    try {
      await _local.saveActiveWorkflow(ActiveWorkflowModel.fromEntity(workflow));
      return const Success(null);
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<void> clearActiveWorkflow() async {
    try {
      await _local.clearActiveWorkflow();
      return const Success(null);
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }
}
