import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_text_context.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/sales_order.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/sales_order/sales_order_status_chip.dart';

/// One row in the sales-order list: who it is for, when, how much, and whether
/// it is committed.
///
/// Deliberately does *not* show line detail — a rep scanning for one order
/// needs the four facts that identify it, and the detail screen is one tap
/// away.
class SalesOrderCard extends StatelessWidget {
  const SalesOrderCard({super.key, required this.order, required this.onTap});

  final SalesOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    // Locale-aware, via intl (FS-LOC-6) — never a hand-built date string.
    final language = context.languageCode;
    final date = DateFormat.yMMMd(language).add_jm().format(order.createdAt);
    final total = NumberFormat.currency(locale: language, symbol: r'$')
        .format(order.total);

    // Falls through customer → lead → an explicit "unnamed" key rather than
    // rendering a blank line: an order always belongs to *someone*, and a
    // silent gap looks like a rendering bug rather than missing data.
    final party = order.shopName?.trim().isNotEmpty == true
        ? order.shopName!
        : (order.leadDisplayName?.trim().isNotEmpty == true
            ? order.leadDisplayName!
            : 'orders.sales_order.unnamed_party'.tr);

    return Semantics(
      button: true,
      label: '${order.id}, $party, $total',
      child: Padding(
        padding: EdgeInsets.only(bottom: context.rh(10)),
        child: Material(
          color: colors.card,
          borderRadius: BorderRadius.circular(context.rr(16)),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(context.rr(16)),
            child: Container(
              padding: EdgeInsets.all(context.rr(14)),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.rr(16)),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          order.id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: context.rsp(14.5),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      SizedBox(width: context.rw(8)),
                      SalesOrderStatusChip(status: order.status, compact: true),
                    ],
                  ),
                  SizedBox(height: context.rh(6)),
                  Text(
                    party,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: context.rsp(12.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: context.rh(10)),
                  // Wraps instead of overflowing: at 200% font scale
                  // (FS-A11Y-2) the date and total cannot share one line.
                  Wrap(
                    spacing: context.rw(12),
                    runSpacing: context.rh(4),
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _Meta(
                          icon: Icons.event_rounded,
                          text: date),
                      _Meta(
                        icon: Icons.inventory_2_outlined,
                        text: 'orders.items_count'
                            .trParams({'count': order.lines.length}),
                      ),
                    ],
                  ),
                  SizedBox(height: context.rh(10)),
                  Divider(color: colors.divider, height: context.rh(1)),
                  SizedBox(height: context.rh(8)),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'orders.sales_order.order_total'.tr,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: context.rsp(12),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        total,
                        style: TextStyle(
                          color: colors.accentPurple,
                          fontSize: context.rsp(15),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // `Flexible` is load-bearing, not decoration: a `Wrap` hands its children
    // loose constraints and does not shrink them, so an unflexible label wider
    // than the row overflows rather than wrapping. At 200% text scale this
    // date ran 159px past the edge.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: context.rr(13), color: colors.iconMuted),
        SizedBox(width: context.rw(4)),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: colors.textSecondary, fontSize: context.rsp(11.5)),
          ),
        ),
      ],
    );
  }
}
