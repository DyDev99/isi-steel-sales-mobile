import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead_document.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/repositories/lead_repository.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/lead_usecase.dart';

class AddLeadDocumentParams {
  const AddLeadDocumentParams({required this.leadId, required this.document});
  final String leadId;
  final LeadDocument document;
}

class AddLeadDocument extends LeadUseCase<void, AddLeadDocumentParams> {
  const AddLeadDocument(this._repository);
  final LeadRepository _repository;

  @override
  Future<void> call(AddLeadDocumentParams params) => _repository.addDocument(params.leadId, params.document);
}
