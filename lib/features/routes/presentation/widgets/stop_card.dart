import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/visit_status.dart';

class StopCard extends StatelessWidget {
  const StopCard({super.key, required this.stop, required this.selected, required this.onTap});
  final RouteStop stop;
  final bool selected;
  final VoidCallback onTap;

  Color get _statusColor => switch (stop.status) {
        VisitStatus.pending => Vibe.muted,
        VisitStatus.enRoute || VisitStatus.arrived => Vibe.violet,
        VisitStatus.checkedIn => Vibe.amber,
        VisitStatus.checkedOut => Vibe.success,
        VisitStatus.missed => Vibe.danger,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? Vibe.violet : _statusColor.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Text('${stop.sequence}',
                  style: TextStyle(
                      color: selected ? Colors.white : _statusColor, fontSize: 12, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stop.customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Vibe.text, fontSize: 13, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(stop.customer.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Vibe.muted, fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
              child: Text(stop.status.label, style: TextStyle(color: _statusColor, fontSize: 10.5, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
