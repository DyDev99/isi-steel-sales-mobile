import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/models/today_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/skip_visit_dialog.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final statusStyle = _getVisitStatusStyle(context);
    final customer = todayStop.stop.customer;

    // Display Name formatted as KH & EN e.g. ស្រី លី (Srey Ly)
    final khName = customer.nameKh;
    final enName = customer.name;
    final formattedOutletName =
        khName.isNotEmpty ? '$khName ($enName)' : enName;

    // Actions (Skip / Cart) are allowed ONLY on today's date
    final isVisitedOrSkipped =
        _status == VisitStatus.checkedOut || _status == VisitStatus.missed;
    final canSkip = isToday &&
        _status != VisitStatus.checkedOut &&
        _status != VisitStatus.missed;
    final hasActions = isToday && (isVisitedOrSkipped || canSkip);

    return Padding(
      padding: EdgeInsets.only(bottom: context.rh(12)),
      child: AbsorbPointer(
        absorbing:
            !isToday, // 👈 Completely blocks all tap/click events if not today
        child: InkWell(
          onTap:
              isToday ? onTap : null, // 👈 Disables tap to view detail screen
          borderRadius: BorderRadius.circular(context.rr(16)),
          child: Opacity(
            opacity:
                isToday ? 1.0 : 0.85, // Visual indicator that item is read-only
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.rw(16),
                vertical: context.rh(14),
              ),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(context.rr(16)),
                border: Border.all(color: colors.border),
                boxShadow: colors.cardShadow,
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

                      // Status Pill
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.rw(10),
                          vertical: context.rh(4),
                        ),
                        decoration: BoxDecoration(
                          color: statusStyle.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(context.rr(12)),
                        ),
                        child: Text(
                          statusStyle.label,
                          style: TextStyle(
                            color: statusStyle.color,
                            fontSize: context.rsp(11),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.rh(10)),

                  // Middle Row: Territory Chips + Action Buttons (Only for today)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Territory Chips
                      Expanded(
                        child: Wrap(
                          spacing: context.rw(8),
                          runSpacing: context.rh(4),
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _TagChip(
                                label: customer.territory,
                                color: colors.border),
                            _TagChip(
                              label: customer.territoryType.label,
                              color: Colors.amber.shade100,
                              textColor: Colors.amber.shade900,
                            ),
                          ],
                        ),
                      ),

                      // Action Buttons (Only rendered when viewing today's date)
                      if (hasActions)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Quotation/Basket Button
                            if (isVisitedOrSkipped) ...[
                              _ActionButton(
                                icon: Icons.shopping_basket_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.12),
                                onTap: onQuotationTap,
                              ),
                              if (canSkip) SizedBox(width: context.rw(8)),
                            ],

                            // Big Red Cross Skip Button ❌
                            if (canSkip)
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.rr(20)),
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
