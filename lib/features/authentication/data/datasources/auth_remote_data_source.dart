import 'package:dio/dio.dart';
import 'package:isi_steel_sales_mobile/core/constants/app_constant.dart';
import 'package:isi_steel_sales_mobile/core/device/device_identity.dart';
import 'package:isi_steel_sales_mobile/core/network/api_envelope.dart';
import 'package:isi_steel_sales_mobile/core/network/api_error.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/models/auth_profile_model.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/models/auth_session_model.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/models/auth_token_model.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/otp_challenge.dart';

abstract interface class AuthRemoteDataSource {
  /// Signs in with a personnel number **or** an e-mail address.
  ///
  /// The server resolves whichever arrives, which is why the login form has a
  /// single field labelled "Employee ID or e-mail": field representatives know
  /// their personnel number — it is on their badge and payslip — and often
  /// have no company e-mail, while portal users keep using theirs.
  Future<AuthTokenModel> login({
    required String identifier,
    required String password,
    String? pushToken,
    bool rememberDevice,
  });

  /// The signed-in employee's profile, including permissions and feature flags.
  Future<AuthProfileModel> getProfile();

  // ── Phone sign-in with OTP (three steps, in order) ─────────────────

  /// Step 1. **The only call that sees the password.**
  Future<OtpChallenge> sendOtp({
    required String phoneNumber,
    required String password,
  });

  /// Step 2. Returns 204 and issues **no token** — it only moves the attempt
  /// to `Verified`.
  Future<void> verifyOtp({
    required String verificationId,
    required String otp,
  });

  /// Step 3. Exchanges the verified attempt for the token pair. Takes the id
  /// only — the endpoint does not accept the password.
  Future<AuthTokenModel> phoneLogin({required String verificationId});

  /// A fresh code for an attempt in flight. Takes the id only.
  Future<OtpChallenge> resendOtp({required String verificationId});

  /// Ends this session, or every session when [allDevices] is true.
  Future<void> logout({required String refreshToken, bool allDevices});

  Future<List<AuthSessionModel>> listSessions();
  Future<void> revokeSession(String sessionId);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> forgotPassword(String email);
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  });
  Future<void> verifyEmail({required String userId, required String token});
  Future<void> resendVerification(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl({
    required Dio authedClient,
    required Dio bareClient,
    required DeviceIdentity device,
  })  : _authed = authedClient,
        _bare = bareClient,
        _device = device;

  /// Carries [AuthInterceptor]. Used for everything that needs a bearer token.
  final Dio _authed;

  /// No auth interceptor. Used for the endpoints that establish or recover a
  /// session — sending a stale bearer token to `/auth/login` would at best be
  /// pointless and at worst trip the refresh path on a 401 that is really
  /// "wrong password".
  final Dio _bare;

  final DeviceIdentity _device;

  @override
  Future<AuthTokenModel> login({
    required String identifier,
    required String password,
    String? pushToken,
    bool rememberDevice = true,
  }) async {
    try {
      final res = await _bare.post<DataMap>(
        AppConstants.loginEndpoint,
        data: {
          // `employeeId` accepts an e-mail address too; the server resolves it.
          'employeeId': identifier.trim(),
          'password': password,
          // Optional, but always sent: it is what turns the session list into
          // something a rep can act on when they lose a handset.
          'device': await _device.describe(
            pushToken: pushToken,
            rememberDevice: rememberDevice,
          ),
        },
      );

      final token = AuthTokenModel.fromMap(res.data ?? const {});
      if (!token.isUsable) {
        throw const ApiException(ApiError(
          code: ApiErrorCodes.unknown,
          detail: 'Login succeeded but returned no usable token pair.',
        ));
      }
      return token;
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<OtpChallenge> sendOtp({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final res = await _bare.post<DataMap>(
        AppConstants.sendOtpEndpoint,
        data: {
          // As the user typed it. The server matches on digits, so
          // `012 345 201` and `+855 12 345 201` resolve to the same account —
          // reformatting here would only risk breaking a form the server
          // already accepts.
          'phoneNumber': phoneNumber,
          'password': password,
          // Carried through to the session opened at step 3, which is why they
          // are sent here rather than at login.
          'deviceId': await _device.deviceId(),
          'deviceName': (await _device.describe())['deviceName'],
        },
      );

      // Wrapped, unlike step 3.
      return OtpChallenge.fromJson(
        ApiEnvelope.fromBody(res.data).data,
      );
    } on DioException catch (e) {
      // problem+json here — see `phoneLogin` for the other half.
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<void> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    try {
      await _bare.post<void>(
        AppConstants.verifyOtpEndpoint,
        data: {'verificationId': verificationId, 'otp': otp},
      );
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<AuthTokenModel> phoneLogin({required String verificationId}) async {
    try {
      final res = await _bare.post<DataMap>(
        AppConstants.mobileLoginEndpoint,
        // The password is deliberately absent: it was spent at step 1 and this
        // endpoint does not accept it.
        data: {'verificationId': verificationId},
      );

      // Raw OAuth payload — **not** wrapped, unlike steps 1 and 2. One flow,
      // two parsers.
      final token = AuthTokenModel.fromMap(res.data ?? const {});
      if (!token.isUsable) {
        throw const ApiException(ApiError(
          code: ApiErrorCodes.unknown,
          detail: 'Phone login returned no usable token pair.',
        ));
      }
      return token;
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<OtpChallenge> resendOtp({required String verificationId}) async {
    try {
      final res = await _bare.post<DataMap>(
        AppConstants.resendOtpEndpoint,
        // Takes only the identifier — never ask for the password again.
        data: {'verificationId': verificationId},
      );
      return OtpChallenge.fromJson(
        ApiEnvelope.fromBody(res.data).data,
      );
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<AuthProfileModel> getProfile() async {
    try {
      final res = await _authed.get<DataMap>(AppConstants.currentUserEndpoint);
      // Wrapped, unlike the token endpoints above.
      return AuthProfileModel.fromJson(ApiEnvelope.fromBody(res.data).data);
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  /// Server-side revocation. Returns 204.
  ///
  /// The caller clears secure storage regardless of the outcome here — a token
  /// discarded locally is unusable whether or not the server was told.
  @override
  Future<void> logout({
    required String refreshToken,
    bool allDevices = false,
  }) async {
    try {
      await _authed.post<void>(
        AppConstants.logoutEndpoint,
        data: {'refreshToken': refreshToken, 'allDevices': allDevices},
        options: Options(
          // By the time this runs the session may already be gone locally, so
          // a 401 is expected and uninteresting. Letting it come back as a
          // plain response keeps it out of the interceptor's refresh path,
          // which would otherwise burn a connect timeout re-authenticating a
          // session that no longer exists.
          validateStatus: (_) => true,
        ),
      );
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  @override
  Future<List<AuthSessionModel>> listSessions() async {
    try {
      final res = await _authed.get<DataMap>(AppConstants.sessionsEndpoint);
      final body = res.data ?? const <String, dynamic>{};
      // `data` here is an array rather than an object, so this is the one
      // wrapped endpoint ApiEnvelope cannot read directly.
      final rows = (body['data'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((e) => AuthSessionModel.fromJson(e.cast<String, dynamic>()))
          .toList();
      return rows;
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  /// Revokes one session — this is "I lost my phone".
  @override
  Future<void> revokeSession(String sessionId) async {
    try {
      await _authed
          .delete<void>('${AppConstants.sessionsEndpoint}/$sessionId');
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }

  /// Re-verifies [currentPassword] even though the caller is already
  /// authenticated. That is deliberate on the server's part: it is what stops
  /// a borrowed unlocked handset from becoming a permanent account takeover.
  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _post(
        _authed,
        AppConstants.changePasswordEndpoint,
        {'currentPassword': currentPassword, 'newPassword': newPassword},
      );

  /// Always succeeds, whether or not the address exists.
  ///
  /// Do not "improve" the UX by reporting an unknown address — that turns the
  /// endpoint into an account-enumeration oracle. Show "if that address is
  /// registered, a link is on its way".
  @override
  Future<void> forgotPassword(String email) =>
      _post(_bare, AppConstants.forgotPasswordEndpoint, {'email': email.trim()});

  @override
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) =>
      _post(_bare, AppConstants.resetPasswordEndpoint, {
        'email': email.trim(),
        'token': token,
        'newPassword': newPassword,
      });

  @override
  Future<void> verifyEmail({required String userId, required String token}) =>
      _post(_bare, AppConstants.verifyEmailEndpoint,
          {'userId': userId, 'token': token});

  @override
  Future<void> resendVerification(String email) => _post(
      _bare, AppConstants.resendVerificationEndpoint, {'email': email.trim()});

  Future<void> _post(Dio client, String path, DataMap body) async {
    try {
      await client.post<void>(path, data: body);
    } on DioException catch (e) {
      throw ApiException(ApiError.fromDio(e));
    }
  }
}
