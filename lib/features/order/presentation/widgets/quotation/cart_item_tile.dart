import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_text_context.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/cart_item.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/material_availability.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/stock_availability_badge.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/cart_quantity_stepper.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

/// One quotation line, in three rows: what it is, what it costs, what it
/// totals.
///
/// Deliberately dense. A rep building a real quotation adds a dozen lines and
/// then scrolls back to check them, so vertical space per line is the whole
/// ergonomic budget — the old tile spent 56dp of it on a catalog stock photo
/// that told them nothing a steel SKU's code and specs didn't already say, and
/// cost a network fetch per row while doing it. Now ~78dp of pure information.
///
/// A *customization drawing* is the one image that survives, because it is the
/// rep's own sketch and the one thing on the line that text genuinely cannot
/// convey. It is also rare, so it costs nothing on the common path.
class CartItemTile extends StatelessWidget {
  const CartItemTile({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
    this.stock,
  });

  final CartItem item;
  final ValueChanged<double> onQuantityChanged;
  final VoidCallback onRemove;

  /// SAP's verdict for this line's material.
  ///
  /// Replaces the old `_StockDot(available: item.product.isAvailable)`, which
  /// was reading the wrong thing from the wrong place. `Product.isAvailable` is
  /// a flag off the synced catalog row — it says what the last sync thought,
  /// not what the ERP will accept now — and being a bool it collapsed four
  /// states into two, so "never asked" and "SAP refused" rendered identically
  /// as "out of stock" on a line the rep had already committed to.
  ///
  /// Null renders nothing, which on a cart line means the check has not come
  /// back yet rather than that there is a problem.
  final MaterialAvailability? stock;

  /// Measurements + finish, joined for the review line (null for plain lines).
  String? get _customSpecs {
    if (!item.isCustomized) return null;
    final parts = <String>[];
    final m = item.measurements;
    if (m != null && !m.isEmpty) parts.add(m.toSummaryString());
    if (item.appearance != null && item.appearance!.trim().isNotEmpty) {
      parts.add(item.appearance!.trim());
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// Material code first — it is what a rep reads back to the counter — then
  /// whatever distinguishes this line from its siblings.
  String get _identityLine {
    final parts = <String>[
      if (item.product.materialCode.trim().isNotEmpty)
        item.product.materialCode,
      ...?_customSpecs?.split(' · '),
      if (_customSpecs == null && item.product.size.trim().isNotEmpty)
        item.product.size,
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final discounted = item.discountPercent > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.isCustomized) ...[
                  Icon(Icons.tune_rounded,
                      size: context.rr(13), color: colors.accentPurple),
                  SizedBox(width: context.rw(4)),
                ],
                Expanded(
                  child: Text(
                    context.localized(item.product.displayName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: context.rsp(13),
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),
                // Compact hit target rather than a full IconButton: the default
                // 48dp box alone would blow the row-height budget.
                InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: EdgeInsets.all(context.rr(6)),
                    child: Icon(Icons.close_rounded,
                        size: context.rr(16), color: colors.iconMuted),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.rh(3)),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _identityLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: colors.textSecondary, fontSize: context.rsp(11)),
                  ),
                ),
                SizedBox(width: context.rw(6)),
                // The badge keeps the dot-plus-word shape the old `_StockDot`
                // had, for the same reason: colour alone leaves the state
                // unreadable to a colour-blind rep, and on a quotation line
                // that is the difference between promising stock and promising
                // a lead time. What changed is where the answer comes from.
                if (stock != null)
                  StockAvailabilityBadge(availability: stock),
                SizedBox(width: context.rw(8)),
              ],
            ),
            SizedBox(height: context.rh(8)),
            Row(
              children: [
                CartQuantityStepper(
                  quantity: item.quantity.round(),
                  onChanged: (value) => onQuantityChanged(value.toDouble()),
                  // Gates `+` on the status alone. A line already in the
                  // quotation can always be reduced or removed, including when
                  // SAP has since refused it — which is the case where a rep
                  // most needs to take it back out.
                  stock: stock,
                ),
                SizedBox(width: context.rw(10)),
                Expanded(
                  child: Text(
                    '\$${item.unitPrice.toStringAsFixed(2)}/${item.unit}'
                    '${discounted ? '  −${item.discountPercent.toStringAsFixed(0)}%' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: discounted ? scheme.primary : colors.textSecondary,
                      fontSize: context.rsp(11),
                      fontWeight: discounted ? FontWeight.w700 : null,
                    ),
                  ),
                ),
                // The total is what the rep re-reads on every scroll-back, so
                // it animates rather than snapping — a silently changed number
                // is one nobody trusts.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: Text(
                    '\$${item.lineTotal.toStringAsFixed(2)}',
                    key: ValueKey(item.lineTotal.toStringAsFixed(2)),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: context.rsp(14),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(width: context.rw(10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}