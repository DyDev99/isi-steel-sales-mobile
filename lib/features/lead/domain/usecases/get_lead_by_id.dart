import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/repositories/lead_repository.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/lead_id_params.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/lead_usecase.dart';

class GetLeadById extends LeadUseCase<Lead, LeadIdParams> {
  const GetLeadById(this._repository);
  final LeadRepository _repository;

  @override
  Future<Lead> call(LeadIdParams params) => _repository.getById(params.leadId);
}
