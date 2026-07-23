import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/l10n/lead_labels.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/priority.dart';

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});
  final Priority priority;

  Color _color(ColorScheme scheme, AppThemeColors colors) => switch (priority) {
        Priority.high => scheme.error,
        Priority.medium => colors.warning,
        Priority.low => colors.info,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color(Theme.of(context).colorScheme, context.appColors);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        priority.localizedLabel,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
