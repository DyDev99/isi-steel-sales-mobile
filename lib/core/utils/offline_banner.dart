import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

/// A thin amber strip that appears only while the device is offline, reassuring
/// the field agent that GPS logs, photos, and captured data are queued on the
/// device (SQLite) and will sync once a connection returns. Collapses to
/// nothing when online.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.margin = EdgeInsets.zero});

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final results = snapshot.data;
        // Before the first event we assume online (avoids a flash on launch).
        final offline = results != null &&
            results.every((r) => r == ConnectivityResult.none);
        if (!offline) return const SizedBox.shrink();

        return Container(
          margin: margin,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Vibe.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Vibe.amber.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_off_rounded, color: Vibe.amber, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'my_visits.flow.offline_saved'.tr,
                  style: const TextStyle(
                      color: Vibe.amber,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
