import 'package:isi_steel_sales_mobile/core/network/api_envelope.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/auth_session.dart';

class AuthSessionModel extends AuthSession {
  const AuthSessionModel({
    required super.sessionId,
    required super.deviceId,
    required super.createdAt,
    required super.isCurrent,
    super.deviceName,
    super.ipAddress,
    super.userAgent,
    super.lastSeenAt,
    super.expiresAt,
  });

  factory AuthSessionModel.fromJson(DataMap json) => AuthSessionModel(
        sessionId: json['sessionId']?.toString() ?? '',
        deviceId: json['deviceId']?.toString() ?? '',
        deviceName: json['deviceName'] as String?,
        ipAddress: json['ipAddress'] as String?,
        userAgent: json['userAgent'] as String?,
        createdAt: parseUtc(json['createdAt']) ?? DateTime.now().toUtc(),
        lastSeenAt: parseUtc(json['lastSeenAt']),
        expiresAt: parseUtc(json['expiresAt']),
        isCurrent: json['isCurrent'] as bool? ?? false,
      );
}
