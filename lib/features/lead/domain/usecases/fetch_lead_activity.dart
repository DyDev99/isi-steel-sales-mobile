import 'package:isi_steel_sales_mobile/features/lead/domain/entities/activity_log_item.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/repositories/lead_repository.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/lead_id_params.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/lead_usecase.dart';

class FetchLeadActivity
    extends LeadUseCase<List<ActivityLogItem>, LeadIdParams> {
  const FetchLeadActivity(this._repository);
  final LeadRepository _repository;

  @override
  Future<List<ActivityLogItem>> call(LeadIdParams params) =>
      _repository.fetchActivity(params.leadId);
}
