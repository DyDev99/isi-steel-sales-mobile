import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/off_visit_reason.dart';

extension OffVisitReasonL10n on OffVisitReason {
  String get localizedLabel => switch (this) {
        OffVisitReason.phoneOrder => 'orders.shop.reason_phone_order'.tr,
        OffVisitReason.urgentRestock => 'orders.shop.reason_urgent_restock'.tr,
        OffVisitReason.passingBy => 'orders.shop.reason_passing_by'.tr,
      };
}

/// Off-visit reason picker — same bottom-sheet shape as `collections_form.dart`
/// in the `my_visits` feature (StatefulBuilder + ChoiceChip + pop-with-value).
Future<OffVisitReason?> showOffVisitReasonSheet(
    {required BuildContext context, OffVisitReason? initial}) {
  var reason = initial ?? OffVisitReason.phoneOrder;
  final colors = Theme.of(context).extension<AppThemeColors>()!;

  return showModalBottomSheet<OffVisitReason>(
    context: context,
    backgroundColor: colors.surfaceSoft,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('orders.shop.off_visit_warning'.tr,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final r in OffVisitReason.values)
                      ChoiceChip(
                        label: Text(r.localizedLabel),
                        selected: reason == r,
                        onSelected: (_) => setState(() => reason = r),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, reason),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accentPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('orders.shop.start_quotation'.tr),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}