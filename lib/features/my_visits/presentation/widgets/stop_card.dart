import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isi_steel_sales_mobile/core/animations/animated_card.dart';
import 'package:isi_steel_sales_mobile/core/animations/app_animations.dart';
import 'package:isi_steel_sales_mobile/core/animations/press_scale.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/models/today_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/skip_visit_dialog.dart';

class StopCard extends StatelessWidget {
  const StopCard({
    super.key,
    required this.todayStop,
    required this.onTap,
    this.onQuotationTap,
    this.onSkipSubmitted,
    this.isToday = true,
  });

  final TodayStop todayStop;
  final VoidCallback onTap;
  final VoidCallback? onQuotationTap;
  final void Function(String reason, String? photoPath)? onSkipSubmitted;
  final bool isToday;

  VisitStatus get _status => todayStop.stop.status;

  /// Status Color Schemes
  ({Color color, String label}) _getVisitStatusStyle(BuildContext context) {
    final colors = context.appColors;

    switch (_status) {
      case VisitStatus.checkedOut:
        return (color: colors.success, label: 'Visited');
      case VisitStatus.checkedIn:
        return (color: Colors.blue, label: 'In Progress');
      case VisitStatus.missed:
        return (color: Theme.of(context).colorScheme.error, label: 'Skipped');
      case VisitStatus.pending:
      default:
        return (color: colors.textSecondary, label: 'Pending');
    }
  }

  /// Helper to get tier badge colors (Diamond/Gold/Silver/Bronze)
  ({Color bg, Color text}) _getTierColors(String tier) {
    switch (tier.toLowerCase()) {
      case 'diamond':
        return (bg: const Color(0xFFE0F7FA), text: const Color(0xFF006064));
      case 'gold':
        return (bg: const Color(0xFFFFF8E1), text: const Color(0xFFF57F17));
      case 'silver':
        return (bg: const Color(0xFFF5F5F5), text: const Color(0xFF616161));
      case 'bronze':
        return (bg: const Color(0xFFEFEBE9), text: const Color(0xFF4E342E));
      default:
        return (bg: const Color(0xFFF5F5F5), text: const Color(0xFF616161));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final statusStyle = _getVisitStatusStyle(context);
    final customer = todayStop.stop.customer;

    // Display Name formatted as KH & EN
    final khName = customer.nameKh;
    final enName = customer.name;
    final formattedOutletName =
        khName.isNotEmpty ? '$khName ($enName)' : enName;

    // Rules:
    // 1. Can only start/view detail on today's call plan
    // 2. Can only skip visits on today's call plan
    // 3. Ad-Hoc order button is accessible anytime
    final isVisitedOrSkipped =
        _status == VisitStatus.checkedOut || _status == VisitStatus.missed;
    final canSkip = isToday && !isVisitedOrSkipped;
    final canStartVisit = isToday && !isVisitedOrSkipped;

    // Retrieve channel (Wholesale/Retail) and tier (Diamond/Gold/Silver/Bronze)
    final channelTag = customer.territoryType.label;
    final tierTag = 'Silver'; // Fallback / mock field from customer entity

    final tierColors = _getTierColors(tierTag);

    return Padding(
      padding: EdgeInsets.only(bottom: context.rh(12)),
      // `AnimatedCard` rather than a bare `InkWell` over a `Container`: the
      // rest state is pixel-identical (same colour, border, radius, shadow),
      // and the card gains the press scale, ripple and shadow-settle every
      // other pressable surface in the app already has. A stop card is the
      // primary target on this screen — it should answer a finger.
      child: AnimatedCard(
        onTap: canStartVisit ? onTap : null,
        color: colors.card,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(context.rr(16)),
        restShadow: colors.cardShadow,
        // A card that cannot be opened must not pretend otherwise.
        enableHoverScale: canStartVisit,
        pressedScale: canStartVisit ? AppScale.pressedCard : 1.0,
        padding: EdgeInsets.symmetric(
          horizontal: context.rw(16),
          vertical: context.rh(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Outlet Name, Address & Status Pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedOutletName,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: context.rsp(15),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: context.rh(4)),
                      Text(
                        customer.address,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: context.rsp(11.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: context.rw(12)),

                // Status pill.
                //
                // Animated because this is the one thing on the card that
                // *changes*, and it is the app's whole answer to "did my
                // visit register?". `WatchAllRoutes` pushes the new status
                // in live, so with a static pill the label simply teleports
                // from "In Progress" to "Visited" — easy to miss, and the
                // rep is left tapping Complete Visit again. The colour eases
                // and the wording cross-fades, so the change is witnessed.
                AnimatedContainer(
                  duration: AppDurations.medium,
                  curve: AppCurves.standard,
                  padding: EdgeInsets.symmetric(
                    horizontal: context.rw(10),
                    vertical: context.rh(4),
                  ),
                  decoration: BoxDecoration(
                    color: statusStyle.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(context.rr(12)),
                  ),
                  child: AnimatedSwitcher(
                    duration: AppDurations.medium,
                    switchInCurve: AppCurves.standard,
                    switchOutCurve: AppCurves.standard,
                    // Size-transition too, so a pill going from "Pending" to
                    // "In Progress" grows into the wider word instead of
                    // clipping it mid-fade.
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        axis: Axis.horizontal,
                        sizeFactor: animation,
                        child: child,
                      ),
                    ),
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.centerRight,
                      children: [...previous, if (current != null) current],
                    ),
                    child: Text(
                      statusStyle.label,
                      // Keyed by the status, not the text: without a key
                      // `AnimatedSwitcher` sees one `Text` and never runs.
                      key: ValueKey(_status),
                      style: TextStyle(
                        color: statusStyle.color,
                        fontSize: context.rsp(11),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.rh(10)),

            // Middle Row: Territory + Channel + Tier Tags + Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Tagging Section: Territory, Wholesale/Retail, Diamond/Gold/Silver/Bronze
                Expanded(
                  child: Wrap(
                    spacing: context.rw(6),
                    runSpacing: context.rh(4),
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _TagChip(
                        label: customer.territory,
                        color: colors.border,
                      ),
                      _TagChip(
                        label: channelTag,
                        color: Colors.amber.shade100,
                        textColor: Colors.amber.shade900,
                      ),
                      _TagChip(
                        label: tierTag,
                        color: tierColors.bg,
                        textColor: tierColors.text,
                      ),
                    ],
                  ),
                ),

                // Action Buttons Section
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Basket Order Button — hidden when pending
                    if (_status != VisitStatus.pending)
                      _ActionButton(
                        icon: Icons.shopping_basket_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
                        onTap: onQuotationTap,
                      ),

                    // Skip Visit Button — shown only when pending today
                    if (canSkip) ...[
                      SizedBox(width: context.rw(8)),
                      _ActionButton(
                        icon: Icons.cancel_rounded,
                        color: Theme.of(context).colorScheme.error,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .error
                            .withValues(alpha: 0.12),
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          final result = await showSkipVisitDialog(
                            context,
                            customer: customer,
                          );
                          if (result != null) {
                            onSkipSubmitted?.call(
                                result.reason, result.photoPath);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.color, this.textColor});
  final String label;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rw(8),
        vertical: context.rh(4),
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(context.rr(6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? context.appColors.textPrimary,
          fontSize: context.rsp(10.5),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // `PressScale`, not a bare `InkWell`: these sit *inside* the card's own
    // ripple, so a tap on the basket used to read as a tap on the card behind
    // it — the ripple spread across the whole surface and the button itself
    // did nothing visible. Scaling the button says which of the two nested
    // targets the finger actually hit.
    return PressScale(
      onTap: onTap,
      enabled: onTap != null,
      child: Container(
        padding: EdgeInsets.all(context.rr(6)),
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: context.rr(22),
          color: color,
        ),
      ),
    );
  }
}
