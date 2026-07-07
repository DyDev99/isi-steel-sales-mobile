import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

/// UI-only error state for the visit history list — no real fetch/retry logic
/// behind it, the caller wires [onRetry] to whatever it wants to re-run.
class VisitHistoryErrorState extends StatelessWidget {
  const VisitHistoryErrorState({super.key, required this.onRetry});
  final VoidCallback onRetry;

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
              decoration: BoxDecoration(color: Vibe.danger.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.cloud_off_rounded, size: 34, color: Vibe.danger),
            ),
            const SizedBox(height: 16),
            Text(
              'my_visits.history.error_title'.tr,
              style: const TextStyle(color: Vibe.text, fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'my_visits.history.error_message'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Vibe.muted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Vibe.violet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('my_visits.history.retry'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
