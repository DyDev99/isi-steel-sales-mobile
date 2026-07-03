import 'package:isi_steel_sales_mobile/features/lead/domain/repositories/lead_repository.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/lead_id_params.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/lead_usecase.dart';

class DeleteLead extends LeadUseCase<void, LeadIdParams> {
  const DeleteLead(this._repository);
  final LeadRepository _repository;

  @override
  Future<void> call(LeadIdParams params) => _repository.deleteLead(params.leadId);
}
