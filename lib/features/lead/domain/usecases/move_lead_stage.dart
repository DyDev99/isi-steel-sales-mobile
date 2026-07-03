import 'package:isi_steel_sales_mobile/features/lead/domain/entities/opportunity_info.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/won_info.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/repositories/lead_repository.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/lead_usecase.dart';

class MoveLeadStageParams {
  const MoveLeadStageParams({
    required this.leadId,
    required this.toStage,
    this.opportunityInfo,
    this.wonInfo,
  });
  final String leadId;
  final PipelineStage toStage;
  final OpportunityInfo? opportunityInfo;
  final WonInfo? wonInfo;
}

class MoveLeadStage extends LeadUseCase<void, MoveLeadStageParams> {
  const MoveLeadStage(this._repository);
  final LeadRepository _repository;

  @override
  Future<void> call(MoveLeadStageParams params) => _repository.moveStage(
        id: params.leadId,
        toStage: params.toStage,
        opportunityInfo: params.opportunityInfo,
        wonInfo: params.wonInfo,
      );
}
