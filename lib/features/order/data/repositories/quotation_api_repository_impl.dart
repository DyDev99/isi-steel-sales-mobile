import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/network/api_error.dart';
import 'package:isi_steel_sales_mobile/core/network/network_info.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/data/remote/quotation_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/paged_result.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation_api_entities.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/quotation_api_repository.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/promotions/promo_view.dart';

class QuotationApiRepositoryImpl implements QuotationApiRepository {
  const QuotationApiRepositoryImpl({
    required QuotationRemoteDataSource remote,
    required NetworkInfo network,
  })  : _remote = remote,
        _network = network;

  final QuotationRemoteDataSource _remote;
  final NetworkInfo _network;

  Failure _mapException(Object e) {
    if (e is ApiException) {
      return ServerFailure(
        message: e.error.message ?? e.error.detail ?? 'Server error',
        statusCode: e.error.statusCode,
        code: e.error.code,
      );
    }
    if (e is ServerException) {
      return ServerFailure(message: e.message, statusCode: e.statusCode);
    }
    return ServerFailure(message: e.toString());
  }

  @override
  ResultFuture<PagedResult<QuotationSummary>> getQuotations({
    String? status,
    String? customerId,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (!await _network.isConnected) {
      return const Failed(NetworkFailure());
    }
    try {
      final result = await _remote.fetchQuotations(
        status: status,
        customerId: customerId,
        page: page,
        pageSize: pageSize,
      );
      final hasMore = result.metadata?.hasNextPage ??
          (result.quotations.length >= pageSize);
      return Success(PagedResult(
        items: result.quotations,
        page: page,
        hasMore: hasMore,
      ));
    } catch (e) {
      return Failed(_mapException(e));
    }
  }

  @override
  ResultFuture<QuotationDetail> createQuotation({
    required String customerId,
    String shipmentType = 'Pickup',
    String? shipTo,
  }) async {
    if (!await _network.isConnected) {
      return const Failed(NetworkFailure());
    }
    try {
      final quotation = await _remote.createQuotation(
        customerId: customerId,
        shipmentType: shipmentType,
        shipTo: shipTo,
      );
      return Success(quotation);
    } catch (e) {
      return Failed(_mapException(e));
    }
  }

  @override
  ResultFuture<QuotationDetail> getQuotationDetail(String id) async {
    if (!await _network.isConnected) {
      return const Failed(NetworkFailure());
    }
    try {
      final quotation = await _remote.fetchQuotationById(id);
      return Success(quotation);
    } catch (e) {
      return Failed(_mapException(e));
    }
  }

  @override
  ResultFuture<QuotationDetail> updateQuotationHeader(
    String id, {
    required String shipmentType,
    String? shipTo,
    String? paymentTerm,
    String? customerReference,
    String? remarks,
  }) async {
    if (!await _network.isConnected) {
      return const Failed(NetworkFailure());
    }
    try {
      final quotation = await _remote.updateHeader(
        id,
        shipmentType: shipmentType,
        shipTo: shipTo,
        paymentTerm: paymentTerm,
        customerReference: customerReference,
        remarks: remarks,
      );
      return Success(quotation);
    } catch (e) {
      return Failed(_mapException(e));
    }
  }

  @override
  ResultFuture<QuotationDetail> addLine(
    String id, {
    required String materialNumber,
    required double quantity,
    String? unit,
  }) async {
    if (!await _network.isConnected) {
      return const Failed(NetworkFailure());
    }
    try {
      final quotation = await _remote.addLine(
        id,
        materialNumber: materialNumber,
        quantity: quantity,
        unit: unit,
      );
      return Success(quotation);
    } catch (e) {
      return Failed(_mapException(e));
    }
  }

  @override
  ResultFuture<QuotationDetail> updateLine(
    String id,
    String lineId, {
    required double quantity,
    String? unit,
  }) async {
    if (!await _network.isConnected) {
      return const Failed(NetworkFailure());
    }
    try {
      final quotation = await _remote.updateLine(
        id,
        lineId,
        quantity: quantity,
        unit: unit,
      );
      return Success(quotation);
    } catch (e) {
      return Failed(_mapException(e));
    }
  }

  @override
  ResultFuture<QuotationDetail> deleteLine(String id, String lineId) async {
    if (!await _network.isConnected) {
      return const Failed(NetworkFailure());
    }
    try {
      final quotation = await _remote.deleteLine(id, lineId);
      return Success(quotation);
    } catch (e) {
      return Failed(_mapException(e));
    }
  }

  @override
  ResultFuture<QuotationDetail> setDiscounts(
    String id, {
    required List<QuotationDiscountIntent> lines,
  }) async {
    if (!await _network.isConnected) {
      return const Failed(NetworkFailure());
    }
    try {
      final quotation = await _remote.setDiscounts(id, lines: lines);
      return Success(quotation);
    } catch (e) {
      return Failed(_mapException(e));
    }
  }

  @override
  ResultFuture<QuotationPreviewData> getPreview(String id) async {
    if (!await _network.isConnected) {
      return const Failed(NetworkFailure());
    }
    try {
      final preview = await _remote.getPreview(id);
      return Success(preview);
    } catch (e) {
      return Failed(_mapException(e));
    }
  }

  @override
  ResultFuture<QuotationDetail> reprice(String id) async {
    if (!await _network.isConnected) {
      return const Failed(NetworkFailure());
    }
    try {
      final quotation = await _remote.reprice(id);
      return Success(quotation);
    } catch (e) {
      return Failed(_mapException(e));
    }
  }

  @override
  ResultFuture<QuotationDetail> submit(String id) async {
    if (!await _network.isConnected) {
      return const Failed(NetworkFailure());
    }
    try {
      final quotation = await _remote.submit(id);
      return Success(quotation);
    } catch (e) {
      return Failed(_mapException(e));
    }
  }

  @override
  ResultFuture<QuotationDetail> cancel(String id) async {
    if (!await _network.isConnected) {
      return const Failed(NetworkFailure());
    }
    try {
      final quotation = await _remote.cancel(id);
      return Success(quotation);
    } catch (e) {
      return Failed(_mapException(e));
    }
  }

  @override
  ResultFuture<List<QuotationApprovalHistory>> getHistory(String id) async {
    if (!await _network.isConnected) {
      return const Failed(NetworkFailure());
    }
    try {
      final history = await _remote.fetchHistory(id);
      return Success(history);
    } catch (e) {
      return Failed(_mapException(e));
    }
  }

  @override
  ResultFuture<List<CustomerAgreement>> getCustomerAgreements(
      String customerId) async {
    if (!await _network.isConnected) {
      return const Failed(NetworkFailure());
    }
    try {
      final agreements = await _remote.fetchCustomerAgreements(customerId);
      return Success(agreements);
    } catch (e) {
      return Failed(_mapException(e));
    }
  }

  @override
  ResultFuture<List<PromoGroup>> getCustomerIncentives(
    String customerId, {
    String? shipment,
  }) async {
    if (!await _network.isConnected) {
      return const Failed(NetworkFailure());
    }
    try {
      final incentives = await _remote.fetchCustomerIncentives(
        customerId,
        shipment: shipment,
      );
      return Success(incentives);
    } catch (e) {
      return Failed(_mapException(e));
    }
  }

  @override
  ResultFuture<List<PromoView>> getCustomerPromotions(
      String customerId) async {
    if (!await _network.isConnected) {
      return const Failed(NetworkFailure());
    }
    try {
      final promotions = await _remote.fetchCustomerPromotions(customerId);
      return Success(promotions);
    } catch (e) {
      return Failed(_mapException(e));
    }
  }

  @override
  ResultFuture<DiscountAuthority> getDiscountAuthority() async {
    if (!await _network.isConnected) {
      return const Failed(NetworkFailure());
    }
    try {
      final authority = await _remote.fetchDiscountAuthority();
      return Success(authority);
    } catch (e) {
      return Failed(_mapException(e));
    }
  }
}
