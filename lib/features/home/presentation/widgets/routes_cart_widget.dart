import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
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

    return DashboardKpiCard(
      title: title ?? 'home.quick_access.routes'.tr,
      icon: Icons.alt_route_rounded,
      iconColor: Vibe.amber,
      headline: '$totalRoutes',
      headlineCaption: 'home.quick_access.total_routes'.tr,
      badge: missedRoutesCount > 0
          ? KpiBadge(
              label: '$missedRoutesCount ${'home.quick_access.missed'.tr}',
              color: Vibe.danger)
          : null,
      segments: [
        KpiSegment(
            label: 'home.quick_access.today_active'.tr,
            value: todayRoutesCount,
            color: Vibe.amber),
        KpiSegment(
            label: 'home.quick_access.missed'.tr,
            value: missedRoutesCount,
            color: Vibe.danger),
        KpiSegment(
            label: 'home.quick_access.remaining'.tr,
            value: remaining,
            color: Vibe.stroke),
      ],
      onTap: onTap,
    );
  }
}
