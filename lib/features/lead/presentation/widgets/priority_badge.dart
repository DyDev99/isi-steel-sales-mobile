import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/priority.dart';

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});
  final Priority priority;

  Color get _color => switch (priority) {
        Priority.high => Vibe.danger,
        Priority.medium => Vibe.amber,
        Priority.low => Vibe.mint,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        priority.label,
        style:
            TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
