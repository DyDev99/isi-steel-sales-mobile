import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/auth_vibe.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/aurora_background.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/widgets/login/gradient_button.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/widgets/forgot_password/identifier_field.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/widgets/login/status_pill.dart';

/// Outcome of a forgot-password request, returned by [ForgotPasswordScreen.onSubmit].
class ForgotPasswordResult {
  const ForgotPasswordResult.success([this.message]) : isSuccess = true;
  const ForgotPasswordResult.failure(this.message) : isSuccess = false;

  final bool isSuccess;
  final String? message;
}

/// Step 1 of the forgot-password flow: the person enters the email or phone
/// tied to their account and requests a reset.
///
/// This screen is deliberately decoupled from AuthBloc — since this repo's
/// auth_event.dart / auth_state.dart weren't available while building this,
/// it takes a plain [onSubmit] callback instead of guessing at Bloc event
/// names. Wire it up from the navigation layer, e.g.:
///
///   ForgotPasswordScreen(
///     onSubmit: (identifier) async {
///       final result = await /* your reset-request call */;
///       if (result.isSuccess) {
///         Navigator.of(context).pushNamed(Static.verifyOtp, arguments: identifier);
///       }
///       return result;
///     },
///   )
///
/// If this screen should instead run through AuthBloc/BlocListener the same
/// way LoginScreen does, that's a straightforward follow-up once the event/
/// state classes exist — ping back and it can be wired the same way.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    required this.onSubmit,
    this.onBackToLogin,
  });

  /// Called with the submitted email or E.164-ish phone number. Return a
  /// [ForgotPasswordResult] describing whether the request succeeded.
  /// See the wiring example in the class doc comment above.
  final Future<ForgotPasswordResult> Function(String identifier) onSubmit;

  final VoidCallback? onBackToLogin;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierKey = GlobalKey<IdentifierFieldState>();

  AuthVibeStatus _status = AuthVibeStatus.idle;
  String? _errorMessage;
  String? _sentTo;

  Future<void> _submit() async {
    final formOk = _formKey.currentState?.validate() ?? false;
    final identifierOk = _identifierKey.currentState?.validate() ?? false;
    if (!formOk || !identifierOk) return;

    final identifier = _identifierKey.currentState!.value;

    setState(() {
      _status = AuthVibeStatus.verifying;
      _errorMessage = null;
    });

    final result = await widget.onSubmit(identifier);

    if (!mounted) return;
    setState(() {
      if (result.isSuccess) {
        _status = AuthVibeStatus.success;
        _sentTo = identifier;
      } else {
        _status = AuthVibeStatus.error;
        _errorMessage = result.message ?? 'auth.something_went_wrong'.tr;
      }
    });
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
                _BackButton(onPressed: () => Navigator.of(context).maybePop()),
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
                                Icon(
                                  _status == AuthVibeStatus.success
                                      ? Icons.mark_email_read_outlined
                                      : Icons.lock_reset_outlined,
                                  size: 40,
                                  color: Vibe.pink,
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  _status == AuthVibeStatus.success
                                      ? 'auth.check_your_inbox'.tr
                                      : 'auth.forgot_password_title'.tr,
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
                                  _status == AuthVibeStatus.success
                                      ? 'auth.reset_instructions_sent'
                                          .trParams({'target': _sentTo ?? ''})
                                      : 'auth.forgot_password_subtitle'.tr,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Vibe.muted, fontSize: 15),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            GlassCard(
                              child: _status == AuthVibeStatus.success
                                  ? _SuccessActions(
                                      onBackToLogin: widget.onBackToLogin,
                                      onResend: () => setState(
                                          () => _status = AuthVibeStatus.idle),
                                    )
                                  : _form(),
                            ),
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IdentifierField(
            key: _identifierKey,
            required: true,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 6),
          StatusPill(
            status: _status,
            message: _errorMessage,
          ),
          GradientButton(
            label: 'auth.send_reset_link'.tr,
            loading: _status == AuthVibeStatus.verifying,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

/// Shown inside the glass card once the reset request succeeds.
class _SuccessActions extends StatelessWidget {
  const _SuccessActions({this.onBackToLogin, this.onResend});

  final VoidCallback? onBackToLogin;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GradientButton(
          label: 'auth.back_to_login'.tr,
          onPressed: onBackToLogin,
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: onResend,
            child: Text(
              'auth.resend_or_try_different'.tr,
              style: TextStyle(color: Vibe.mint, fontWeight: FontWeight.w600),
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