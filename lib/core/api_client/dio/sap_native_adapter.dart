import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:isi_steel_sales_mobile/core/api_client/dio/sap_native_transport.dart';

/// A Dio [HttpClientAdapter] that sends over the platform TLS stack via
/// [SapNativeTransport] instead of Dart's BoringSSL.
///
/// Installed only on the SAP client (see `DioFactory`), and only where
/// [SapNativeTransport.isSupported]. It replaces **just the transport** — the
/// bottom layer Dio calls after every interceptor has run — so the connectivity,
/// auth, logging, retry and error-mapping interceptors all still execute exactly
/// as before. Nothing above `core/api_client` is aware the socket is native.
///
/// Certificate pinning is not lost by swapping off `_applyTls`: it moves into
/// the native side, which pins to the same `SAP_CERT_SHA256`. See
/// `SapNativeHttpClient` (Kotlin).
class SapNativeAdapter implements HttpClientAdapter {
  const SapNativeAdapter();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // Dio has already encoded the body to a byte stream by the time the adapter
    // is reached, so the request body is read from [requestStream], not
    // `options.data`.
    String? body;
    if (requestStream != null) {
      final builder = BytesBuilder(copy: false);
      await for (final chunk in requestStream) {
        builder.add(chunk);
      }
      if (builder.length > 0) {
        body = utf8.decode(builder.takeBytes(), allowMalformed: true);
      }
    }

    final headers = <String, String>{};
    options.headers.forEach((key, value) {
      if (value == null) return;
      // Content-Length is managed by the native connection; forwarding Dio's
      // copy can conflict with the encoding it chooses.
      if (key.toLowerCase() == Headers.contentLengthHeader) return;
      headers[key] = value.toString();
    });

    try {
      final response = await SapNativeTransport.send(
        method: options.method,
        // `options.uri` is the fully composed URL: base + path + query.
        url: options.uri.toString(),
        headers: headers,
        body: body,
        timeout: options.receiveTimeout ?? const Duration(seconds: 20),
      );

      final responseHeaders = <String, List<String>>{};
      response.headers.forEach((key, value) {
        responseHeaders[key.toLowerCase()] = [value];
      });
      // Guarantee a content-type so Dio's response decoder runs; the SAP facade
      // sometimes omits it on error responses.
      responseHeaders.putIfAbsent(
        Headers.contentTypeHeader,
        () => [Headers.jsonContentType],
      );

      return ResponseBody.fromBytes(
        utf8.encode(response.body),
        response.statusCode,
        headers: responseHeaders,
      );
    } on SapNativeTransportException catch (e) {
      // Surface as a DioException so the standard error mapper turns it into a
      // typed ApiException, exactly as a Dart-side transport failure would be.
      throw DioException.connectionError(
        requestOptions: options,
        reason: e.message,
      );
    }
  }

  @override
  void close({bool force = false}) {}
}
