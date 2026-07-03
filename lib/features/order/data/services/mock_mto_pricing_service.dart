import 'package:isi_steel_sales_mobile/core/network/network_info.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/mto_quote.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/mto_pricing_service.dart';

/// Stand-in for an online SAP quote request — deliberately never resolves
/// from the local `prices` table, so MTO pricing stays structurally
/// separate from standard pricing even in this mock form.
class MockMtoPricingService implements MtoPricingService {
  const MockMtoPricingService(this._network);
  final NetworkInfo _network;

  @override
  ResultFuture<MtoQuote> requestQuote(Product product) async {
    if (!await _network.isConnected) {
      return const Success(MtoQuote(
        available: false,
        message: 'Quote pending — connect to request pricing from SAP.',
      ));
    }
    final estimate = product.pricing.standardPrice * 1.15;
    return Success(MtoQuote(
      available: true,
      message: 'Estimated MTO price — confirm with SAP before quoting the customer.',
      price: double.parse(estimate.toStringAsFixed(2)),
    ));
  }
}
