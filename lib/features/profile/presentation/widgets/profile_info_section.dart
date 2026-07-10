import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/features/profile/domain/entities/worker_profile.dart';

class ProfileInfoSection extends StatelessWidget {
  const ProfileInfoSection({super.key, required this.profile});
  final WorkerProfile profile;

  // Defensive date formatting method
  String _formatDate(BuildContext context, DateTime date) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    try {
      return DateFormat.yMMMd(currentLocale).format(date);
    } catch (_) {
      // Fallback to default system formatting if the locale isn't initialized yet
      return DateFormat.yMMMd().format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('profile.details'.tr,
              style: const TextStyle(
                  color: Vibe.text,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _InfoTile(
              icon: Icons.email_rounded,
              label: 'profile.email'.tr,
              value: profile.email),
          _InfoTile(
              icon: Icons.phone_rounded,
              label: 'profile.phone'.tr,
              value: profile.phone),
          _InfoTile(
              icon: Icons.map_rounded,
              label: 'profile.territory'.tr,
              value: profile.territory),
          _InfoTile(
              icon: Icons.public_rounded,
              label: 'profile.region'.tr,
              value: profile.region),
          // Use the safe format block here
          _InfoTile(
              icon: Icons.event_rounded,
              label: 'profile.joined'.tr,
              value: _formatDate(context, profile.joinedAt)),
          _InfoTile(
            icon: profile.isActive
                ? Icons.check_circle_rounded
                : Icons.pause_circle_rounded,
            label: 'profile.status'.tr,
            value:
                profile.isActive ? 'profile.active'.tr : 'profile.inactive'.tr,
            valueColor: profile.isActive ? Vibe.success : Vibe.muted,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Vibe.violet),
              const SizedBox(width: 12),
              Text(label,
                  style: const TextStyle(color: Vibe.muted, fontSize: 13)),
              const Spacer(),
              Text(value,
                  style: TextStyle(
                      color: valueColor ?? Vibe.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: Vibe.stroke),
      ],
    );
  }
}
