import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/opportunity_info.dart';

const _valueChips = <(String, double)>[
  ('\$10k', 10000),
  ('\$25k', 25000),
  ('\$50k', 50000),
  ('\$100k', 100000),
  ('\$100k+', 150000),
];

/// The only question asked to open an opportunity: what's it roughly
/// worth? Everything else (tonnage, grade, budget, authority) is filled in
/// later, in place, on the deal detail screen — never gated here.
Future<OpportunityInfo?> showConvertToOpportunitySheet({
  required BuildContext context,
  required Lead lead,
}) {
  return showModalBottomSheet<OpportunityInfo>(
    context: context,
    backgroundColor: context.appColors.surfaceSoft,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) => _ConvertSheet(lead: lead),
  );
}

class _ConvertSheet extends StatefulWidget {
  const _ConvertSheet({required this.lead});
  final Lead lead;

  @override
  State<_ConvertSheet> createState() => _ConvertSheetState();
}

class _ConvertSheetState extends State<_ConvertSheet> {
  double? _value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('leads.qualify'.trParams({'company': widget.lead.companyName}),
                style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('leads.qualify_subtitle'.tr,
                style: TextStyle(color: colors.textSecondary, fontSize: 12.5)),
            const SizedBox(height: 16),
            Text('leads.deal_worth'.tr,
                style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _valueChips
                  .map((c) => ChoiceChip(
                        label: Text(c.$1),
                        selected: _value == c.$2,
                        onSelected: (_) => setState(() => _value = c.$2),
                        labelStyle: TextStyle(
                            color: _value == c.$2
                                ? scheme.primary
                                : colors.textPrimary,
                            fontSize: 13),
                        backgroundColor: colors.card,
                        selectedColor: scheme.primary.withValues(alpha: 0.2),
                        side: BorderSide(
                            color: _value == c.$2
                                ? scheme.primary
                                : colors.border),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _value == null
                    ? null
                    : () => Navigator.of(context)
                        .pop(OpportunityInfo(estimatedValue: _value!)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('leads.move_to_opportunities'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
