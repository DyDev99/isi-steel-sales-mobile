import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';

/// The success envelope every business endpoint wraps its payload in:
///
/// ```json
/// { "success": true, "message": "…", "data": { … },
///   "metadata": { … }, "traceId": "…", "timestamp": "…" }
/// ```
///
/// **The OAuth token endpoints are the exception** — `/auth/login`,
/// `/auth/refresh` and `/auth/token` return the raw RFC 6749 token response
/// with no `data` wrapper. Do not run one deserialiser over both.
///
/// Note that [success] is *not* how failure is detected. Branch on the HTTP
/// status code: an error response is a problem document that has no `success`
/// field at all, so reading it would mean reading a null.
class ApiEnvelope {
  const ApiEnvelope({
    required this.data,
    this.message,
    this.metadata,
    this.traceId,
  });

  /// The payload. Its shape is endpoint-specific — the customer list nests a
  /// `customers` array under here, and the customer detail nests one level
  /// deeper again under `data.customer`.
  final DataMap data;

  /// Server-localised and safe to show.
  final String? message;

  final ApiMetadata? metadata;
  final String? traceId;

  factory ApiEnvelope.fromBody(Object? body) {
    if (body is! Map) {
      throw const ServerException(
          message: 'The server returned an unexpected response.');
    }
    final map = body.cast<String, dynamic>();
    final data = map['data'];
    if (data is! Map) {
      throw const ServerException(
          message: 'The server response was missing its payload.');
    }
    return ApiEnvelope(
      data: data.cast<String, dynamic>(),
      message: map['message'] as String?,
      metadata: ApiMetadata.fromJson(map['metadata']),
      traceId: map['traceId'] as String?,
    );
  }

  /// The list under [key], as raw JSON objects.
  List<DataMap> list(String key) =>
      (data[key] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();

  /// The nested object under [key], for payloads like `data.customer`.
  DataMap? object(String key) =>
      (data[key] as Map?)?.cast<String, dynamic>();
}

/// Paging and sync bookkeeping from the envelope's `metadata` block.
class ApiMetadata {
  const ApiMetadata({
    required this.page,
    required this.pageSize,
    required this.totalRecords,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
    this.syncTimestamp,
    this.isDeltaSync = false,
  });

  final int page;

  /// **Read this rather than assuming you got what you asked for.** The server
  /// clamps `pageSize` to 200 silently instead of rejecting a larger value —
  /// deliberately, so a mistyped page size on a flaky connection degrades
  /// instead of failing.
  final int pageSize;

  final int totalRecords;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  /// The server's clock at the moment the query ran, and the **only** valid
  /// source for the next `modifiedSince`.
  ///
  /// Never substitute the device clock here. A phone running ten minutes fast
  /// would ask for changes since the future, receive an empty delta, store
  /// that timestamp, and never sync again — a silent, permanent failure. The
  /// server rejects a `modifiedSince` more than five minutes ahead of its own
  /// time precisely to catch clients that get this wrong.
  final DateTime? syncTimestamp;

  /// True when the response was filtered by `modifiedSince`, which also means
  /// tombstones (`deleted: true`) may be present.
  final bool isDeltaSync;

  static ApiMetadata? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final map = raw.cast<String, dynamic>();
    return ApiMetadata(
      page: (map['page'] as num?)?.toInt() ?? 1,
      pageSize: (map['pageSize'] as num?)?.toInt() ?? 0,
      totalRecords: (map['totalRecords'] as num?)?.toInt() ?? 0,
      totalPages: (map['totalPages'] as num?)?.toInt() ?? 0,
      hasNextPage: map['hasNextPage'] as bool? ?? false,
      hasPreviousPage: map['hasPreviousPage'] as bool? ?? false,
      syncTimestamp: parseUtc(map['syncTimestamp']),
      isDeltaSync: map['isDeltaSync'] as bool? ?? false,
    );
  }
}

/// Parses an API timestamp as UTC.
///
/// Every timestamp the API returns is UTC ISO-8601. `DateTime.parse` honours a
/// trailing `Z`, but a server that ever drops it would silently produce a
/// local-time `DateTime` that compares wrongly against a watermark — so the
/// result is forced to UTC rather than trusted. Convert for display only.
DateTime? parseUtc(Object? raw) {
  if (raw is DateTime) return raw.toUtc();
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toUtc();
}
