import 'package:isi_steel_sales_mobile/features/lead/domain/entities/activity_log_item.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/repositories/lead_repository.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/lead_usecase.dart';

class AddLeadActivityParams {
  const AddLeadActivityParams({required this.leadId, required this.item});
  final String leadId;
  final ActivityLogItem item;
}

class AddLeadActivity extends LeadUseCase<void, AddLeadActivityParams> {
  const AddLeadActivity(this._repository);
  final LeadRepository _repository;

  @override
  Future<void> call(AddLeadActivityParams params) => _repository.addActivity(params.leadId, params.item);
}
