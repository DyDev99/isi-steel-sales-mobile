import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/material_availability.dart';

/// SAP's sellability verdict for one material, as a badge.
///
/// ## Why this is not a stock level
///
/// The materials API exposes **no on-hand quantity** — no units, no warehouse
/// balance, no ATP. What it exposes is whether the ERP will accept an order
/// line for a material in a sales area. So the badge reads "No stock" rather
/// than a figure, and there is deliberately no number to tap through to.
///
/// ## The four states, and why they are four
///
/// | [MaterialAvailability] | Badge | Meaning |
/// |---|---|---|
/// | absent | *nothing rendered* | never asked — the check costs a live SAP round trip and is spent on commitment |
/// | `checking` | spinner | asked, waiting |
/// | `available` | In stock | SAP will accept the line |
/// | `unavailable` | No stock | SAP will not |
///
/// Rendering "never asked" as "No stock" would be the worst of the four
/// mistakes available here: a rep would decline a sale on the strength of a
/// question the handset had not got round to asking.
///
/// ## The `INPUT_*` caveat
///
/// SAP needs `salesOrg`, `disChannel` and `division`. Without them it answers
/// **200** carrying `isSellable: false` and `INPUT_VKORG` / `INPUT_VTWEG`
/// checks — the validation never ran. That currently renders as "No stock"
/// alongside every genuine refusal, which is the product decision on record;
/// [MaterialAvailability.isInputIncomplete] keeps the two distinguishable in
/// the tooltip and in logs so the gap stays visible to whoever has to close it.
class StockAvailabilityBadge extends StatelessWidget {
  const StockAvailabilityBadge({
    super.key,
    required this.availability,
    this.compact = false,
  });

  /// Null when this material has never been checked, in which case nothing
  /// renders at all.
  final MaterialAvailability? availability;

  /// Drops the label and keeps the dot, for a card too tight for words.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final verdict = availability;
    if (verdict == null) return const SizedBox.shrink();

    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    final (String label, Color color) = switch (verdict.status) {
      MaterialStockStatus.checking => (
          'products.status.checking_stock'.tr,
          colors.textSecondary,
        ),
      MaterialStockStatus.available => (
          'products.status.in_stock'.tr,
          colors.success,
        ),
      MaterialStockStatus.unavailable => (
          'products.status.no_stock'.tr,
          scheme.error,
        ),
      MaterialStockStatus.unknown => (
          'products.status.stock_unknown'.tr,
          colors.textSecondary,
        ),
    };

    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rw(compact ? 5 : 6),
        vertical: context.rh(2),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(context.rr(4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (verdict.status == MaterialStockStatus.checking)
            SizedBox(
              width: context.rr(8),
              height: context.rr(8),
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            )
          else
            Container(
              width: context.rr(6),
              height: context.rr(6),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          if (!compact) ...[
            SizedBox(width: context.rw(4)),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: context.rsp(10.5),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );

    // SAP's own explanation, long-pressable rather than printed: "not extended
    // to sales area 1000/10" is what lets a rep phone the right person, and
    // "cannot sell this" is not. Nothing is attached while the check is still
    // in flight, when there is no reasoning yet to show.
    final reason =
        verdict.status == MaterialStockStatus.checking ? '' : verdict.reason;
    if (reason.isEmpty) return badge;

    return Tooltip(
      message: reason,
      triggerMode: TooltipTriggerMode.longPress,
      child: badge,
    );
  }
}
