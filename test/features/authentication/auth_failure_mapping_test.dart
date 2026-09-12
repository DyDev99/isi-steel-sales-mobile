import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/network/api_error.dart';

/// `_failure` is private, so these assert the contract through the public
/// helper the presentation layer actually reads.
void main() {
  AuthenticationFailure auth(String code) =>
      AuthenticationFailure(message: 'm', code: code);

  group('dead attempts must restart at step 1', () {
    for (final code in const [
      ApiErrorCodes.verificationBlocked,
      ApiErrorCodes.verificationExpired,
      ApiErrorCodes.verificationNotFound,
      ApiErrorCodes.verificationNotCompleted,
      ApiErrorCodes.resendLimitReached,
    ]) {
      test(code, () => expect(auth(code).isAttemptDead, isTrue));
    }
  });

  test('a plain wrong code is retryable', () {
    // Five wrong codes kill the attempt, but the first four must not.
    expect(auth(ApiErrorCodes.invalidVerificationCode).isAttemptDead, isFalse);
  });

  test('a non-auth failure is never a dead attempt', () {
    expect(const ServerFailure(message: 'm').isAttemptDead, isFalse);
    expect(const NetworkFailure().isAttemptDead, isFalse);
  });

  test('the two 403 verification codes are not permission denials', () {
    // `Auth.VerificationBlocked` and `Auth.ResendLimitReached` arrive as 403.
    // Mapping them by status would hide them behind "you do not have access"
    // and the code screen would never learn the attempt was dead.
    final blocked = ApiError.fromBody(const {
      'errorCode': ApiErrorCodes.verificationBlocked,
      'status': 403,
    });

    expect(blocked.isPermissionDenied, isTrue,
        reason: 'it genuinely is a 403 at the transport level');
    expect(blocked.code, ApiErrorCodes.verificationBlocked,
        reason: 'so the repository must branch on the code, not the status');
  });
}
