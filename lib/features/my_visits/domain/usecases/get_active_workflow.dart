import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/active_workflow.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/repositories/active_workflow_repository.dart';

class GetActiveWorkflow extends UseCase<ActiveWorkflow?, NoParams> {
  const GetActiveWorkflow(this._repository);
  final ActiveWorkflowRepository _repository;
  @override
  ResultFuture<ActiveWorkflow?> call(NoParams params) =>
      _repository.getActiveWorkflow();
}
