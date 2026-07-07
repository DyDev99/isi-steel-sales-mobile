import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/models/visit_record.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/visit_map_preview.dart';

(String label, Color color) statusStyle(VisitHistoryStatus status) => switch (status) {
      VisitHistoryStatus.completed => ('my_visits.history.status_completed'.tr, Vibe.success),
      VisitHistoryStatus.missed => ('my_visits.history.status_missed'.tr, Vibe.danger),
      VisitHistoryStatus.pending => ('my_visits.history.status_pending'.tr, Vibe.amber),
    };

/// One row in the My Visits history list — static map thumbnail, customer
/// name/address, date, and a status chip. Tapping opens the detail screen.
class VisitHistoryCard extends StatelessWidget {
  const VisitHistoryCard({super.key, required this.visit, required this.onTap});

  final VisitRecord visit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = statusStyle(visit.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Vibe.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Vibe.stroke),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: VisitMapPreview(
                    latitude: visit.latitude,
                    longitude: visit.longitude,
                    height: 100,
                    borderRadius: 0,
                    showCoordinates: false,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              visit.customerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Vibe.text, fontSize: 14, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        visit.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Vibe.muted, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 13, color: Vibe.muted),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('MMM d, y · h:mm a').format(visit.visitDate),
                            style: const TextStyle(color: Vibe.muted, fontSize: 12),
                          ),
                          const Spacer(),
                          if (visit.orderPlaced)
                            const Icon(Icons.receipt_long_rounded, size: 16, color: Vibe.violet),
                          const Icon(Icons.chevron_right_rounded, color: Vibe.muted),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
