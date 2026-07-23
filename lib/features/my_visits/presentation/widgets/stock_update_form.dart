import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/stock_level.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_stock_update.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/stock_level_selector.dart';

/// Bottom sheet for a one-off stock status capture from the stop detail
/// screen: product name + a single Low / Medium / High selection (no numeric
/// quantity). Save is disabled until both are provided.
Future<VisitStockUpdate?> showStockUpdateSheet(
    {required BuildContext context, required String stopId}) {
  final productController = TextEditingController();
  final notesController = TextEditingController();
  StockLevel? level;

  return showModalBottomSheet<VisitStockUpdate>(
    context: context,
    backgroundColor: context.appColors.surfaceSoft,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('my_visits.forms.update_stock'.tr,
                    style: TextStyle(
                        color: context.appColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextField(
                    controller: productController,
                    onChanged: (_) => setSheetState(() {}),
                    decoration: InputDecoration(
                        hintText: 'my_visits.forms.product_name'.tr)),
                const SizedBox(height: 14),
                Text('my_visits.forms.stock_status'.tr,
                    style: TextStyle(
                        color: context.appColors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: StockLevelSelector(
                    value: level,
                    onChanged: (selected) =>
                        setSheetState(() => level = selected),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: notesController,
                    decoration:
                        InputDecoration(hintText: 'common.notes_optional'.tr)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        productController.text.trim().isEmpty || level == null
                            ? null
                            : () {
                                Navigator.pop(
                                  context,
                                  VisitStockUpdate(
                                    id: '${DateTime.now().microsecondsSinceEpoch}',
                                    stopId: stopId,
                                    productId: productController.text.trim(),
                                    productName: productController.text.trim(),
                                    stockLevel: level!,
                                    notes: notesController.text.trim(),
                                  ),
                                );
                              },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Save'),
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
