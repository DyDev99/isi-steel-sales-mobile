import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/quotation_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';

class UpdateQuotation extends UseCase<Quotation, UpdateQuotationParams> {
  const UpdateQuotation(this._repository);
  final QuotationRepository _repository;

  @override
  ResultFuture<Quotation> call(UpdateQuotationParams params) =>
      _repository.updateQuotation(params.existing, items: params.items);
}
