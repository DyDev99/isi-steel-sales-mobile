import 'package:isi_steel_sales_mobile/features/quotations/domain/entities/quotation.dart';

abstract class QuotationRepository {
  Future<List<Quotation>> getQuotations({
    String? status,
    String? customerId,
    int page = 1,
    int pageSize = 20,
  });

  Future<String> createQuotation({
    required String customerId,
    String shipmentType = 'Pickup',
    String? shipTo,
  });

  Future<QuotationDetail> getQuotationDetail(String id);

  Future<QuotationDetail> updateQuotationHeader(
    String id, {
    required String shipmentType,
    String? shipTo,
    String? paymentTerm,
    String? customerReference,
    String? remarks,
  });

  Future<QuotationDetail> addLine(
    String id, {
    required String materialNumber,
    required double quantity,
    String? unit,
  });

  Future<QuotationDetail> updateLineQuantity(
    String id,
    String lineId, {
    required double quantity,
  });

  Future<QuotationDetail> removeLine(String id, String lineId);

  Future<QuotationDetail> updateDiscounts(
    String id,
    List<Map<String, dynamic>> discounts,
  );

  Future<QuotationDetail> previewQuotation(String id);

  Future<QuotationDetail> repriceQuotation(String id);

  Future<QuotationDetail> submitQuotation(String id);

  Future<QuotationDetail> cancelQuotation(String id);
}
