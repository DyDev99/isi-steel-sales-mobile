import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/auth_token.dart';

/// The OAuth 2.0 token response from `/auth/login`, `/auth/refresh` and
/// `/auth/token`.
///
/// **These three endpoints are not wrapped.** They return the raw RFC 6749
/// §5.1 token response — snake_case field names, no `data` envelope, no user
/// object — because they are served by OpenIddict as a real OAuth token
/// endpoint rather than by a bespoke JSON API. `/auth/me` and every business
/// endpoint *are* wrapped. Do not write one deserialiser for both.
///
/// The profile is fetched separately from `/auth/me`; nothing about the user
/// arrives here.
class AuthTokenModel extends AuthToken {
  const AuthTokenModel({
    required super.accessToken,
    required super.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresIn,
  });

  final String tokenType;

  /// Access-token lifetime in seconds — 899, i.e. 15 minutes.
  ///
  /// Recorded for diagnostics only. **Do not schedule a refresh off it.**
  /// Refresh reactively on 401: a timer keeps waking a phone asleep in a
  /// pocket and drifts against the server clock.
  final int? expiresIn;

  /// Reads the raw OAuth response.
  ///
  /// [id_token] is deliberately ignored. It is an OIDC identity token that
  /// carries none of the territory, depot or feature-flag data the app needs,
  /// all of which comes from `/auth/me`.
  factory AuthTokenModel.fromMap(DataMap map) => AuthTokenModel(
        accessToken: map['access_token'] as String? ?? '',
        refreshToken: map['refresh_token'] as String? ?? '',
        tokenType: map['token_type'] as String? ?? 'Bearer',
        expiresIn: (map['expires_in'] as num?)?.toInt(),
      );

  bool get isUsable => accessToken.isNotEmpty && refreshToken.isNotEmpty;

  DataMap toMap() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'token_type': tokenType,
        if (expiresIn != null) 'expires_in': expiresIn,
      };
}
