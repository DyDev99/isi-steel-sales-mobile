import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_state.dart';

/// Which journey the code screen is part of.
///
/// `VerifyScreen` is shared by two flows that look identical to the user and
/// are completely different underneath, so the origin is passed explicitly
/// rather than inferred from the navigation stack — a screen that guesses
/// where it came from breaks the first time someone deep-links to it.
enum OtpFlow {
  /// Sign-in. The code is verified server-side (`/mobile/auth/verify-otp`),
  /// then exchanged for a token pair, and the user lands in the app.
  login,

  /// Password reset. The code **is** the reset token, and it cannot be checked
  /// on its own: `/auth/reset-password` takes `{email, token, newPassword}`
  /// together, so the code is carried forward to the new-password screen and
  /// validated there.
  passwordReset,
}

/// Route argument for `Static.verifyOtp`.
class VerifyOtpArgs {
  const VerifyOtpArgs._({
    required this.flow,
    required this.target,
    this.challenge,
  });

  /// Sign-in: carries the live challenge, because the screen's box count and
  /// countdown come from `otpLength` / `expiresIn` rather than constants.
  factory VerifyOtpArgs.login(AuthOtpRequiredState state) => VerifyOtpArgs._(
        flow: OtpFlow.login,
        target: state.destination ?? '',
        challenge: state,
      );

  /// Password reset: only the address or number the code went to. There is no
  /// challenge object — the reset flow has no `send-otp` step.
  factory VerifyOtpArgs.passwordReset({required String target}) =>
      VerifyOtpArgs._(flow: OtpFlow.passwordReset, target: target);

  final OtpFlow flow;

  /// Where the code was sent, for the "we sent a code to …" line.
  final String target;

  /// Present for [OtpFlow.login] only.
  final AuthOtpRequiredState? challenge;

  bool get isLogin => flow == OtpFlow.login;
}
