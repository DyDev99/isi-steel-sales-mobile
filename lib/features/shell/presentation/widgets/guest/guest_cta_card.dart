import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

/// The dominant call-to-action: "Unlock the full experience", with primary
/// Login and secondary Create-account buttons.
///
/// Visually the heaviest block on the guest screen by design — a full-bleed
/// gradient (the brand blue→purple, from theme tokens) so it out-weighs the
/// neutral cards above it and reads as the intended next step.
///
/// Both buttons call [onAuthenticate]; the app has a single sign-in / register
/// entry point (`AuthGuard` → auth flow), so "Login" and "Create account" lead
/// to the same surface rather than two divergent flows this screen would have
/// to keep in sync.
class GuestCtaCard extends StatelessWidget {
  const GuestCtaCard({super.key, required this.onAuthenticate});

  final VoidCallback onAuthenticate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final onGrad = scheme.onPrimary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, colors.accentPurple],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.accentPurple.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unlock the full experience',
            style: TextStyle(
              color: onGrad,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to access personalized tools, dashboards, '
            'and exclusive features.',
            style: TextStyle(
              color: onGrad.withValues(alpha: 0.9),
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          // Primary: a solid, high-contrast surface button on the gradient.
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: onAuthenticate,
              style: FilledButton.styleFrom(
                backgroundColor: onGrad,
                foregroundColor: scheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text('Login',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
