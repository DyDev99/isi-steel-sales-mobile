import 'package:isi_steel_sales_mobile/features/lead/domain/repositories/lead_repository.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/lead_usecase.dart';

class AddLeadNoteParams {
  const AddLeadNoteParams({required this.leadId, required this.note});
  final String leadId;
  final String note;
}

class AddLeadNote extends LeadUseCase<void, AddLeadNoteParams> {
  const AddLeadNote(this._repository);
  final LeadRepository _repository;

  @override
  Future<void> call(AddLeadNoteParams params) => _repository.addNote(params.leadId, params.note);
}
