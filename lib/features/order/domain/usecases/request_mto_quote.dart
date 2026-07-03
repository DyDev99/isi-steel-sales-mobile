import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/mto_quote.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/mto_pricing_service.dart';

class RequestMtoQuote extends UseCase<MtoQuote, Product> {
  const RequestMtoQuote(this._service);
  final MtoPricingService _service;

  @override
  ResultFuture<MtoQuote> call(Product params) => _service.requestQuote(params);
}
