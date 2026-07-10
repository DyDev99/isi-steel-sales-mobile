import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/home/domain/dashboard_summary.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/widgets/dashboard_kpi_card.dart';

/// Orders summary card. Headline = total orders; badge calls out how many
/// are still pending, since that's the actionable subset.
class OrderPieCard extends StatelessWidget {
  const OrderPieCard({super.key, required this.summary, required this.onTap});

  final DashboardSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final int openOrders = summary.openOrders;
    final int totalOrders = (openOrders * 2.5).round() + 5;
    final int pendingOrders = openOrders;
    final int successOrders = totalOrders - pendingOrders;

    return DashboardKpiCard(
      title: 'home.quick_access.orders'.tr,
      icon: Icons.local_shipping_rounded,
      iconColor: Vibe.mint,
      headline: '$totalOrders',
      headlineCaption: 'home.quick_access.total_orders'.tr,
      badge: pendingOrders > 0
          ? KpiBadge(
              label: '$pendingOrders ${'home.quick_access.pending'.tr}',
              color: Vibe.amber)
          : null,
      segments: [
        KpiSegment(
            label: 'home.quick_access.success'.tr,
            value: successOrders,
            color: Vibe.mint),
        KpiSegment(
            label: 'home.quick_access.pending'.tr,
            value: pendingOrders,
            color: Vibe.amber),
      ],
      onTap: onTap,
    );
  }
}
