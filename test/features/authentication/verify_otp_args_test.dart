import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/otp_challenge.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_state.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/screens/verify_otp_args.dart';

/// `VerifyScreen` serves two journeys that look identical to the user:
/// sign-in, which ends in the app, and password reset, which ends at the
/// new-password screen. The origin is passed explicitly because a screen that
/// infers it from the navigation stack breaks the moment anything deep-links
/// to it.
void main() {
  const challenge = OtpChallenge(
    verificationId: '019ffa68-…',
    expiresIn: 120,
    otpLength: 4,
  );

  group('sign-in', () {
    final args = VerifyOtpArgs.login(
      const AuthOtpRequiredState(
        challenge: challenge,
        destination: '+85512345201',
      ),
    );

    test('is marked as the login journey', () {
      expect(args.isLogin, isTrue);
      expect(args.flow, OtpFlow.login);
    });

    test('carries the challenge, so the screen is server-sized', () {
      // Box count and countdown come from `otpLength` / `expiresIn`; both
      // change when a real SMS provider is wired up.
      expect(args.challenge?.challenge.otpLength, 4);
      expect(args.challenge?.challenge.window, const Duration(seconds: 120));
    });

    test('shows where the code went', () {
      expect(args.target, '+85512345201');
    });
  });

  group('password reset', () {
    final args = VerifyOtpArgs.passwordReset(target: 'rep@isigroup.com.kh');

    test('is not the login journey', () {
      // This is what stops the code screen dropping the user into the app
      // with no session — the reset flow never issues a token.
      expect(args.isLogin, isFalse);
      expect(args.flow, OtpFlow.passwordReset);
    });

    test('carries no challenge, because the reset flow has no send-otp step',
        () {
      // The code *is* the reset token: `/auth/reset-password` takes
      // `{email, token, newPassword}` together, so there is nothing to verify
      // on its own and no `verificationId` to hold.
      expect(args.challenge, isNull);
    });

    test('shows the address the link went to', () {
      expect(args.target, 'rep@isigroup.com.kh');
    });
  });
}
