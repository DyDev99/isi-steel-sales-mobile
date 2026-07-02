import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_event.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_state.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/theme/auth_vibe.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/widgets/aurora_background.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/widgets/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/widgets/gradient_button.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/widgets/status_pill.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/widgets/vibe_field.dart';

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
    return Scaffold(
      backgroundColor: Vibe.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Brand(),
                      const SizedBox(height: 28),
                      const Text(
                        'Welcome back 👋',
                        style: TextStyle(
                          color: Vibe.text,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in to your KIC workspace.',
                        style: TextStyle(color: Vibe.muted, fontSize: 15),
                      ),
                      const SizedBox(height: 24),
                      GlassCard(child: _form()),
                      const SizedBox(height: 20),
                      _footer(),
                    ],
                  ),
                ),
              ),
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
            controller: _email,
            label: 'Corporate email',
            icon: Icons.alternate_email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter your email';
              final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
              return ok ? null : 'That email looks off';
            },
          ),
          const SizedBox(height: 14),
          VibeField(
            controller: _password,
            label: 'Password',
            icon: Icons.lock_outline,
            obscure: _obscure,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _submit(),
            suffix: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Vibe.muted,
                size: 20,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) =>
                (v == null || v.length < 6) ? 'At least 6 characters' : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.onForgotPassword,
              child: const Text('Forgot password?',
                  style: TextStyle(color: Vibe.mint, fontWeight: FontWeight.w600)),
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
                    label: "Let's go  →",
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

  Widget _footer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('New here?', style: TextStyle(color: Vibe.muted)),
        TextButton(
          onPressed: widget.onRequestAccess,
          child: const Text('Request access',
              style: TextStyle(color: Vibe.pink, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

/// Compact brand mark — replaces the old wide identity panel.
class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: Vibe.cta,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text('K',
              style: TextStyle(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(width: 12),
        const Text('KIC GROUP',
            style: TextStyle(
                color: Vibe.muted,
                fontSize: 13,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}
