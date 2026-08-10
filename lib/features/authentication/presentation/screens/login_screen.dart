import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/utils/version.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_event.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_state.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/widgets/forgot_password/identifier_field.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/widgets/login/gradient_button.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/widgets/login/status_pill.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/widgets/login/vibe_field.dart';
import 'package:isi_steel_sales_mobile/routes/app_routes.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/glass_card.dart';

/// "Trad-Z" Sign-in for ISI Steel Mobile.
/// Maintains a centered vertical column layout across phone and tablet viewports.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onRequestAccess, this.onForgotPassword});

  final VoidCallback? onRequestAccess;
  final VoidCallback? onForgotPassword;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierKey = GlobalKey<IdentifierFieldState>();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final formOk = _formKey.currentState?.validate() ?? false;
    final identifierOk = _identifierKey.currentState?.validate() ?? false;
    if (!formOk || !identifierOk) return;

    context.read<AuthBloc>().add(
          LoginSubmittedEvent(
            email: _identifierKey.currentState!.value,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dynamically scale maximum card width for larger screens without splitting into rows
    final maxCardWidth = context.responsive(
      compact: 420.0,
      medium: 520.0,
      expanded: 580.0,
    );

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => curr is AuthenticatedState,
      listener: (context, state) {
        if (!context.mounted) return;
        Navigator.of(context)
            .pushNamedAndRemoveUntil(Static.main, (route) => false);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Stack(
          children: [
            // -------------------------------------------------------------
            // 1. TRADITIONAL: Building Background Image
            // -------------------------------------------------------------
            Positioned.fill(
              child: Image.asset(
                'assets/images/isi_building.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),

            // -------------------------------------------------------------
            // 2. ADAPTIVE OVERLAY: Dark/Light Contrast Optimization
            // -------------------------------------------------------------
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            Colors.black.withValues(alpha: 0.55),
                            Colors.black.withValues(alpha: 0.85),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.30),
                            Colors.black.withValues(alpha: 0.70),
                          ],
                  ),
                ),
              ),
            ),

            // -------------------------------------------------------------
            // 3. GEN-Z UI LAYER: Centered Column Layout (Phone & Tablet)
            // -------------------------------------------------------------
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(context.pagePadding),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxCardWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _HeaderSection(),
                              SizedBox(height: context.rh(24)),
                              GlassCard(child: _form()),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
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
          IdentifierField(
            key: _identifierKey,
            required: true,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: context.rh(14)),
          VibeField(
            controller: _password,
            label: 'auth.password'.tr,
            icon: Icons.lock_outline,
            obscure: _obscure,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            required: true,
            onSubmitted: (_) => _submit(),
            suffix: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: context.appColors.textSecondary,
                size: context.rr(20),
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
              onPressed: () =>
                  Navigator.of(context).pushNamed(Static.forgotPassword),
              child: Text(
                'auth.forgot_password'.tr,
                style: TextStyle(
                  color: context.appColors.info,
                  fontSize: context.rsp(14),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: context.rh(6)),
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

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _Brand(),
        SizedBox(height: context.rh(24)),
        Text(
          'auth.welcome_back'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: context.rsp(32),
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            height: 1.1,
            shadows: const [
              Shadow(
                offset: Offset(0, 2),
                blurRadius: 8.0,
                color: Colors.black45,
              ),
            ],
          ),
        ),
        SizedBox(height: context.rh(8)),
        Text(
          'auth.sign_in_subtitle'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: context.rsp(15),
            fontWeight: FontWeight.w500,
            shadows: const [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 4.0,
                color: Colors.black38,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(context.rr(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.rw(20),
            vertical: context.rh(12),
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(context.rr(20)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.2,
            ),
          ),
          child: Image.asset(
            "assets/logos/isi_app_logo.png",
            width: context.rr(160),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}