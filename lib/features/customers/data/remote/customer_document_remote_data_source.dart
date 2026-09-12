import 'dart:io';

import 'package:dio/dio.dart';
import 'package:isi_steel_sales_mobile/core/constants/app_constant.dart';
import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/network/api_envelope.dart';
import 'package:isi_steel_sales_mobile/core/network/api_error.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_document_mapper.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_document.dart';

/// `/api/v1/mobile/customers/{customerId}/documents`.
///
/// `{customerId}` accepts **either** the platform id **or** the customer code
/// (which for a SAP-originated customer is its SAP number). The platform id is
/// what the field flow uses: a shop registered on a market stall has no SAP
/// number yet — an operator pushes it to the ERP hours or days later — and the
/// representative has taken the photographs *now*.
abstract interface class CustomerDocumentRemoteDataSource {
  /// Uploads one file into one slot. There is no batch endpoint: a failed
  /// batch tells you nothing about which photograph to retake.
  Future<CustomerDocument> upload({
    required String customerId,
    required CustomerDocumentType type,
    required File file,
    DateTime? capturedAt,
  });

  Future<CustomerDocumentsState> fetch(String customerId);

  Future<void> delete({
    required String customerId,
    required String documentId,
  });
}

class ApiCustomerDocumentRemoteDataSource
    implements CustomerDocumentRemoteDataSource {
  const ApiCustomerDocumentRemoteDataSource(this._client);

  final Dio _client;

  /// The server enforces this too; checking first turns a wasted upload on a
  /// 3G link into an immediate, specific message.
  static const int maxBytes = 10 * 1024 * 1024;

  String _path(String customerId) =>
      '${AppConstants.customersEndpoint}/$customerId/documents';

  @override
  Future<CustomerDocument> upload({
    required String customerId,
    required CustomerDocumentType type,
    required File file,
    DateTime? capturedAt,
  }) async {
    try {
      final media = _mediaTypeFor(file.path, type);

      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          // Stated, never inferred. The server rejects a Content-Type that
          // disagrees with the extension, which is what catches a PDF renamed
          // to `.jpg` to reach a photo slot.
          contentType: media,
        ),
        'Type': type.code,
        // Photo time, not upload time. A queued upload can reach the server
        // hours after the visit; without this the record is dated to whenever
        // the connection came back.
        if (capturedAt != null)
          'CapturedAt': capturedAt.toUtc().toIso8601String(),
      });

      final res = await _client.post<dynamic>(_path(customerId), data: form);
      final document =
          CustomerDocumentMapper.fromJson(ApiEnvelope.fromBody(res.data).data);
      if (document == null) {
        throw const ServerException(
            message: 'The upload response was missing its payload.');
      }
      return document;
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<CustomerDocumentsState> fetch(String customerId) async {
    try {
      final res = await _client.get<dynamic>(_path(customerId));
      return CustomerDocumentMapper.stateFromJson(
          ApiEnvelope.fromBody(res.data).data);
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<void> delete({
    required String customerId,
    required String documentId,
  }) async {
    try {
      await _client.delete<void>('${_path(customerId)}/$documentId');
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  /// The media type for [path], constrained by what [type] accepts.
  ///
  /// A PDF reaching a photo slot is rejected here rather than on the wire — the
  /// server answers `Customer.DocumentExtensionNotAllowed`, and a rep on a
  /// market connection should not spend the upload to learn that.
  static DioMediaType _mediaTypeFor(String path, CustomerDocumentType type) {
    final extension = path.toLowerCase().split('.').last;

    if (extension == 'pdf') {
      if (!type.acceptsPdf) {
        throw const ServerException(
          message: 'A PDF can only be attached to the patent/tax or VAT slot.',
        );
      }
      return DioMediaType('application', 'pdf');
    }

    return switch (extension) {
      'png' => DioMediaType('image', 'png'),
      // The camera writes .jpg; anything else has already been rejected above
      // or is a JPEG under another spelling.
      _ => DioMediaType('image', 'jpeg'),
    };
  }
}
