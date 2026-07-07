import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/credit_summary.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/credit_service.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';

class GetCreditSummary extends UseCase<CreditSummary, GetCreditSummaryParams> {
  const GetCreditSummary(this._service);
  final CreditService _service;

  @override
  ResultFuture<CreditSummary> call(GetCreditSummaryParams params) => _service.getSummary(params.customerId);
}
