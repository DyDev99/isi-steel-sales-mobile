import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_return.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/app_bottom_sheet.dart';

Future<VisitReturn?> showReturnsSheet(
    {required BuildContext context, required String stopId}) {
  final productController = TextEditingController();
  final qtyController = TextEditingController();
  final reasonController = TextEditingController();

  return showModalBottomSheet<VisitReturn>(
    constraints: const BoxConstraints(maxWidth: AppBottomSheet.maxWidth),
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
              Text('my_visits.forms.capture_return'.tr,
                  style: TextStyle(
                      color: context.appColors.textPrimary,
                      fontSize: context.rsp(17),
                      fontWeight: FontWeight.w800)),
              SizedBox(height: context.rh(12)),
              TextField(
                  controller: productController,
                  decoration: InputDecoration(
                      hintText: 'my_visits.forms.product_name'.tr)),
              SizedBox(height: context.rh(10)),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    hintText: 'my_visits.forms.quantity_returned'.tr),
              ),
              SizedBox(height: context.rh(10)),
              TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(hintText: 'Reason')),
              SizedBox(height: context.rh(16)),
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
                      VisitReturn(
                        id: '${DateTime.now().microsecondsSinceEpoch}',
                        stopId: stopId,
                        productId: productController.text.trim(),
                        productName: productController.text.trim(),
                        quantity: qty,
                        reason: reasonController.text.trim().isEmpty
                            ? 'common.not_specified'.tr
                            : reasonController.text.trim(),
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
