import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/paged_result.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation_api_entities.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/promotions/promo_view.dart';

abstract interface class QuotationApiRepository {
  ResultFuture<PagedResult<QuotationSummary>> getQuotations({
    String? status,
    String? customerId,
    int page = 1,
    int pageSize = 20,
  });

  ResultFuture<QuotationDetail> createQuotation({
    required String customerId,
    String shipmentType = 'Pickup',
    String? shipTo,
  });

  ResultFuture<QuotationDetail> getQuotationDetail(String id);

  ResultFuture<QuotationDetail> updateQuotationHeader(
    String id, {
    required String shipmentType,
    String? shipTo,
    String? paymentTerm,
    String? customerReference,
    String? remarks,
  });

  ResultFuture<QuotationDetail> addLine(
    String id, {
    required String materialNumber,
    required double quantity,
    String? unit,
  });

  ResultFuture<QuotationDetail> updateLine(
    String id,
    String lineId, {
    required double quantity,
    String? unit,
  });

  ResultFuture<QuotationDetail> deleteLine(String id, String lineId);

  ResultFuture<QuotationDetail> setDiscounts(
    String id, {
    required List<QuotationDiscountIntent> lines,
  });

  ResultFuture<QuotationPreviewData> getPreview(String id);

  ResultFuture<QuotationDetail> reprice(String id);

  ResultFuture<QuotationDetail> submit(String id);

  ResultFuture<QuotationDetail> cancel(String id);

  ResultFuture<List<QuotationApprovalHistory>> getHistory(String id);

  ResultFuture<List<CustomerAgreement>> getCustomerAgreements(
      String customerId);

  ResultFuture<List<PromoGroup>> getCustomerIncentives(
    String customerId, {
    String? shipment,
  });

  ResultFuture<List<PromoView>> getCustomerPromotions(String customerId);

  ResultFuture<DiscountAuthority> getDiscountAuthority();
}
