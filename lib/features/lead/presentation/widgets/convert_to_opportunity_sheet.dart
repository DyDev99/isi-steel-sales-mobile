import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
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
    backgroundColor: Vibe.bgSoft,
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Qualify ${widget.lead.companyName}',
                style: const TextStyle(color: Vibe.text, fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Record what you now know about the deal — not questions for the customer.',
                style: TextStyle(color: Vibe.muted, fontSize: 12.5)),
            const SizedBox(height: 16),
            const Text('Roughly what is this deal worth?',
                style: TextStyle(color: Vibe.muted, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _valueChips
                  .map((c) => ChoiceChip(
                        label: Text(c.$1),
                        selected: _value == c.$2,
                        onSelected: (_) => setState(() => _value = c.$2),
                        labelStyle: TextStyle(color: _value == c.$2 ? Vibe.violet : Vibe.text, fontSize: 13),
                        backgroundColor: Vibe.surface,
                        selectedColor: Vibe.violet.withValues(alpha: 0.2),
                        side: BorderSide(color: _value == c.$2 ? Vibe.violet : Vibe.stroke),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _value == null
                    ? null
                    : () => Navigator.of(context).pop(OpportunityInfo(estimatedValue: _value!)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Vibe.violet,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Move to Opportunities', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
