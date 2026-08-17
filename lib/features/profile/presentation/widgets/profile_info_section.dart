import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/glass_card.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/features/profile/domain/entities/worker_profile.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

class ProfileInfoSection extends StatelessWidget {
  const ProfileInfoSection({super.key, required this.profile, this.isTablet = false});

  final WorkerProfile profile;
  final bool isTablet;

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
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return GlassCard(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 8 : 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('profile.details'.tr,
                style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: context.rsp(14.5),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1)),
            SizedBox(height: context.rh(12)),
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
            // Only when the server actually supplied a date. `/auth/me` does
            // not return one today, and an empty or invented "Joined" row on
            // an employee record reads as a data error.
            if (profile.joinedAt case final joinedAt?)
              _InfoTile(
                  icon: Icons.event_rounded,
                  label: 'profile.joined'.tr,
                  value: _formatDate(context, joinedAt)),
            _InfoTile(
              icon: profile.isActive
                  ? Icons.check_circle_rounded
                  : Icons.pause_circle_rounded,
              label: 'profile.status'.tr,
              value: profile.isActive
                  ? 'profile.active'.tr
                  : 'profile.inactive'.tr,
              valueColor:
                  profile.isActive ? colors.success : colors.textSecondary,
              iconColor: profile.isActive ? colors.success : null,
              showDivider: false,
            ),
          ],
        ),
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
    this.iconColor,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Color? iconColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final accent = iconColor ?? scheme.primary;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: context.rh(10)),
          child: Row(
            children: [
              Container(
                width: context.rr(32),
                height: context.rr(32),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: context.rr(16), color: accent),
              ),
              SizedBox(width: context.rw(12)),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: context.rsp(13))),
              ),
              Text(value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: valueColor ?? scheme.onSurface,
                      fontSize: context.rsp(13),
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: colors.border.withValues(alpha: 0.6)),
      ],
    );
  }
}