import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/quotation_repository.dart';

class WatchQuotations extends StreamUseCase<List<Quotation>, NoParams> {
  const WatchQuotations(this._repository);
  final QuotationRepository _repository;

  @override
  Stream<List<Quotation>> call(NoParams params) => _repository.watchQuotations();
}
