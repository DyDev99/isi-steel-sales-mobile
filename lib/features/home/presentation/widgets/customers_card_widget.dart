import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/widgets/dashboard_kpi_card.dart';

/// Customers summary card. Headline = total customers; the distribution
/// bar/legend breaks that down into active / prospect / suspended.
class CustomerCardWidget extends StatelessWidget {
  const CustomerCardWidget({
    super.key,
    required this.totalCustomers,
    required this.activeCount,
    required this.prospectCount,
    required this.suspendedCount,
    this.title,
    this.onTap,
  });

  final int totalCustomers;
  final int activeCount;
  final int prospectCount;
  final int suspendedCount;
  final String? title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DashboardKpiCard(
      title: title ?? 'home.quick_access.customers'.tr,
      icon: Icons.groups_rounded,
      iconColor: Vibe.success,
      headline: '$totalCustomers',
      headlineCaption: 'home.quick_access.total_customers'.tr,
      badge: suspendedCount > 0
          ? KpiBadge(
              label: '$suspendedCount ${'home.quick_access.suspended'.tr}',
              color: Vibe.amber)
          : null,
      segments: [
        KpiSegment(
            label: 'home.quick_access.active'.tr,
            value: activeCount,
            color: Vibe.success),
        KpiSegment(
            label: 'home.quick_access.prospect'.tr,
            value: prospectCount,
            color: Vibe.violet),
        KpiSegment(
            label: 'home.quick_access.suspended'.tr,
            value: suspendedCount,
            color: Vibe.amber),
      ],
      onTap: onTap,
    );
  }
}
