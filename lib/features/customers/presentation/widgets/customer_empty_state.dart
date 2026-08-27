import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

/// Explains an empty directory without conflating it with a loading failure.
class CustomerEmptyState extends StatelessWidget {
  const CustomerEmptyState({
    super.key,
    required this.hasActiveSearchOrFilter,
    this.onClearSearchOrFilter,
  });

  final bool hasActiveSearchOrFilter;
  final VoidCallback? onClearSearchOrFilter;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.rr(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: context.rr(48),
              color: colors.textSecondary,
            ),
            SizedBox(height: context.rh(12)),
            Text(
              'customers.no_customers'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: context.rsp(16),
                fontWeight: FontWeight.w800,
              ),
            ),
            if (hasActiveSearchOrFilter) ...[
              SizedBox(height: context.rh(6)),
              Text(
                'customers.no_matches'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: context.rsp(13),
                ),
              ),
              if (onClearSearchOrFilter != null) ...[
                SizedBox(height: context.rh(16)),
                TextButton(
                  onPressed: onClearSearchOrFilter,
                  child: Text('common.clear_search'.tr),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
