import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

/// Shown when the visit history list has no records. UI only — the caller
/// decides when this applies.
class VisitHistoryEmptyState extends StatelessWidget {
  const VisitHistoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Vibe.primaryLight,
                  borderRadius: BorderRadius.circular(20)),
              child:
                  const Icon(Icons.map_outlined, size: 34, color: Vibe.violet),
            ),
            const SizedBox(height: 16),
            Text(
              'my_visits.history.empty_title'.tr,
              style: const TextStyle(
                  color: Vibe.text, fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'my_visits.history.empty_subtitle'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Vibe.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
