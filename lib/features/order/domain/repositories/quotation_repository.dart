import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/cart_item.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/off_visit_reason.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation.dart';

abstract interface class QuotationRepository {
  ResultFuture<Quotation> saveQuotation({
    required List<CartItem> items,
    String? customerId,
    String? shopName,
    String? leadId,
    String? leadDisplayName,
    OffVisitReason? offVisitReason,
    double? gpsLat,
    double? gpsLng,
  });

  ResultFuture<Quotation> updateQuotation(Quotation existing,
      {required List<CartItem> items});

  ResultFuture<Quotation> markConverted(String quotationId);

  ResultFuture<Quotation?> getQuotationById(String id);

  /// Permanently removes a draft quotation (user discarded it).
  ResultFuture<void> deleteQuotation(String id);

  /// Live stream of saved quotations — emits the current list on listen,
  /// then re-emits after every save/update/conversion.
  Stream<List<Quotation>> watchQuotations();
}
