import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/repositories/lead_repository.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/lead_usecase.dart';

class FetchLeads extends LeadUseCase<List<Lead>, NoParams> {
  const FetchLeads(this._repository);
  final LeadRepository _repository;

  @override
  Future<List<Lead>> call(NoParams params) => _repository.fetchLeads();
}
