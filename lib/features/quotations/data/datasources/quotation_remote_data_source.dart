import 'package:dio/dio.dart';
import 'package:isi_steel_sales_mobile/core/network/api_envelope.dart';
import 'package:isi_steel_sales_mobile/features/quotations/data/models/quotation_dto.dart';

abstract class QuotationRemoteDataSource {
  Future<List<QuotationDto>> getQuotations({
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

  Future<QuotationDetailDto> getQuotationDetail(String id);

  Future<QuotationDetailDto> updateQuotationHeader(
    String id, {
    required String shipmentType,
    String? shipTo,
    String? paymentTerm,
    String? customerReference,
    String? remarks,
  });

  Future<QuotationDetailDto> addLine(
    String id, {
    required String materialNumber,
    required double quantity,
    String? unit,
  });

  Future<QuotationDetailDto> updateLineQuantity(
    String id,
    String lineId, {
    required double quantity,
  });

  Future<QuotationDetailDto> removeLine(String id, String lineId);

  Future<QuotationDetailDto> updateDiscounts(
    String id,
    List<Map<String, dynamic>> discounts,
  );

  Future<QuotationDetailDto> previewQuotation(String id);

  Future<QuotationDetailDto> repriceQuotation(String id);

  Future<QuotationDetailDto> submitQuotation(String id);

  Future<QuotationDetailDto> cancelQuotation(String id);
}

class QuotationRemoteDataSourceImpl implements QuotationRemoteDataSource {
  const QuotationRemoteDataSourceImpl(this._client);

  final Dio _client;
  static const String _endpoint = '/api/v1/mobile/quotations';

  @override
  Future<List<QuotationDto>> getQuotations({
    String? status,
    String? customerId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.get<dynamic>(
      _endpoint,
      queryParameters: {
        if (status != null) 'status': status,
        if (customerId != null) 'customerId': customerId,
        'page': page,
        'pageSize': pageSize,
      },
    );

    final envelope = ApiEnvelope.fromBody(response.data);
    // Assuming the list of items is under the 'items' key in data or just mapped.
    // Documentation isn't explicit on the list key name, but typically it is `items` or `quotations`
    final list = envelope.list('items').isEmpty ? envelope.list('quotations') : envelope.list('items');
    return list.map((json) => QuotationDto.fromJson(json)).toList();
  }

  @override
  Future<String> createQuotation({
    required String customerId,
    String shipmentType = 'Pickup',
    String? shipTo,
  }) async {
    final response = await _client.post<dynamic>(
      _endpoint,
      data: {
        'customerId': customerId,
        'shipmentType': shipmentType,
        if (shipTo != null) 'shipTo': shipTo,
      },
      options: Options(
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // Endpoint returns 201 with Location header, usually Dio exposes headers
    final location = response.headers.value('location');
    if (location != null && location.isNotEmpty) {
      final segments = Uri.parse(location).pathSegments;
      return segments.last;
    }
    
    // Fallback if returned in body
    final envelope = ApiEnvelope.fromBody(response.data);
    return envelope.data['id'] as String;
  }

  @override
  Future<QuotationDetailDto> getQuotationDetail(String id) async {
    final response = await _client.get<dynamic>('$_endpoint/$id');
    final envelope = ApiEnvelope.fromBody(response.data);
    return QuotationDetailDto.fromJson(envelope.data);
  }

  @override
  Future<QuotationDetailDto> updateQuotationHeader(
    String id, {
    required String shipmentType,
    String? shipTo,
    String? paymentTerm,
    String? customerReference,
    String? remarks,
  }) async {
    final response = await _client.put<dynamic>(
      '$_endpoint/$id',
      data: {
        'shipmentType': shipmentType,
        'shipTo': shipTo,
        'paymentTerm': paymentTerm,
        'customerReference': customerReference,
        'remarks': remarks,
      },
    );
    final envelope = ApiEnvelope.fromBody(response.data);
    return QuotationDetailDto.fromJson(envelope.data);
  }

  @override
  Future<QuotationDetailDto> addLine(
    String id, {
    required String materialNumber,
    required double quantity,
    String? unit,
  }) async {
    final response = await _client.post<dynamic>(
      '$_endpoint/$id/lines',
      data: {
        'materialNumber': materialNumber,
        'quantity': quantity,
        if (unit != null) 'unit': unit,
      },
    );
    final envelope = ApiEnvelope.fromBody(response.data);
    return QuotationDetailDto.fromJson(envelope.data);
  }

  @override
  Future<QuotationDetailDto> updateLineQuantity(
    String id,
    String lineId, {
    required double quantity,
  }) async {
    final response = await _client.put<dynamic>(
      '$_endpoint/$id/lines/$lineId',
      data: {
        'quantity': quantity,
      },
    );
    final envelope = ApiEnvelope.fromBody(response.data);
    return QuotationDetailDto.fromJson(envelope.data);
  }

  @override
  Future<QuotationDetailDto> removeLine(String id, String lineId) async {
    final response = await _client.delete<dynamic>('$_endpoint/$id/lines/$lineId');
    final envelope = ApiEnvelope.fromBody(response.data);
    return QuotationDetailDto.fromJson(envelope.data);
  }

  @override
  Future<QuotationDetailDto> updateDiscounts(
    String id,
    List<Map<String, dynamic>> discounts,
  ) async {
    final response = await _client.put<dynamic>(
      '$_endpoint/$id/discounts',
      data: {
        'lines': discounts,
      },
    );
    final envelope = ApiEnvelope.fromBody(response.data);
    return QuotationDetailDto.fromJson(envelope.data);
  }

  @override
  Future<QuotationDetailDto> previewQuotation(String id) async {
    final response = await _client.get<dynamic>('$_endpoint/$id/preview');
    final envelope = ApiEnvelope.fromBody(response.data);
    return QuotationDetailDto.fromJson(envelope.data);
  }

  @override
  Future<QuotationDetailDto> repriceQuotation(String id) async {
    final response = await _client.post<dynamic>('$_endpoint/$id/reprice');
    final envelope = ApiEnvelope.fromBody(response.data);
    return QuotationDetailDto.fromJson(envelope.data);
  }

  @override
  Future<QuotationDetailDto> submitQuotation(String id) async {
    final response = await _client.post<dynamic>('$_endpoint/$id/submit');
    final envelope = ApiEnvelope.fromBody(response.data);
    return QuotationDetailDto.fromJson(envelope.data);
  }

  @override
  Future<QuotationDetailDto> cancelQuotation(String id) async {
    final response = await _client.post<dynamic>('$_endpoint/$id/cancel');
    final envelope = ApiEnvelope.fromBody(response.data);
    return QuotationDetailDto.fromJson(envelope.data);
  }
}
