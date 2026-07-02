import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/ui/app_vibe.dart';

class QuickAction {
  const QuickAction(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
}

class QuickActions extends StatelessWidget {
  const QuickActions({super.key, required this.actions});
  final List<QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final a = actions[i];
          return InkWell(
            onTap: a.onTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Vibe.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Vibe.stroke),
              ),
              child: Row(
                children: [
                  Icon(a.icon, size: 16, color: Vibe.pink),
                  const SizedBox(width: 8),
                  Text(a.label,
                      style: const TextStyle(
                          color: Vibe.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
