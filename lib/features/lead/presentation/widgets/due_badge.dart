import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

/// Urgency tier for a [DueBadge]. Lets the same compact pill express
/// "5 Upcoming", "3 Due Today" or "2 Overdue" later — with distinct colours —
/// without redesigning the card layout. Today the card passes no urgency, so
/// the badge falls back to a neutral "N Due".
enum DueUrgency {
  upcoming('Upcoming'),
  dueToday('Due Today'),
  overdue('Overdue');

  const DueUrgency(this.label);
  final String label;
}

/// Compact Material 3 pill that surfaces how many pending actions a record has
/// — e.g. "2 Due" — meant to sit right-aligned on the same row as the shop /
/// depot name.
///
/// It is deliberately self-hiding: when [count] is `null` or `<= 0` it renders
/// a zero-size box, so callers can drop it into a row unconditionally and it
/// simply disappears when there's nothing due (it never shows "0 Due").
///
/// [urgency] is reserved for future colour/label variants. When supplied the
/// label becomes "$count ${urgency.label}" (e.g. "2 Overdue") and the pill
/// tints to match; otherwise it shows a neutral "$count Due".
class DueBadge extends StatelessWidget {
  const DueBadge({super.key, required this.count, this.urgency});

  final int? count;
  final DueUrgency? urgency;

  Color _color(ColorScheme scheme, AppThemeColors colors) => switch (urgency) {
        DueUrgency.overdue => scheme.error,
        DueUrgency.dueToday => colors.warning,
        DueUrgency.upcoming || null => scheme.primary,
      };

  @override
  Widget build(BuildContext context) {
    final value = count;
    if (value == null || value <= 0) return const SizedBox.shrink();

    final label = urgency == null ? '$value Due' : '$value ${urgency!.label}';
    final color = _color(Theme.of(context).colorScheme, context.appColors);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            color: color, fontSize: 10.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}
