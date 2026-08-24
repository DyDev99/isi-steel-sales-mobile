import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/animations/app_animations.dart';
import 'package:isi_steel_sales_mobile/core/device/device_insets.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/utils/version.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_event.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_state.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/widgets/login/gradient_button.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/widgets/login/phone_number_field.dart';
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
  final _phoneKey = GlobalKey<PhoneNumberFieldState>();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final formOk = _formKey.currentState?.validate() ?? false;
    final phoneOk = _phoneKey.currentState?.validate() ?? false;
    if (!formOk || !phoneOk) return;

    // Single request. Sign-in is phone + password and nothing else: on
    // success `/auth/login` returns the token pair directly and the listener
    // below lands the rep on the shell.
    //
    // The one-time code is **not** part of signing in any more. It now guards
    // password *reset* only — the flow where a code in hand is the sole proof
    // of identity, because the password by definition cannot be. Requiring it
    // here as well charged every rep a second step, dozens of times a day, for
    // a factor that added nothing the password had not already established.
    context.read<AuthBloc>().add(
          LoginSubmittedEvent(
            identifier: _phoneKey.currentState!.value,
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

    // Read through the shared extension rather than MediaQuery directly. It
    // uses `viewInsetsOf`, so this screen rebuilds as the keyboard animates
    // but not when unrelated metrics change — core/device/device_insets.dart.
    final insets = context.deviceInsets;
    final keyboard = insets.keyboard;
    final keyboardOpen = insets.isKeyboardOpen;

    // Dynamically scale maximum card width for larger screens without splitting into rows
    final maxCardWidth = context.responsive(
      compact: 420.0,
      medium: 520.0,
      expanded: 580.0,
    );

    return BlocListener<AuthBloc, AuthState>(
      // Only one outcome to listen for now. `AuthOtpRequiredState` can no
      // longer arise from this screen — sign-in is a single request — so the
      // branch that pushed the code screen is gone rather than left as an
      // unreachable path for someone to wonder about later. That state still
      // exists and is still handled by the forgot-password flow, which is the
      // only journey that issues a code.
      listenWhen: (prev, curr) => curr is AuthenticatedState,
      listener: (context, state) {
        if (!context.mounted) return;
        // Straight to the shell, clearing the stack: there is nothing behind a
        // completed sign-in worth backing into.
        Navigator.of(context)
            .pushNamedAndRemoveUntil(Static.main, (route) => false);
      },
      child: Scaffold(
        // Deliberately false, and the content layer below compensates. Letting
        // the Scaffold resize would shrink the whole body — including the
        // full-bleed building photo and its gradient — so the backdrop would
        // visibly squash every time the keyboard opened.
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: GestureDetector(
          // Tap any gap to put the keyboard away. `translucent` so the fields,
          // the reveal toggle, the forgot-password link and the submit button
          // all still win their own taps; this only catches what they don't.
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
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
              // This padding is the whole keyboard fix. Because the Scaffold
              // does not resize, the scrollable's viewport would otherwise still
              // extend to the bottom of the screen — behind the keyboard. The
              // form would sit centred underneath it, and Flutter's built-in
              // "scroll the focused field into view" would do nothing, because
              // as far as it could tell the field was already inside the
              // viewport. Ending the viewport above the keyboard fixes both: the
              // form re-centres in the space that is actually visible, and
              // focusing a field now scrolls it into view on its own.
              //
              // `SafeArea` first, then this: `MediaQuery.padding` already drops
              // to 0 while the keyboard covers the gesture bar, so the two never
              // double-count.
              //
              // Plain `Padding`, not `AnimatedPadding` — the platform reports
              // `viewInsets` frame by frame as the keyboard slides, so this
              // tracks its edge exactly. Animating an already-animated value
              // would trail behind it.
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(bottom: keyboard),
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(context.pagePadding),
                            // Dragging over the form dismisses the keyboard —
                            // the reliable one-handed escape for a rep holding
                            // the phone in a warehouse aisle.
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            child: ConstrainedBox(
                              constraints:
                                  BoxConstraints(maxWidth: maxCardWidth),
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
                      // The footer is the first thing to give up its space when
                      // the keyboard takes two thirds of a small screen. It
                      // carries no action, so collapsing it costs the user
                      // nothing and buys the form back a visible row.
                      AnimatedSize(
                        duration: AppDurations.fast,
                        curve: AppCurves.standard,
                        child: keyboardOpen
                            ? const SizedBox(width: double.infinity)
                            : const VersionFooter(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _form() {
    // One autofill context for the phone + password pair, so iOS Keychain and
    // Android Autofill can fill both from a single saved credential and offer
    // to save the pair afterwards. The fields already carry the right
    // `autofillHints`; without a group around them the platform treats each as
    // an unrelated one-off.
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Phone number, as before. The identifier travels to
            // `/mobile/auth/login` as `employeeId`, which the server resolves.
            //
            // NOTE: staging currently answers a phone identifier with
            // `invalid_grant` — it resolves employee IDs (`EMP000201`) and
            // e-mail addresses only. Sign-in by phone therefore depends on the
            // backend accepting phone as an identifier on that endpoint.
            PhoneNumberField(
              key: _phoneKey,
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
                    // Failures only. The pill used to report success too — a
                    // green "You're in" that appeared for a single frame
                    // before the listener navigated away, so it said nothing
                    // the shell appearing did not already say, and on a slow
                    // frame it flashed. What it *was* carrying that nothing
                    // else does is the failure message: without this a wrong
                    // password simply stops the spinner and leaves the rep
                    // guessing.
                    if (state is AuthFailureState) ...[
                      StatusPill(status: status, message: state.message),
                      SizedBox(height: context.rh(8)),
                    ],
                    GradientButton(
                      // `auth.login_btn` ("Sign In"), not `auth.lets_go`.
                      // "Let's Go" belongs to the reset-password success screen;
                      // on a sign-in form it reads like an onboarding CTA and
                      // does not say what the button does.
                      label: 'auth.login_btn'.tr,
                      loading: status == AuthVibeStatus.verifying,
                      onPressed: _submit,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
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
