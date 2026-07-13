import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_status.dart';

/// Localized display label for a [CustomerStatus]. Kept here (presentation)
/// rather than on the domain enum so the entity stays free of any `.tr`/l10n
/// dependency. Reused by the filter sheet's status chips.
extension CustomerStatusL10n on CustomerStatus {
  String get localizedLabel => switch (this) {
        CustomerStatus.active => 'customers.status.active'.tr,
        CustomerStatus.dormant => 'customers.status.dormant'.tr,
        CustomerStatus.creditHold => 'customers.status.credit_hold'.tr,
      };
}

class CustomerStatusBadge extends StatelessWidget {
  const CustomerStatusBadge({super.key, required this.status});
  final CustomerStatus status;

  Color _color(ColorScheme scheme, AppThemeColors colors) => switch (status) {
        CustomerStatus.active => colors.success,
        CustomerStatus.dormant => colors.textSecondary,
        CustomerStatus.creditHold => scheme.error,
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
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
