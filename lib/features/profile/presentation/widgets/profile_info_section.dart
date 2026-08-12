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
                    fontSize: isTablet ? 16 : context.rsp(14.5),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1)),
            SizedBox(height: isTablet ? 16 : context.rh(12)),
            _InfoTile(
                icon: Icons.email_rounded,
                label: 'profile.email'.tr,
                value: profile.email,
                isTablet: isTablet),
            _InfoTile(
                icon: Icons.phone_rounded,
                label: 'profile.phone'.tr,
                value: profile.phone,
                isTablet: isTablet),
            _InfoTile(
                icon: Icons.map_rounded,
                label: 'profile.territory'.tr,
                value: profile.territory,
                isTablet: isTablet),
            _InfoTile(
                icon: Icons.public_rounded,
                label: 'profile.region'.tr,
                value: profile.region,
                isTablet: isTablet),
            _InfoTile(
                icon: Icons.event_rounded,
                label: 'profile.joined'.tr,
                value: _formatDate(context, profile.joinedAt),
                isTablet: isTablet),
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
              isTablet: isTablet,
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
    this.isTablet = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Color? iconColor;
  final bool showDivider;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final accent = iconColor ?? scheme.primary;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: isTablet ? 12 : 10),
          child: Row(
            children: [
              Container(
                width: isTablet ? 38 : 32,
                height: isTablet ? 38 : 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: isTablet ? 19 : context.rr(16), color: accent),
              ),
              SizedBox(width: isTablet ? 14 : context.rw(12)),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: isTablet ? 14 : context.rsp(13))),
              ),
              Text(value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: valueColor ?? scheme.onSurface,
                      fontSize: isTablet ? 14 : context.rsp(13),
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