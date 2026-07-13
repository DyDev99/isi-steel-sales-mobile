import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/auth_vibe.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/aurora_background.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/widgets/login/gradient_button.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/widgets/login/status_pill.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/widgets/login/vibe_field.dart';

/// Outcome of a password-reset submission, returned by
/// [CreateNewPasswordScreen.onSubmit].
class ResetPasswordResult {
  const ResetPasswordResult.success([this.message]) : isSuccess = true;
  const ResetPasswordResult.failure(this.message) : isSuccess = false;

  final bool isSuccess;
  final String? message;
}

/// Step 3 of the forgot-password flow: the person picks a new password
/// after verifying their code on `VerifyScreen`.
///
/// Same design choice as the other steps — plain callback instead of
/// dispatching an AuthBloc event directly, since auth_event.dart /
/// auth_state.dart weren't available while building this. Wire it up from
/// the navigation layer, e.g.:
///
///   CreateNewPasswordScreen(
///     onSubmit: (newPassword) async {
///       context.read<AuthBloc>().add(
///         ResetPasswordRequestedEvent(target, code, newPassword),
///       );
///       // ...await the resulting state and map it to a ResetPasswordResult
///     },
///     onSuccess: () => Navigator.of(context).pushReplacementNamed(
///       Static.resetPasswordSuccess,
///     ),
///   )
class CreateNewPasswordScreen extends StatefulWidget {
  const CreateNewPasswordScreen({
    super.key,
    required this.onSubmit,
    this.onSuccess,
    this.onBack,
  });

  /// Called with the new password once both fields validate and match.
  /// Return a [ResetPasswordResult] describing whether it succeeded.
  final Future<ResetPasswordResult> Function(String newPassword) onSubmit;

  /// Called right after a successful reset — use this to navigate to the
  /// success screen (or straight back to login).
  final VoidCallback? onSuccess;

  final VoidCallback? onBack;

  @override
  State<CreateNewPasswordScreen> createState() =>
      _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  AuthVibeStatus _status = AuthVibeStatus.idle;
  String? _errorMessage;

  @override
  void dispose() {
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _status = AuthVibeStatus.verifying;
      _errorMessage = null;
    });

    final result = await widget.onSubmit(_newPassword.text);

    if (!mounted) return;
    if (result.isSuccess) {
      setState(() => _status = AuthVibeStatus.success);
      widget.onSuccess?.call();
    } else {
      setState(() {
        _status = AuthVibeStatus.error;
        _errorMessage = result.message ?? 'auth.something_went_wrong'.tr;
      });
    }
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
                  onPressed:
                      widget.onBack ?? () => Navigator.of(context).maybePop(),
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
                                  Icons.password_outlined,
                                  size: 40,
                                  color: Vibe.pink,
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'auth.create_new_password_title'.tr,
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
                                  'auth.create_new_password_subtitle'.tr,
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VibeField(
            controller: _newPassword,
            label: 'auth.new_password'.tr,
            icon: Icons.lock_outline,
            obscure: _obscureNew,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            required: true,
            suffix: IconButton(
              icon: Icon(
                _obscureNew
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Vibe.muted,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
            validator: (v) => (v == null || v.length < 6)
                ? 'auth.password_too_short'.tr
                : null,
          ),
          const SizedBox(height: 14),
          VibeField(
            controller: _confirmPassword,
            label: 'auth.confirm_new_password'.tr,
            icon: Icons.lock_outline,
            obscure: _obscureConfirm,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            required: true,
            onSubmitted: (_) => _submit(),
            suffix: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Vibe.muted,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) {
              if (v == null || v.length < 6) {
                return 'auth.password_too_short'.tr;
              }
              return v == _newPassword.text
                  ? null
                  : 'auth.passwords_dont_match'.tr;
            },
          ),
          const SizedBox(height: 20),
          StatusPill(status: _status, message: _errorMessage),
          GradientButton(
            label: 'auth.reset_password_button'.tr,
            loading: _status == AuthVibeStatus.verifying,
            onPressed: _submit,
          ),
        ],
      ),
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
