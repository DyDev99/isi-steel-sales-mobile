import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/widgets/dashboard_kpi_card.dart';

/// Routes summary card. Headline = total routes; badge calls out missed
/// routes specifically, since that's the one that needs attention today.
class RoutesCardWidget extends StatelessWidget {
  const RoutesCardWidget({
    super.key,
    required this.totalRoutes,
    required this.todayRoutesCount,
    required this.missedRoutesCount,
    this.title,
    this.onTap,
  });

  final int totalRoutes;
  final int todayRoutesCount;
  final int missedRoutesCount;
  final String? title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final int remaining = (totalRoutes - todayRoutesCount - missedRoutesCount)
        .clamp(0, totalRoutes);
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return DashboardKpiCard(
      title: title ?? 'home.quick_access.routes'.tr,
      icon: Icons.alt_route_rounded,
      iconColor: colors.warning,
      headline: '$totalRoutes',
      headlineCaption: 'home.quick_access.total_routes'.tr,
      badge: missedRoutesCount > 0
          ? KpiBadge(
              label: '$missedRoutesCount ${'home.quick_access.missed'.tr}',
              color: scheme.error)
          : null,
      segments: [
        KpiSegment(
            label: 'home.quick_access.today_active'.tr,
            value: todayRoutesCount,
            color: colors.warning),
        KpiSegment(
            label: 'home.quick_access.missed'.tr,
            value: missedRoutesCount,
            color: scheme.error),
        KpiSegment(
            label: 'home.quick_access.remaining'.tr,
            value: remaining,
            color: colors.border),
      ],
      onTap: onTap,
    );
  }
}
