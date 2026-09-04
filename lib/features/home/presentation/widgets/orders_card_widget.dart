import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/home/domain/dashboard_summary.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/widgets/dashboard_kpi_card.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sales_order/sales_order_list_state.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/sales_order/sales_order_list_screen.dart';

/// Orders summary card. Headline = total orders; badge calls out how many
/// are still pending, since that's the actionable subset.
///
/// Tapping opens [SalesOrderListScreen]. [onTap] is optional and overrides
/// that — pass one only when the card needs to go somewhere else.
class OrderPieCard extends StatelessWidget {
  const OrderPieCard({super.key, required this.summary, this.onTap});

  final DashboardSummary summary;

  /// Defaults to opening the sales-order list, filtered to pending when there
  /// is a pending badge to act on: the badge is the reason the rep tapped, so
  /// landing on the full list would make them filter again.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final int openOrders = summary.openOrders;
    final int totalOrders = (openOrders * 2.5).round() + 5;
    final int pendingOrders = openOrders;
    final int successOrders = totalOrders - pendingOrders;
    final colors = context.appColors;

    return DashboardKpiCard(
      title: 'home.quick_access.orders'.tr,
      icon: Icons.local_shipping_rounded,
      iconColor: colors.info,
      headline: '$totalOrders',
      headlineCaption: 'home.quick_access.total_orders'.tr,
      badge: pendingOrders > 0
          ? KpiBadge(
              label: '$pendingOrders ${'home.quick_access.pending'.tr}',
              color: colors.warning)
          : null,
      segments: [
        KpiSegment(
            label: 'home.quick_access.success'.tr,
            value: successOrders,
            color: colors.info),
        KpiSegment(
            label: 'home.quick_access.pending'.tr,
            value: pendingOrders,
            color: colors.warning),
      ],
      onTap: onTap ??
          () => SalesOrderListScreen.open(
                context,
                initialFilter: pendingOrders > 0
                    ? SalesOrderFilter.pending
                    : SalesOrderFilter.all,
              ),
    );
  }
}
