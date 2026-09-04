import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/auth_profile.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/otp_challenge.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/auth_session.dart';

/// The contract the domain depends on. The data layer provides the
/// implementation; the domain never knows about Dio, JSON, or storage.
abstract interface class AuthRepository {
  /// [identifier] is a personnel number **or** an e-mail address — the server
  /// resolves whichever arrives, so the login form carries a single field.
  ResultFuture<AuthProfile> login({
    required String identifier,
    required String password,
    String? pushToken,
    bool rememberDevice,
  });

  /// The persisted session, resolved from cache so a cold start on no signal
  /// still boots into the app.
  ResultFuture<AuthProfile> getCurrentUser();

  /// Re-reads `GET /auth/me`, falling back to the cached copy when offline or
  /// when the call fails — a stale permission set beats an empty screen.
  ResultFuture<AuthProfile> refreshProfile();

  /// The cached profile without any network call. Null when signed out.
  ResultFuture<AuthProfile?> cachedProfile();

  /// Ends the local session, and best-effort revokes it server-side.
  /// [allDevices] ends every session — offer it after a password change or a
  /// suspected compromise.
  // ── Phone sign-in with OTP ───────────────────────────────────────
  //
  // Three steps, in order. The password is seen only by [sendOtp] and is never
  // re-sent; everything afterwards presents the `verificationId`.

  /// Step 1 — checks the password and sends a code.
  ResultFuture<OtpChallenge> sendOtp({
    required String phoneNumber,
    required String password,
  });

  /// Step 2 — confirms the code. Issues no token.
  ResultFuture<void> verifyOtp({
    required String verificationId,
    required String otp,
  });

  /// Step 3 — exchanges the verified attempt for a session, and resolves the
  /// profile exactly as password sign-in does.
  ResultFuture<AuthProfile> completePhoneLogin({
    required String verificationId,
  });

  /// A fresh code for the attempt in flight.
  ResultFuture<OtpChallenge> resendOtp({required String verificationId});

  ResultFuture<void> logout({bool allDevices});

  ResultFuture<List<AuthSession>> listSessions();
  ResultFuture<void> revokeSession(String sessionId);

  ResultFuture<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Always reports success, whether or not the address is registered —
  /// anything else would make this an account-enumeration oracle.
  ResultFuture<void> forgotPassword(String email);

  ResultFuture<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  });

  ResultFuture<void> verifyEmail({
    required String userId,
    required String token,
  });

  ResultFuture<void> resendVerification(String email);
}
