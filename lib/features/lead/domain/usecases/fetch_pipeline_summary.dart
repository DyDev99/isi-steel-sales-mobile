import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_summary.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/repositories/lead_repository.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/lead_usecase.dart';

class FetchPipelineSummary extends LeadUseCase<PipelineSummary, NoParams> {
  const FetchPipelineSummary(this._repository);
  final LeadRepository _repository;

  @override
  Future<PipelineSummary> call(NoParams params) => _repository.fetchSummary();
}
