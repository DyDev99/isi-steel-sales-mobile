import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/widgets/metric_card.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_dashboard_summary.dart';

/// Reuses the Home feature's `MetricCard` — no new card component needed.
class DashboardSummaryCards extends StatelessWidget {
  const DashboardSummaryCards({super.key, required this.summary});
  final RouteDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'my_visits.flow.stops_today'.tr,
                value: '${summary.completed}/${summary.stopsToday}',
                icon: Icons.flag_rounded,
                accent: Vibe.violet,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: MetricCard(
                label: 'my_visits.flow.missed'.tr,
                value: '${summary.missed}',
                icon: Icons.report_gmailerrorred_rounded,
                accent: Vibe.danger,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'my_visits.flow.collections'.tr,
                value: '\$${summary.totalCollections.toStringAsFixed(0)}',
                icon: Icons.payments_rounded,
                accent: Vibe.success,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: MetricCard(
                label: 'my_visits.flow.orders_value'.tr,
                value: '\$${summary.totalSalesValue.toStringAsFixed(0)}',
                icon: Icons.receipt_long_rounded,
                accent: Vibe.mint,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
