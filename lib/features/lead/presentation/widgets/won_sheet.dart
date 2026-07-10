import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/won_info.dart';

const _timelines = ['This month', 'Next month', 'This quarter'];

/// Marking a deal Won only asks for the final value; delivery timeline is
/// optional. This does not create the SAP customer — that's the separate
/// "Send to HQ" step from the Won card.
Future<WonInfo?> showWonSheet(
    {required BuildContext context, required Lead lead}) {
  return showModalBottomSheet<WonInfo>(
    context: context,
    backgroundColor: Vibe.bgSoft,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) => _WonSheet(lead: lead),
  );
}

class _WonSheet extends StatefulWidget {
  const _WonSheet({required this.lead});
  final Lead lead;

  @override
  State<_WonSheet> createState() => _WonSheetState();
}

class _WonSheetState extends State<_WonSheet> {
  late final _finalValue = TextEditingController(
    text: widget.lead.opportunityInfo?.estimatedValue.toStringAsFixed(0) ?? '',
  );
  String? _timeline;

  @override
  void dispose() {
    _finalValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.lead.companyName} — Won!',
                  style: const TextStyle(
                      color: Vibe.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text(
                  "Nice work. One more step gets this to SAP so HQ can set up billing.",
                  style: TextStyle(color: Vibe.muted, fontSize: 12.5)),
              const SizedBox(height: 16),
              TextField(
                controller: _finalValue,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Vibe.text, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Final value (\$)',
                  labelStyle: const TextStyle(color: Vibe.muted, fontSize: 13),
                  filled: true,
                  fillColor: Vibe.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Vibe.stroke),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Vibe.stroke),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Delivery timeline (optional)',
                  style: TextStyle(
                      color: Vibe.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _timelines
                    .map((t) => ChoiceChip(
                          label: Text(t),
                          selected: _timeline == t,
                          onSelected: (_) => setState(
                              () => _timeline = _timeline == t ? null : t),
                          labelStyle: TextStyle(
                              color: _timeline == t ? Vibe.violet : Vibe.text,
                              fontSize: 12.5),
                          backgroundColor: Vibe.surface,
                          selectedColor: Vibe.violet.withValues(alpha: 0.2),
                          side: BorderSide(
                              color:
                                  _timeline == t ? Vibe.violet : Vibe.stroke),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final value = double.tryParse(_finalValue.text.trim());
                    if (value == null) return;
                    Navigator.of(context).pop(WonInfo(
                        finalValue: value, deliveryTimeline: _timeline));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Vibe.success,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Mark as Won',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
