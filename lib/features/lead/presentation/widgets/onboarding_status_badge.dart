import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/onboarding_status.dart';

class OnboardingStatusBadge extends StatelessWidget {
  const OnboardingStatusBadge({super.key, required this.status});
  final OnboardingStatus status;

  Color _color(ColorScheme scheme, AppThemeColors colors) => switch (status) {
        OnboardingStatus.notSubmitted => colors.textSecondary,
        OnboardingStatus.pendingApproval => colors.warning,
        OnboardingStatus.approved => colors.success,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color(Theme.of(context).colorScheme, context.appColors);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
