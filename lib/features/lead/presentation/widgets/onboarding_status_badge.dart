import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/onboarding_status.dart';

class OnboardingStatusBadge extends StatelessWidget {
  const OnboardingStatusBadge({super.key, required this.status});
  final OnboardingStatus status;

  Color get _color => switch (status) {
        OnboardingStatus.notSubmitted => Vibe.muted,
        OnboardingStatus.pendingApproval => Vibe.amber,
        OnboardingStatus.approved => Vibe.success,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label,
        style:
            TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
