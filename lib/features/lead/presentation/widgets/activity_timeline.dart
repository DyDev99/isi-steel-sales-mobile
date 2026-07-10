import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/activity_log_item.dart';

class ActivityTimeline extends StatelessWidget {
  const ActivityTimeline({super.key, required this.items});
  final List<ActivityLogItem> items;

  ({IconData icon, Color color}) _style(ActivityLogKind kind) => switch (kind) {
        ActivityLogKind.leadCreated => (
            icon: Icons.person_add_alt_1_rounded,
            color: Vibe.violet
          ),
        ActivityLogKind.siteVisit => (
            icon: Icons.storefront_rounded,
            color: Vibe.mint
          ),
        ActivityLogKind.gpsCaptured => (
            icon: Icons.place_rounded,
            color: Vibe.amber
          ),
        ActivityLogKind.photoUploaded => (
            icon: Icons.photo_camera_rounded,
            color: Vibe.pink
          ),
        ActivityLogKind.documentCollected => (
            icon: Icons.description_rounded,
            color: Vibe.violet
          ),
        ActivityLogKind.creditSubmitted => (
            icon: Icons.send_rounded,
            color: Vibe.amber
          ),
        ActivityLogKind.creditApproved => (
            icon: Icons.verified_rounded,
            color: Vibe.success
          ),
        ActivityLogKind.customerCreated => (
            icon: Icons.storage_rounded,
            color: Vibe.success
          ),
        ActivityLogKind.stageChanged => (
            icon: Icons.trending_up_rounded,
            color: Vibe.violet
          ),
        ActivityLogKind.orderReceived => (
            icon: Icons.receipt_long_rounded,
            color: Vibe.success
          ),
        ActivityLogKind.note => (
            icon: Icons.sticky_note_2_rounded,
            color: Vibe.muted
          ),
      };

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('No activity yet',
            style: TextStyle(color: Vibe.muted, fontSize: 12.5)),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          _TimelineRow(
              item: items[i],
              style: _style(items[i].kind),
              isLast: i == items.length - 1),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow(
      {required this.item, required this.style, required this.isLast});
  final ActivityLogItem item;
  final ({IconData icon, Color color}) style;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, size: 15, color: style.color),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: Vibe.stroke)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          color: Vibe.text,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(item.description,
                      style:
                          const TextStyle(color: Vibe.muted, fontSize: 12.5)),
                  const SizedBox(height: 4),
                  Text('${item.actor} · ${_formatDateTime(item.timestamp)}',
                      style: const TextStyle(color: Vibe.muted, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
