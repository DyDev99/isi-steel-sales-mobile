import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/auth_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/aurora_background.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/widgets/login/gradient_button.dart';

/// A generic "all done" confirmation screen — same aurora/glass visual
/// language as the rest of the auth flow, but not tied to any one step, so
/// it can close out password reset, account creation, or anything else
/// that ends in a single checkmark + CTA.
///
/// For the password-reset flow specifically:
///
///   SuccessScreen(
///     title: 'auth.reset_password_success_title'.tr,
///     subtitle: 'auth.reset_password_success_subtitle'.tr,
///     buttonLabel: 'auth.back_to_login'.tr,
///     onContinue: () => Navigator.of(context)
///         .pushNamedAndRemoveUntil(Static.login, (route) => false),
///   )
class SuccessScreen extends StatelessWidget {
  const SuccessScreen({
    super.key,
    required this.title,
    this.subtitle,
    required this.buttonLabel,
    required this.onContinue,
    this.icon = Icons.check_circle_outline,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String? subtitle;
  final String buttonLabel;
  final VoidCallback onContinue;
  final IconData icon;

  /// Optional low-emphasis text action under the main button (e.g.
  /// "Contact support").
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

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
                          _SuccessBadge(icon: icon),
                          const SizedBox(height: 22),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Vibe.text,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              subtitle!,
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: Vibe.muted, fontSize: 15),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 28),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            GradientButton(
                              label: buttonLabel,
                              onPressed: onContinue,
                            ),
                            if (secondaryLabel != null) ...[
                              const SizedBox(height: 12),
                              Center(
                                child: TextButton(
                                  onPressed: onSecondary,
                                  child: Text(
                                    secondaryLabel!,
                                    style: TextStyle(
                                      color: Vibe.mint,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
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
}

/// Soft glowing ring behind the checkmark, matching the pink accent used
/// throughout the auth flow instead of a plain green success color.
class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Vibe.pink.withValues(alpha: 0.12),
        border: Border.all(color: Vibe.pink.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Icon(icon, size: 42, color: Vibe.pink),
    );
  }
}
