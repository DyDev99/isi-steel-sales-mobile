import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_stock_update.dart';

Future<VisitStockUpdate?> showStockUpdateSheet(
    {required BuildContext context, required String stopId}) {
  final productController = TextEditingController();
  final qtyController = TextEditingController();
  final notesController = TextEditingController();

  return showModalBottomSheet<VisitStockUpdate>(
    context: context,
    backgroundColor: context.appColors.surfaceSoft,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (context) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Update Stock Count',
                  style: TextStyle(
                      color: context.appColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextField(
                  controller: productController,
                  decoration: const InputDecoration(hintText: 'Product name')),
              const SizedBox(height: 10),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Counted quantity'),
              ),
              const SizedBox(height: 10),
              TextField(
                  controller: notesController,
                  decoration:
                      const InputDecoration(hintText: 'Notes (optional)')),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final qty = double.tryParse(qtyController.text);
                    if (productController.text.trim().isEmpty || qty == null) {
                      return;
                    }
                    Navigator.pop(
                      context,
                      VisitStockUpdate(
                        id: '${DateTime.now().microsecondsSinceEpoch}',
                        stopId: stopId,
                        productId: productController.text.trim(),
                        productName: productController.text.trim(),
                        countedQuantity: qty,
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
  );
}
