import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/fetch_visit_data.dart';

class TimelineEntry {
  const TimelineEntry(
      {required this.time, required this.label, required this.icon});
  final DateTime time;
  final String label;
  final IconData icon;
}

/// Assembles the "08:01 Start Route -> 08:35 Arrived -> Check In -> Stock
/// Updated -> Order Created -> Check Out" style timeline from a stop's
/// check-in/out timestamps plus whatever's been captured during the visit.
List<TimelineEntry> buildVisitTimeline(RouteStop stop, VisitData? data) {
  final entries = <TimelineEntry>[];
  if (stop.actualArrival != null) {
    entries.add(TimelineEntry(
        time: stop.actualArrival!,
        label: 'Checked in',
        icon: Icons.login_rounded));
  }
  if (data != null) {
    for (final line in data.orderLines) {
      entries.add(TimelineEntry(
          time: stop.actualArrival ?? DateTime.now(),
          label: 'Order: ${line.productName}',
          icon: Icons.shopping_cart_rounded));
    }
    for (final s in data.stockUpdates) {
      entries.add(TimelineEntry(
          time: stop.actualArrival ?? DateTime.now(),
          label: 'Stock updated: ${s.productName}',
          icon: Icons.inventory_2_rounded));
    }
    for (final r in data.returns) {
      entries.add(TimelineEntry(
          time: stop.actualArrival ?? DateTime.now(),
          label: 'Return: ${r.productName}',
          icon: Icons.undo_rounded));
    }
    for (final c in data.collections) {
      entries.add(TimelineEntry(
          time: stop.actualArrival ?? DateTime.now(),
          label: 'Collection: \$${c.amount.toStringAsFixed(2)}',
          icon: Icons.payments_rounded));
    }
    for (final n in data.notes) {
      entries.add(TimelineEntry(
          time: n.createdAt,
          label: 'Note added',
          icon: Icons.note_alt_rounded));
    }
    for (final p in data.photos) {
      entries.add(TimelineEntry(
          time: p.takenAt,
          label: p.isSignature ? 'Signature captured' : 'Photo added',
          icon: Icons.photo_camera_rounded));
    }
  }
  if (stop.actualDeparture != null) {
    entries.add(TimelineEntry(
        time: stop.actualDeparture!,
        label: 'Checked out',
        icon: Icons.logout_rounded));
  }
  entries.sort((a, b) => a.time.compareTo(b.time));
  return entries;
}

class VisitTimeline extends StatelessWidget {
  const VisitTimeline({super.key, required this.entries});
  final List<TimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Text('No activity yet',
          style: TextStyle(color: Vibe.muted, fontSize: 12.5));
    }
    return Column(
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: Vibe.primaryLight,
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(entry.icon, size: 14, color: Vibe.violet),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(entry.label,
                      style: const TextStyle(
                          color: Vibe.text,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600)),
                ),
                Text(_formatTime(entry.time),
                    style: const TextStyle(color: Vibe.muted, fontSize: 11)),
              ],
            ),
          ),
      ],
    );
  }

  static String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
