import 'dart:async';

import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/auth_vibe.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/aurora_background.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/widgets/login/gradient_button.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/widgets/verify/otp_field.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/widgets/login/status_pill.dart';
import 'package:isi_steel_sales_mobile/routes/app_routes.dart';

/// Outcome of a code-verification attempt, returned by
/// [VerifyScreen.onVerify].
class VerifyResult {
  const VerifyResult.success([this.message]) : isSuccess = true;
  const VerifyResult.failure(this.message) : isSuccess = false;

  final bool isSuccess;
  final String? message;
}

/// Step 2 of the forgot-password flow (or any OTP step): the person enters
/// the code that was sent to [target] (an email or phone from
/// `ForgotPasswordScreen`).
///
/// Same design choice as `ForgotPasswordScreen`: this takes plain callbacks
/// instead of dispatching AuthBloc events directly, since this repo's
/// auth_event.dart / auth_state.dart weren't available while building it.
///
/// Out of the box (no `onVerified` passed), a successful check pushes
/// straight to `CreateNewPasswordScreen` with stubbed callbacks — enough to
/// see the whole flow working end to end. Once AuthBloc events exist,
/// override `onVerified` instead to dispatch them yourself, e.g.:
///
///   VerifyScreen(
///     target: identifier,
///     onVerify: (code) async {
///       context.read<AuthBloc>().add(VerifyOtpRequestedEvent(identifier, code));
///       // ...await the resulting state and map it to a VerifyResult
///     },
///     onVerified: (code) => Navigator.of(context).pushReplacement(
///       MaterialPageRoute(
///         builder: (_) => CreateNewPasswordScreen(
///           onSubmit: (newPassword) async {
///             context.read<AuthBloc>().add(
///               ResetPasswordRequestedEvent(identifier, code, newPassword),
///             );
///             // ...await the resulting state and map it to a ResetPasswordResult
///           },
///         ),
///       ),
///     ),
///     onResend: () async {
///       context.read<AuthBloc>().add(ForgotPasswordRequestedEvent(identifier));
///     },
///   )
class VerifyScreen extends StatefulWidget {
  const VerifyScreen({
    super.key,
    required this.target,
    required this.onVerify,
    this.onVerified,
    this.onResend,
    this.onBackToLogin,
    this.codeLength = 6,
    this.resendCooldown = const Duration(seconds: 30),
  });

  /// The email or phone the code was sent to — shown in the subtitle.
  final String target;

  /// Called with the entered code. Return a [VerifyResult] describing
  /// whether it was accepted.
  final Future<VerifyResult> Function(String code) onVerify;

  /// Called right after a successful verification. If provided, this is
  /// responsible for navigating to whatever comes next (e.g. dispatching
  /// an AuthBloc event, then pushing a route yourself). If omitted, this
  /// screen falls back to pushing the `Static.createNewPassword` route
  /// with `target`/`code` as arguments — see [_navigateToCreateNewPassword].
  final ValueChanged<String>? onVerified;

  /// Called when the person taps "Resend code". Omit to hide the resend
  /// action entirely.
  final Future<void> Function()? onResend;

  final VoidCallback? onBackToLogin;

  final int codeLength;

  /// How long the resend button stays disabled after each send.
  final Duration resendCooldown;

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _otpKey = GlobalKey<OtpFieldState>();

  AuthVibeStatus _status = AuthVibeStatus.idle;
  String? _errorMessage;
  Timer? _cooldownTimer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _secondsLeft = widget.resendCooldown.inSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  Future<void> _submit([String? autoCode]) async {
    final codeOk = _otpKey.currentState?.validate() ?? false;
    if (!codeOk) return;

    final code = autoCode ?? _otpKey.currentState!.value;

    setState(() {
      _status = AuthVibeStatus.verifying;
      _errorMessage = null;
    });

    final result = await widget.onVerify(code);

    if (!mounted) return;
    if (result.isSuccess) {
      setState(() => _status = AuthVibeStatus.success);
      if (widget.onVerified != null) {
        widget.onVerified!(code);
      } else {
        _navigateToCreateNewPassword(code);
      }
    } else {
      setState(() {
        _status = AuthVibeStatus.error;
        _errorMessage = result.message ?? 'auth.invalid_code'.tr;
      });
      _otpKey.currentState?.clear();
    }
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0 || widget.onResend == null) return;
    setState(() {
      _status = AuthVibeStatus.idle;
      _errorMessage = null;
    });
    _otpKey.currentState?.clear();
    await widget.onResend!();
    if (!mounted) return;
    _startCooldown();
  }

  /// Default fallback used when [VerifyScreen.onVerified] isn't provided —
  /// pushes straight to the create-new-password step so the flow works
  /// out of the box.
  ///
  /// Navigates via the named [Static.createNewPassword] route (rather than
  /// building the screen inline) so app_page.dart owns the `onSubmit` /
  /// `onSuccess` callbacks with a live route context. Building it inline
  /// here and capturing this screen's `context` in `onSuccess` would break
  /// once this route is replaced, since that context is no longer mounted.
  void _navigateToCreateNewPassword(String code) {
    Navigator.of(context).pushReplacementNamed(
      Static.createNewPassword,
      arguments: {'target': widget.target, 'code': code},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vibe.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          SafeArea(
            child: Column(
              children: [
                _BackButton(
                  onPressed: widget.onBackToLogin ??
                      () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.mark_email_unread_outlined,
                                  size: 40,
                                  color: Vibe.pink,
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'auth.verify_code_title'.tr,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Vibe.text,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'auth.verify_code_subtitle'
                                      .trParams({'target': widget.target}),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Vibe.muted, fontSize: 15),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            GlassCard(child: _form()),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OtpField(
          key: _otpKey,
          length: widget.codeLength,
          onCompleted: _submit,
        ),
        const SizedBox(height: 14),
        StatusPill(status: _status, message: _errorMessage),
        GradientButton(
          label: 'auth.verify'.tr,
          loading: _status == AuthVibeStatus.verifying,
          onPressed: () => _submit(),
        ),
        const SizedBox(height: 10),
      Center(
          child: TextButton(
            onPressed: (_secondsLeft > 0 || widget.onResend == null)
                ? null
                : _resend,
            child: Text(
              _secondsLeft > 0
                  ? 'auth.resend_code_in'.trParams({
                      'seconds': _secondsLeft.toString().padLeft(2, '0'),
                    })
                  : 'auth.resend_code'.tr,
              style: TextStyle(
                color: _secondsLeft > 0 ? Vibe.muted : Vibe.mint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          onPressed: onPressed,
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: Vibe.text,
        ),
      ),
    );
  }
}