import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isi_steel_sales_mobile/core/animations/app_animations.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/quotation/promotion_detail_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/quotation/promotions_mock_data.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/promotions/promo_card.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/promotions/promo_view.dart';

/// The promotions block inside the quotation builder.
///
/// Rebuilt around what the rep is doing here. They came to this screen to build
/// a quote; promotions are the supporting information they check on the way
/// past. The previous version rendered all four groups fully expanded —
/// thirteen promotions, a horizontal rail, roughly 700 vertical points of
/// content — in the middle of the form, so the rep scrolled through the entire
/// promotions catalogue every time they wanted the cart below it.
///
/// So: one collapsible block that states what is available in a line, and opens
/// to a **preview per group** (the one expiring soonest) with a link to the
/// rest. That is progressive disclosure (FS-UX-4) rather than a wall, and it
/// leaves the section's total height roughly one screen instead of three.
class PromotionSectionWidget extends StatefulWidget {
  const PromotionSectionWidget({
    super.key,
    this.groups,
    this.now,
    this.terms,
    this.initiallyExpanded = true,
  });

  /// Injectable so a test — and later the repository — supplies the data.
  final List<PromoGroup>? groups;

  /// Injectable clock; see `PromoCountdown.now`.
  final DateTime? now;

  /// How the quotation is currently set up. Rebuilt from the parent's state, so
  /// changing the shipment method re-evaluates every promotion here — which is
  /// the whole point: the COD / Pickup discount is only earned by collecting,
  /// and a rep switching to Delivery must not still see it as money in hand.
  final OrderTerms? terms;

  /// Open by default: a rep who has never seen the section should not have to
  /// discover it. Once they fold it, it stays folded for the rest of the quote.
  final bool initiallyExpanded;

  @override
  State<PromotionSectionWidget> createState() => _PromotionSectionWidgetState();
}

class _PromotionSectionWidgetState extends State<PromotionSectionWidget> {
  late bool _expanded = widget.initiallyExpanded;
  late final DateTime _now = widget.now ?? DateTime.now();
  late final List<PromoGroup> _groups =
      widget.groups ?? mockQuotationPromoGroups;

  Iterable<PromoView> get _available => _groups
      .expand((g) => g.promos)
      .where((p) => p.isAvailableFor(_now, widget.terms));

  /// "Ending soon" is the same seven-day window [PromoView.urgency] calls
  /// urgent, so the summary line and the countdowns inside can never disagree.
  ///
  /// Both counts are over the *available* set. A header that said "13
  /// available" while three of them were greyed out for this order would be
  /// worse than no header — the number is the part a rep repeats to a
  /// customer.
  int get _endingSoon =>
      _available.where((p) => p.urgency(_now) == PromoUrgency.urgent).length;

  int get _total => _available.length;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(context.rr(16)),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            expanded: _expanded,
            total: _total,
            endingSoon: _endingSoon,
            onToggle: () {
              HapticFeedback.selectionClick();
              setState(() => _expanded = !_expanded);
            },
          ),
          // AnimatedSize so the fold reads as the block changing size rather
          // than the page jumping under the rep's thumb (FS-ANI-4, FS-UX-2).
          // The collapsed branch is a zero-height full-width box, not a
          // `shrink`: the block must keep the column's width while it animates
          // or the header snaps narrow for the duration.
          AnimatedSize(
            duration: AppDurations.medium,
            curve: AppCurves.standard,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.rw(12),
                      0,
                      context.rw(12),
                      context.rh(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final group in _groups)
                          if (group.promos.isNotEmpty)
                            _GroupBlock(
                              group: group,
                              now: _now,
                              terms: widget.terms,
                            ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.expanded,
    required this.total,
    required this.endingSoon,
    required this.onToggle,
  });

  final bool expanded;
  final int total;
  final int endingSoon;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      expanded: expanded,
      label: 'promotions.section_title'.tr,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: EdgeInsets.all(context.rr(14)),
          child: Row(
            children: [
              Icon(Icons.local_offer_rounded,
                  size: context.rr(18), color: scheme.primary),
              SizedBox(width: context.rw(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'promotions.section_title'.tr,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: context.rsp(14.5),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: context.rh(2)),
                    Text(
                      // Says what is there before it is opened, so folding the
                      // block never hides the fact that something is expiring.
                      endingSoon > 0
                          ? 'promotions.summary_with_urgent'.trParams({
                              'count': '$total',
                              'soon': '$endingSoon',
                            })
                          : 'promotions.summary'.trParams({'count': '$total'}),
                      style: TextStyle(
                        color: endingSoon > 0
                            ? colors.warningAlt
                            : colors.textSecondary,
                        fontSize: context.rsp(11.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: AppDurations.fast,
                curve: AppCurves.standard,
                child: Icon(Icons.expand_more_rounded,
                    size: context.rr(22), color: colors.iconMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One group heading plus its most urgent promotion, and a way to the rest.
class _GroupBlock extends StatelessWidget {
  const _GroupBlock({
    required this.group,
    required this.now,
    required this.terms,
  });

  final PromoGroup group;
  final DateTime now;
  final OrderTerms? terms;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    final ordered = [...group.promos]
      ..sort((a, b) => a.endsOn.compareTo(b.endsOn));

    // Preview the soonest promotion the rep can actually use, and only fall
    // back to a blocked one when the whole group is blocked. Otherwise a group
    // whose first entry happens to need pickup would show a greyed card and
    // hide two live ones behind "See all".
    final preview = ordered.firstWhere(
      (p) => p.isAvailableFor(now, terms),
      orElse: () => ordered.first,
    );
    final remaining = ordered.length - 1;

    return Padding(
      padding: EdgeInsets.only(bottom: context.rh(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  group.titleKey.tr,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: context.rsp(13),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (remaining > 0)
                // A 44pt-tall target, not the bare `GestureDetector` on a text
                // span this replaced — that measured about 70x16 (FS-UX-3).
                InkWell(
                  onTap: () => _openAll(context, ordered),
                  borderRadius: BorderRadius.circular(context.rr(8)),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.rw(8),
                      vertical: context.rh(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'promotions.see_all'
                              .trParams({'count': '${ordered.length}'}),
                          style: TextStyle(
                            color: scheme.primary,
                            fontSize: context.rsp(12),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: context.rw(2)),
                        Icon(Icons.chevron_right_rounded,
                            size: context.rr(16), color: scheme.primary),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: context.rh(6)),
          PromoCard(
            promo: preview,
            now: now,
            terms: terms,
            // The code belongs on the detail screen; on a preview inside a form
            // it adds a row and an action to a card that is only a signpost.
            showCode: false,
            onTap: () => _openAll(context, ordered),
          ),
        ],
      ),
    );
  }

  void _openAll(BuildContext context, List<PromoView> promos) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PromotionDetailScreen(
          title: group.titleKey.tr,
          promos: promos,
          now: now,
          terms: terms,
        ),
      ),
    );
  }
}
