import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/network/connectivity_service.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart'; // Ensure correct path to AppThemeColors

/// A thin warning-tinted strip that appears only while the device is offline, reassuring
/// the field agent that GPS logs, photos, and captured data are queued on the
/// device and will sync once a connection returns. Collapses to nothing when
/// online.
///
/// Reads [ConnectivityService], never `connectivity_plus` directly (ADR-005 §3):
/// this banner and the sync engine must agree on what "offline" means, and the
/// plugin's interface-up signal would report "online" on a captive-portal Wi-Fi
/// where nothing can actually sync.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.margin = EdgeInsets.zero});

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context
        .appColors; // Access the resolved semantic theme extension tokens
    final connectivity = sl<ConnectivityService>();

    return StreamBuilder<ConnectivityStatus>(
      stream: connectivity.changes,
      initialData: connectivity.status,
      builder: (context, snapshot) {
        final offline = snapshot.data == ConnectivityStatus.offline;
        if (!offline) return const SizedBox.shrink();

        return Container(
          margin: margin,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.warning.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(Icons.cloud_off_rounded, color: colors.warning, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'my_visits.flow.offline_saved'.tr,
                  style: TextStyle(
                    color: colors.warning,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
