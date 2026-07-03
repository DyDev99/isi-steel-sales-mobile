import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/repositories/lead_repository.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/lead_usecase.dart';

class ReorderLeadsParams {
  const ReorderLeadsParams({required this.stage, required this.oldIndex, required this.newIndex});
  final PipelineStage stage;
  final int oldIndex;
  final int newIndex;
}

class ReorderLeads extends LeadUseCase<void, ReorderLeadsParams> {
  const ReorderLeads(this._repository);
  final LeadRepository _repository;

  @override
  Future<void> call(ReorderLeadsParams params) =>
      _repository.reorder(stage: params.stage, oldIndex: params.oldIndex, newIndex: params.newIndex);
}
