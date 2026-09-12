import 'package:equatable/equatable.dart';

/// A sign-in attempt awaiting its one-time code.
///
/// Returned by `POST /mobile/auth/send-otp`, which is **the only call that sees
/// the password**. Everything afterwards presents [verificationId], which is
/// opaque, single-use, and expires with the code.
class OtpChallenge extends Equatable {
  const OtpChallenge({
    required this.verificationId,
    required this.expiresIn,
    required this.otpLength,
    this.mockOtp,
  });

  /// Opaque handle for the attempt. Spent once `mobile/auth/login` succeeds —
  /// a second exchange with the same id returns 400, deliberately, so a
  /// captured id cannot mint a second token.
  final String verificationId;

  /// Seconds until the code expires. **Drives the countdown** — do not
  /// hard-code 300; it comes from server configuration and will change when a
  /// real SMS provider is wired up.
  final int expiresIn;

  /// How many boxes the code screen should render. **Do not hard-code 6**, for
  /// the same reason.
  final int otpLength;

  /// Temporary scaffolding: no SMS provider is connected yet, so the server
  /// runs a mock that accepts one fixed code and echoes it here.
  ///
  /// **It disappears the moment a real provider is enabled** — the field will
  /// be absent, not empty. Hence nullable, and hence nothing in the flow may
  /// depend on it. Never display it in a shipped build.
  final String? mockOtp;

  Duration get window => Duration(seconds: expiresIn);

  factory OtpChallenge.fromJson(Map<String, dynamic> json) => OtpChallenge(
        verificationId: json['verificationId'] as String,
        // Defaults exist only so a malformed payload cannot crash the screen;
        // the server always sends both.
        expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 300,
        otpLength: (json['otpLength'] as num?)?.toInt() ?? 6,
        // Read defensively — absent once a real gateway is enabled.
        mockOtp: json['mockOtp'] as String?,
      );

  @override
  List<Object?> get props => [verificationId, expiresIn, otpLength];

  /// Deliberately omits [verificationId] and [mockOtp] — this ends up in logs.
  @override
  String toString() =>
      'OtpChallenge(otpLength: $otpLength, expiresIn: $expiresIn)';
}
