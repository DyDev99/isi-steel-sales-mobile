import 'package:dio/dio.dart';
import 'package:isi_steel_sales_mobile/core/constants/app_constant.dart';
import 'package:isi_steel_sales_mobile/core/network/api_envelope.dart';
import 'package:isi_steel_sales_mobile/core/network/api_error.dart';
import 'package:isi_steel_sales_mobile/features/order/data/models/quotation_api_models.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation_api_entities.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/promotions/promo_view.dart';

abstract class QuotationRemoteDataSource {
  Future<({List<QuotationSummaryModel> quotations, ApiMetadata? metadata})>
      fetchQuotations({
    String? status,
    String? customerId,
    int page = 1,
    int pageSize = 20,
  });

  Future<QuotationDetailModel> createQuotation({
    required String customerId,
    String shipmentType = 'Pickup',
    String? shipTo,
  });

  Future<QuotationDetailModel> fetchQuotationById(String id);

  Future<QuotationDetailModel> updateHeader(
    String id, {
    required String shipmentType,
    String? shipTo,
    String? paymentTerm,
    String? customerReference,
    String? remarks,
  });

  Future<QuotationDetailModel> addLine(
    String id, {
    required String materialNumber,
    required double quantity,
    String? unit,
  });

  Future<QuotationDetailModel> updateLine(
    String id,
    String lineId, {
    required double quantity,
    String? unit,
  });

  Future<QuotationDetailModel> deleteLine(String id, String lineId);

  Future<QuotationDetailModel> setDiscounts(
    String id, {
    required List<QuotationDiscountIntent> lines,
  });

  Future<QuotationPreviewModel> getPreview(String id);

  Future<QuotationDetailModel> reprice(String id);

  Future<QuotationDetailModel> submit(String id);

  Future<QuotationDetailModel> cancel(String id);

  Future<List<QuotationHistoryRecordModel>> fetchHistory(String id);

  Future<List<CustomerAgreementModel>> fetchCustomerAgreements(
      String customerId);

  Future<List<PromoGroup>> fetchCustomerIncentives(
    String customerId, {
    String? shipment,
  });

  Future<List<PromoView>> fetchCustomerPromotions(String customerId);

  Future<DiscountAuthorityModel> fetchDiscountAuthority();
}

class ApiQuotationRemoteDataSource implements QuotationRemoteDataSource {
  const ApiQuotationRemoteDataSource(this._client);

  final Dio _client;

  @override
  Future<({List<QuotationSummaryModel> quotations, ApiMetadata? metadata})>
      fetchQuotations({
    String? status,
    String? customerId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final res = await _client.get<Object?>(
        AppConstants.quotationsEndpoint,
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          if (customerId != null && customerId.isNotEmpty)
            'customerId': customerId,
          'page': page,
          'pageSize': pageSize,
        },
      );

      final envelope = ApiEnvelope.fromBody(res.data);
      final rawList = envelope.data['quotations'] as List<dynamic>? ??
          envelope.data['items'] as List<dynamic>? ??
          const <dynamic>[];

      final quotations = rawList
          .whereType<Map>()
          .map((m) =>
              QuotationSummaryModel.fromJson(m.cast<String, dynamic>()))
          .toList();

      return (quotations: quotations, metadata: envelope.metadata);
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<QuotationDetailModel> createQuotation({
    required String customerId,
    String shipmentType = 'Pickup',
    String? shipTo,
  }) async {
    try {
      final res = await _client.post<Object?>(
        AppConstants.quotationsEndpoint,
        data: {
          'customerId': customerId,
          'shipmentType': shipmentType,
          'shipTo': shipTo,
        },
      );

      final envelope = ApiEnvelope.fromBody(res.data);
      final data = envelope.object('quotation') ?? envelope.data;
      return QuotationDetailModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<QuotationDetailModel> fetchQuotationById(String id) async {
    try {
      final res = await _client.get<Object?>(
        AppConstants.quotationEndpoint(id),
      );

      final envelope = ApiEnvelope.fromBody(res.data);
      final data = envelope.object('quotation') ?? envelope.data;
      return QuotationDetailModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<QuotationDetailModel> updateHeader(
    String id, {
    required String shipmentType,
    String? shipTo,
    String? paymentTerm,
    String? customerReference,
    String? remarks,
  }) async {
    try {
      final res = await _client.put<Object?>(
        AppConstants.quotationEndpoint(id),
        data: {
          'shipmentType': shipmentType,
          'shipTo': shipTo,
          'paymentTerm': paymentTerm,
          'customerReference': customerReference,
          'remarks': remarks,
        },
      );

      final envelope = ApiEnvelope.fromBody(res.data);
      final data = envelope.object('quotation') ?? envelope.data;
      return QuotationDetailModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<QuotationDetailModel> addLine(
    String id, {
    required String materialNumber,
    required double quantity,
    String? unit,
  }) async {
    try {
      final res = await _client.post<Object?>(
        AppConstants.quotationLinesEndpoint(id),
        data: {
          'materialNumber': materialNumber,
          'quantity': quantity,
          if (unit != null) 'unit': unit,
        },
      );

      final envelope = ApiEnvelope.fromBody(res.data);
      final data = envelope.object('quotation') ?? envelope.data;
      return QuotationDetailModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<QuotationDetailModel> updateLine(
    String id,
    String lineId, {
    required double quantity,
    String? unit,
  }) async {
    try {
      final res = await _client.put<Object?>(
        AppConstants.quotationLineEndpoint(id, lineId),
        data: {
          'quantity': quantity,
          if (unit != null) 'unit': unit,
        },
      );

      final envelope = ApiEnvelope.fromBody(res.data);
      final data = envelope.object('quotation') ?? envelope.data;
      return QuotationDetailModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<QuotationDetailModel> deleteLine(String id, String lineId) async {
    try {
      final res = await _client.delete<Object?>(
        AppConstants.quotationLineEndpoint(id, lineId),
      );

      final envelope = ApiEnvelope.fromBody(res.data);
      final data = envelope.object('quotation') ?? envelope.data;
      return QuotationDetailModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<QuotationDetailModel> setDiscounts(
    String id, {
    required List<QuotationDiscountIntent> lines,
  }) async {
    try {
      final res = await _client.put<Object?>(
        AppConstants.quotationDiscountsEndpoint(id),
        data: {
          'lines': lines.map((l) => l.toJson()).toList(),
        },
      );

      final envelope = ApiEnvelope.fromBody(res.data);
      final data = envelope.object('quotation') ?? envelope.data;
      return QuotationDetailModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<QuotationPreviewModel> getPreview(String id) async {
    try {
      final res = await _client.get<Object?>(
        AppConstants.quotationPreviewEndpoint(id),
      );

      final envelope = ApiEnvelope.fromBody(res.data);
      final data = envelope.object('preview') ?? envelope.data;
      return QuotationPreviewModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<QuotationDetailModel> reprice(String id) async {
    try {
      final res = await _client.post<Object?>(
        AppConstants.quotationRepriceEndpoint(id),
      );

      final envelope = ApiEnvelope.fromBody(res.data);
      final data = envelope.object('quotation') ?? envelope.data;
      return QuotationDetailModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<QuotationDetailModel> submit(String id) async {
    try {
      final res = await _client.post<Object?>(
        AppConstants.quotationSubmitEndpoint(id),
      );

      final envelope = ApiEnvelope.fromBody(res.data);
      final data = envelope.object('quotation') ?? envelope.data;
      return QuotationDetailModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<QuotationDetailModel> cancel(String id) async {
    try {
      final res = await _client.post<Object?>(
        AppConstants.quotationCancelEndpoint(id),
      );

      final envelope = ApiEnvelope.fromBody(res.data);
      final data = envelope.object('quotation') ?? envelope.data;
      return QuotationDetailModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<List<QuotationHistoryRecordModel>> fetchHistory(String id) async {
    try {
      final res = await _client.get<Object?>(
        AppConstants.quotationHistoryEndpoint(id),
      );

      final envelope = ApiEnvelope.fromBody(res.data);
      final rawList = envelope.data['history'] as List<dynamic>? ??
          envelope.data['records'] as List<dynamic>? ??
          const <dynamic>[];

      return rawList
          .whereType<Map>()
          .map((m) =>
              QuotationHistoryRecordModel.fromJson(m.cast<String, dynamic>()))
          .toList();
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<List<CustomerAgreementModel>> fetchCustomerAgreements(
      String customerId) async {
    try {
      final res = await _client.get<Object?>(
        AppConstants.customerAgreementsEndpoint(customerId),
      );

      final envelope = ApiEnvelope.fromBody(res.data);
      final rawList = envelope.data['agreements'] as List<dynamic>? ??
          envelope.data['items'] as List<dynamic>? ??
          const <dynamic>[];

      return rawList
          .whereType<Map>()
          .map((m) =>
              CustomerAgreementModel.fromJson(m.cast<String, dynamic>()))
          .toList();
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<List<PromoGroup>> fetchCustomerIncentives(
    String customerId, {
    String? shipment,
  }) async {
    try {
      final res = await _client.get<Object?>(
        AppConstants.customerIncentivesEndpoint(customerId),
        queryParameters: {
          if (shipment != null && shipment.isNotEmpty) 'shipment': shipment,
        },
      );

      final envelope = ApiEnvelope.fromBody(res.data);
      final rawList = envelope.data['groups'] as List<dynamic>? ??
          envelope.data['items'] as List<dynamic>? ??
          envelope.data['incentives'] as List<dynamic>? ??
          (envelope.data is List ? envelope.data as List : const <dynamic>[]);

      return rawList
          .whereType<Map>()
          .map((m) => PromoGroup.fromJson(m.cast<String, dynamic>()))
          .toList();
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<List<PromoView>> fetchCustomerPromotions(String customerId) async {
    try {
      final res = await _client.get<Object?>(
        AppConstants.customerPromotionsEndpoint(customerId),
      );

      final envelope = ApiEnvelope.fromBody(res.data);
      final rawList = envelope.data['promotions'] as List<dynamic>? ??
          envelope.data['items'] as List<dynamic>? ??
          (envelope.data is List ? envelope.data as List : const <dynamic>[]);

      return rawList
          .whereType<Map>()
          .map((m) => PromoView.fromJson(m.cast<String, dynamic>()))
          .toList();
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<DiscountAuthorityModel> fetchDiscountAuthority() async {
    try {
      final res = await _client.get<Object?>(
        AppConstants.discountAuthorityEndpoint,
      );

      final envelope = ApiEnvelope.fromBody(res.data);
      final data = envelope.object('authority') ?? envelope.data;
      return DiscountAuthorityModel.fromJson(data);
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }
}
