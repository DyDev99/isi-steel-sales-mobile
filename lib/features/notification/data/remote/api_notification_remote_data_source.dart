import 'package:dio/dio.dart';
import 'package:isi_steel_sales_mobile/core/constants/app_constant.dart';
import 'package:isi_steel_sales_mobile/core/network/api_envelope.dart';
import 'package:isi_steel_sales_mobile/core/network/api_error.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/notification/data/models/notification_api_mapper.dart';
import 'package:isi_steel_sales_mobile/features/notification/data/remote/notification_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/entities/notification_counts.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/entities/notification_message.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/entities/notification_preferences.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/entities/push_registration.dart';

/// The real notification API (`docs/features/notification-mobile.md` §3).
///
/// ## Two response shapes, one envelope family
///
/// The inbox list returns `data` as a **JSON array** — [ApiListEnvelope] — while
/// counts, preferences and device registration return `data` as an object —
/// [ApiEnvelope]. Running the wrong reader over either throws "missing its
/// payload", which is why the two are used explicitly here rather than behind
/// one helper that guesses.
///
/// Mutations answer `204 No Content` with no envelope at all, so they are not
/// parsed: a reader run over an empty body is how a successful call starts
/// reporting failure.
class ApiNotificationRemoteDataSource implements NotificationRemoteDataSource {
  const ApiNotificationRemoteDataSource(this._client);

  final Dio _client;

  @override
  Future<NotificationPage> fetchPage({
    DateTime? since,
    int pageNumber = 1,
    int pageSize = AppConstants.notificationPageSize,
  }) async {
    try {
      final response = await _client.get<Object?>(
        AppConstants.notificationsEndpoint,
        queryParameters: {
          // Only ever a server-issued `syncTimestamp`. See
          // `NotificationPage.syncTimestamp` for why the device clock must
          // never appear here.
          if (since != null) 'since': since.toUtc().toIso8601String(),
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      );

      final envelope = ApiListEnvelope.fromBody(response.data);
      final items = <NotificationMessage>[];
      for (final json in envelope.items) {
        final parsed = NotificationApiMapper.fromJson(json);
        // A row with no usable id is skipped rather than failing the page. One
        // malformed record must not cost a rep the other ninety-nine — and
        // the next catch-up will present it again if the server fixes it.
        if (parsed != null) items.add(parsed);
      }

      final metadata = envelope.metadata;
      return NotificationPage(
        items: items,
        // Read from the server rather than inferred from `items.length ==
        // pageSize`: `pageSize` is clamped to 200 rather than rejected, so a
        // length comparison against what was *asked for* can both loop forever
        // and stop early.
        hasMore: metadata?.hasNextPage ?? false,
        syncTimestamp: metadata?.syncTimestamp,
      );
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<NotificationCounts> fetchCounts() async {
    try {
      final response =
          await _client.get<DataMap>(AppConstants.notificationCountsEndpoint);
      final envelope = ApiEnvelope.fromBody(response.data);
      return NotificationApiMapper.countsFromJson(envelope.data);
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<void> markRead(String id) async {
    try {
      await _client.patch<void>(AppConstants.notificationReadEndpoint(id));
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<int> markAllRead({String? categoryCode}) async {
    try {
      final response = await _client.patch<DataMap>(
        AppConstants.notificationReadAllEndpoint,
        queryParameters: {
          if (categoryCode != null) 'category': categoryCode,
        },
      );
      // `data` is a bare integer here, not an object, so `ApiEnvelope` would
      // reject it as a missing payload — this endpoint is read directly.
      final body = response.data;
      if (body == null) return 0;
      return (body['data'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<void> recordAction(
    String id, {
    String? actionId,
    DateTime? occurredAt,
  }) async {
    try {
      await _client.post<void>(
        AppConstants.notificationActionEndpoint(id),
        data: <String, Object?>{
          // Omitted when the rep acted inside the record rather than from a
          // notification button — §8.3 allows exactly that, and sending an id
          // the notification does not offer answers
          // `400 Notification.ActionNotOffered`.
          if (actionId != null) 'actionId': actionId,
          if (occurredAt != null)
            // An explicit offset, never a bare local timestamp: the offline
            // queue stamps these with `DateTime.now()`, and in Cambodia (UTC+7)
            // a server guessing UTC moves a morning acknowledgement seven hours
            // into the previous night.
            'occurredAt': formatIsoOffset(occurredAt),
        },
      );
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<void> dismiss(String id) async {
    try {
      await _client.delete<void>(AppConstants.notificationDismissEndpoint(id));
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<void> invokeAction({
    required String endpoint,
    required String method,
  }) async {
    try {
      await _client.request<void>(
        endpoint,
        options: Options(method: method.toUpperCase()),
      );
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<PushRegistrationResult> registerDevice(
      PushRegistration registration) async {
    try {
      final response = await _client.post<DataMap>(
        AppConstants.deviceRegisterEndpoint,
        data: NotificationApiMapper.registrationToJson(registration),
      );
      final envelope = ApiEnvelope.fromBody(response.data);
      return NotificationApiMapper.registrationFromJson(envelope.data);
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<void> deregisterDevice(String deviceId) async {
    try {
      await _client.delete<void>(AppConstants.deviceEndpoint(deviceId));
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<NotificationPreferences> fetchPreferences() async {
    try {
      final response = await _client
          .get<DataMap>(AppConstants.notificationPreferencesEndpoint);
      final envelope = ApiEnvelope.fromBody(response.data);
      return NotificationApiMapper.preferencesFromJson(envelope.data);
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<NotificationPreferences> savePreferences(
      NotificationPreferences preferences) async {
    try {
      final response = await _client.put<DataMap>(
        AppConstants.notificationPreferencesEndpoint,
        data: NotificationApiMapper.preferencesToJson(preferences),
      );
      // The PUT echoes the saved document. Falling back to what was sent — for
      // a 204, or a body the reader rejects — is right: the server accepted it,
      // so throwing here would tell the rep their saved settings failed to save.
      try {
        final envelope = ApiEnvelope.fromBody(response.data);
        return NotificationApiMapper.preferencesFromJson(envelope.data);
      } on Object {
        return preferences;
      }
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }
}
