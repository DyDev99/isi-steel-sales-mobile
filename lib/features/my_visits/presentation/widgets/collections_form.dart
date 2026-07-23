import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_collection.dart';

Future<VisitCollection?> showCollectionsSheet(
    {required BuildContext context, required String stopId}) {
  final amountController = TextEditingController();
  final referenceController = TextEditingController();
  final notesController = TextEditingController();
  var method = CollectionMethod.cash;

  return showModalBottomSheet<VisitCollection>(
    context: context,
    backgroundColor: context.appColors.surfaceSoft,
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
                Text('my_visits.forms.record_collection'.tr,
                    style: TextStyle(
                        color: context.appColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      hintText: 'Amount', prefixText: '\$ '),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final m in CollectionMethod.values)
                      ChoiceChip(
                        label: Text(m.name),
                        selected: method == m,
                        onSelected: (_) => setState(() => method = m),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: referenceController,
                    decoration: InputDecoration(
                        hintText: 'my_visits.forms.reference_optional'.tr)),
                const SizedBox(height: 10),
                TextField(
                    controller: notesController,
                    decoration:
                        InputDecoration(hintText: 'common.notes_optional'.tr)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final amount = double.tryParse(amountController.text);
                      if (amount == null || amount <= 0) return;
                      Navigator.pop(
                        context,
                        VisitCollection(
                          id: '${DateTime.now().microsecondsSinceEpoch}',
                          stopId: stopId,
                          amount: amount,
                          method: method,
                          reference: referenceController.text.trim(),
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
