import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_status.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

/// Localized display label for a [CustomerStatus]. Kept here (presentation)
/// rather than on the domain enum so the entity stays free of any `.tr`/l10n
/// dependency. Reused by the filter sheet's status chips.
///
/// The API also returns a pre-translated `statusDisplay` for each customer.
/// This resolves the label locally instead, off the stable `status` code, so a
/// row rendered from the offline cache reads in the user's language even when
/// it was synced under a different one — and so a language switch is a plain
/// rebuild rather than a re-sync.
extension CustomerStatusL10n on CustomerStatus {
  String get localizedLabel => switch (this) {
        CustomerStatus.draft => 'customers.status.draft'.tr,
        CustomerStatus.pendingApproval =>
          'customers.status.pending_approval'.tr,
        CustomerStatus.active => 'customers.status.active'.tr,
        CustomerStatus.suspended => 'customers.status.suspended'.tr,
        CustomerStatus.closed => 'customers.status.closed'.tr,
        CustomerStatus.dormant => 'customers.status.dormant'.tr,
        CustomerStatus.creditHold => 'customers.status.credit_hold'.tr,
      };
}

class CustomerStatusBadge extends StatelessWidget {
  const CustomerStatusBadge({super.key, required this.status});
  final CustomerStatus status;

  Color _color(ColorScheme scheme, AppThemeColors colors) => switch (status) {
        CustomerStatus.active => colors.success,
        // Not yet cleared to trade — informational, not a fault.
        CustomerStatus.draft ||
        CustomerStatus.pendingApproval =>
          colors.textSecondary,
        // Blocked from trading, which a rep needs to notice before they start
        // writing an order.
        CustomerStatus.suspended ||
        CustomerStatus.closed ||
        CustomerStatus.creditHold =>
          scheme.error,
        CustomerStatus.dormant => colors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color(Theme.of(context).colorScheme, context.appColors);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.localizedLabel,
        style: TextStyle(
            color: color,
            fontSize: context.rsp(11),
            fontWeight: FontWeight.w700),
      ),
    );
  }
}
