import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/utils/verion.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_event.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_state.dart';
import 'package:isi_steel_sales_mobile/core/theme/auth_vibe.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/aurora_background.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/widgets/login/gradient_button.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/widgets/login/status_pill.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/widgets/login/vibe_field.dart';
import 'package:isi_steel_sales_mobile/routes/app_routes.dart';

/// Gen-Z sign-in for KIC. Mobile-first single column: aurora canvas +
/// frosted card. Business logic is unchanged — same AuthBloc contract.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onRequestAccess, this.onForgotPassword});

  /// Wire these from the navigation layer (kept out of the widget so it
  /// stays small and decoupled from concrete routes).
  final VoidCallback? onRequestAccess;
  final VoidCallback? onForgotPassword;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          LoginSubmittedEvent(
            email: _email.text.trim(),
            password: _password.text,
          ),
        );
  }

  AuthVibeStatus _statusFor(AuthState s) {
    if (s is AuthLoadingState) return AuthVibeStatus.verifying;
    if (s is AuthFailureState) return AuthVibeStatus.error;
    if (s is AuthenticatedState) return AuthVibeStatus.success;
    return AuthVibeStatus.idle;
  }

  @override
  Widget build(BuildContext context) {
    // Navigation lives here (not in a global listener) so it only fires for
    // *this* screen: on a successful sign-in we clear the stack down to a fresh
    // authenticated shell, whether the user arrived from onboarding or from a
    // "Login Required" prompt over the shell.
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => curr is AuthenticatedState,
      listener: (context, state) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(Static.main, (route) => false);
      },
      child: Scaffold(
        backgroundColor: Vibe.bg,
        body: Stack(
          children: [
            const Positioned.fill(child: AuroraBackground()),
          SafeArea(
            child: Column(
              children: [
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
                            // Centered Header Section (Logo, Title, Subtitle)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const _Brand(),
                                const SizedBox(height: 28),
                                Text(
                                  'auth.welcome_back'.tr,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Vibe.text,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'auth.sign_in_subtitle'.tr,
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
                // Versioning signature aligned perfectly at the bottom edge
                const VersionFooter(),
              ],
            ),
          ),
          ],
        ),
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
            controller: _email,
            label: 'auth.email'.tr,
            icon: Icons.alternate_email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'auth.email_required'.tr;
              }
              final ok =
                  RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
              return ok ? null : 'auth.invalid_email'.tr;
            },
          ),
          const SizedBox(height: 14),
          VibeField(
            controller: _password,
            label: 'auth.password'.tr,
            icon: Icons.lock_outline,
            obscure: _obscure,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _submit(),
            suffix: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Vibe.muted,
                size: 20,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) => (v == null || v.length < 6)
                ? 'auth.password_too_short'.tr
                : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.onForgotPassword,
              child: Text('auth.forgot_password'.tr,
                  style:
                      TextStyle(color: Vibe.mint, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 6),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final status = _statusFor(state);
              return Column(
                children: [
                  StatusPill(
                    status: status,
                    message: state is AuthFailureState ? state.message : null,
                  ),
                  GradientButton(
                    label: "auth.lets_go".tr,
                    loading: status == AuthVibeStatus.verifying,
                    onPressed: _submit,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Compact brand mark — replaces the old wide identity panel.
/// Centered large image logo brand identity.
class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        "assets/logos/isi_app_logo.png", // Replace with your actual image path
        width: 180, // Adjust width size as needed (e.g., 150-240)
        fit: BoxFit.contain,
      ),
    );
  }
}
