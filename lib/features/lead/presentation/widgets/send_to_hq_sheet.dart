import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead_document.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/onboarding_status.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/shop_type.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/won_info.dart';

/// The SAP onboarding step, framed as "confirm what's already known, fill
/// in what's missing" rather than a fresh intake form — everything already
/// on the lead record is shown read-only with a checkmark; only genuinely
/// missing fields get an input.
Future<Lead?> showSendToHqSheet({required BuildContext context, required Lead lead}) {
  return showModalBottomSheet<Lead>(
    context: context,
    backgroundColor: Vibe.bgSoft,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (_) => _SendToHqSheet(lead: lead),
  );
}

class _SendToHqSheet extends StatefulWidget {
  const _SendToHqSheet({required this.lead});
  final Lead lead;

  @override
  State<_SendToHqSheet> createState() => _SendToHqSheetState();
}

class _SendToHqSheetState extends State<_SendToHqSheet> {
  late final _ownerName = TextEditingController(text: widget.lead.ownerName);
  ShopType? _shopType;
  late bool _hasLicence =
      widget.lead.documents.any((d) => d.type == DocumentType.businessLicense);
  late bool _hasTaxPaper =
      widget.lead.documents.any((d) => d.type == DocumentType.taxRegistration);

  @override
  void dispose() {
    _ownerName.dispose();
    super.dispose();
  }

  int get _missingCount =>
      (_ownerName.text.trim().isEmpty ? 1 : 0) +
      (_shopType == null ? 1 : 0) +
      (_hasLicence ? 0 : 1) +
      (_hasTaxPaper ? 0 : 1);

  bool get _canSubmit => _missingCount == 0;

  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;
    final won = lead.wonInfo;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Finish onboarding',
                    style: TextStyle(color: Vibe.text, fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  _canSubmit
                      ? "You already did the hard part. Just confirm and send."
                      : "You already did the hard part. $_missingCount item${_missingCount == 1 ? '' : 's'} left.",
                  style: const TextStyle(color: Vibe.muted, fontSize: 12.5),
                ),
                const SizedBox(height: 16),
                const Text('Already confirmed',
                    style: TextStyle(color: Vibe.muted, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _ConfirmedRow(label: 'Shop', value: lead.companyName),
                _ConfirmedRow(label: 'Phone', value: lead.phone),
                _ConfirmedRow(
                  label: 'GPS location',
                  value: '${lead.latitude.toStringAsFixed(4)}, ${lead.longitude.toStringAsFixed(4)}',
                ),
                _ConfirmedRow(label: 'Won value', value: '\$${(won?.finalValue ?? 0).toStringAsFixed(0)}'),
                if (won != null && won.productsPurchased.isNotEmpty)
                  _ConfirmedRow(label: 'Products', value: won.productsPurchased.join(', ')),
                const SizedBox(height: 18),
                const Text('Needed to send',
                    style: TextStyle(color: Vibe.muted, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (_ownerName.text.trim().isEmpty || lead.ownerName.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: _ownerName,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: Vibe.text, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Owner name',
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
                  )
                else
                  _ConfirmedRow(label: 'Owner', value: lead.ownerName),
                const Text('Shop type', style: TextStyle(color: Vibe.muted, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ShopType.values
                      .map((t) => ChoiceChip(
                            label: Text(t.label),
                            selected: _shopType == t,
                            onSelected: (_) => setState(() => _shopType = t),
                            labelStyle: TextStyle(color: _shopType == t ? Vibe.violet : Vibe.text, fontSize: 12.5),
                            backgroundColor: Vibe.surface,
                            selectedColor: Vibe.violet.withValues(alpha: 0.2),
                            side: BorderSide(color: _shopType == t ? Vibe.violet : Vibe.stroke),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 14),
                _DocRow(
                  label: 'Business Licence',
                  attached: _hasLicence,
                  onAttach: () => setState(() => _hasLicence = true),
                ),
                _DocRow(
                  label: 'Patent / Tax Paper',
                  attached: _hasTaxPaper,
                  onAttach: () => setState(() => _hasTaxPaper = true),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: !_canSubmit
                        ? null
                        : () {
                            final docs = [...lead.documents];
                            if (!lead.documents.any((d) => d.type == DocumentType.businessLicense)) {
                              docs.add(LeadDocument(
                                id: '${lead.id}-DOC-${DateTime.now().microsecondsSinceEpoch}',
                                name: 'Business License.pdf',
                                type: DocumentType.businessLicense,
                                url: 'mock://documents/business_license.pdf',
                                uploadedDate: DateTime.now(),
                              ));
                            }
                            if (!lead.documents.any((d) => d.type == DocumentType.taxRegistration)) {
                              docs.add(LeadDocument(
                                id: '${lead.id}-DOC-${DateTime.now().microsecondsSinceEpoch + 1}',
                                name: 'Tax Registration.pdf',
                                type: DocumentType.taxRegistration,
                                url: 'mock://documents/tax_registration.pdf',
                                uploadedDate: DateTime.now(),
                              ));
                            }
                            final updated = lead.copyWith(
                              ownerName: _ownerName.text.trim(),
                              documents: docs,
                              wonInfo: (won ?? const WonInfo(finalValue: 0)).copyWith(
                                shopType: _shopType,
                                onboardingStatus: OnboardingStatus.pendingApproval,
                              ),
                            );
                            Navigator.of(context).pop(updated);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Vibe.violet,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Send to HQ', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmedRow extends StatelessWidget {
  const _ConfirmedRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 16, color: Vibe.success),
          const SizedBox(width: 8),
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Vibe.muted, fontSize: 12.5))),
          Expanded(
            child: Text(value.isEmpty ? '—' : value,
                style: const TextStyle(color: Vibe.text, fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow({required this.label, required this.attached, required this.onAttach});
  final String label;
  final bool attached;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Vibe.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Vibe.stroke),
      ),
      child: Row(
        children: [
          Icon(attached ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 18, color: attached ? Vibe.success : Vibe.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(color: Vibe.text, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
          if (!attached)
            TextButton.icon(
              onPressed: onAttach,
              icon: const Icon(Icons.camera_alt_outlined, size: 16, color: Vibe.violet),
              label: const Text('Scan', style: TextStyle(color: Vibe.violet, fontSize: 12.5)),
            ),
        ],
      ),
    );
  }
}
