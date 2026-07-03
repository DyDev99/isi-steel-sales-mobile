import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/repositories/lead_repository.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/lead_usecase.dart';

class UpdateLead extends LeadUseCase<void, Lead> {
  const UpdateLead(this._repository);
  final LeadRepository _repository;

  @override
  Future<void> call(Lead params) => _repository.updateLead(params);
}
