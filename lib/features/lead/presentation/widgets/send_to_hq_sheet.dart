import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/l10n/lead_labels.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead_document.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/onboarding_status.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/shop_type.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/won_info.dart';

/// The SAP onboarding step, framed as "confirm what's already known, fill
/// in what's missing" rather than a fresh intake form — everything already
/// on the lead record is shown read-only with a checkmark; only genuinely
/// missing fields get an input.
Future<Lead?> showSendToHqSheet(
    {required BuildContext context, required Lead lead}) {
  return showModalBottomSheet<Lead>(
    context: context,
    backgroundColor: context.appColors.surfaceSoft,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
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
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('leads.hq.finish_onboarding'.tr,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  _canSubmit
                      ? 'leads.hq.confirm_ready'.tr
                      : 'leads.hq.items_left'
                          .trParams({'count': _missingCount}),
                  style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
                ),
                const SizedBox(height: 16),
                Text('leads.hq.already_confirmed'.tr,
                    style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _ConfirmedRow(label: 'leads.shop'.tr, value: lead.companyName),
                _ConfirmedRow(label: 'customers.phone'.tr, value: lead.phone),
                _ConfirmedRow(
                  label: 'leads.hq.gps_location'.tr,
                  value:
                      '${lead.latitude.toStringAsFixed(4)}, ${lead.longitude.toStringAsFixed(4)}',
                ),
                _ConfirmedRow(
                    label: 'leads.hq.won_value'.tr,
                    value: '\$${(won?.finalValue ?? 0).toStringAsFixed(0)}'),
                if (won != null && won.productsPurchased.isNotEmpty)
                  _ConfirmedRow(
                      label: 'leads.products'.tr,
                      value: won.productsPurchased.join(', ')),
                const SizedBox(height: 18),
                Text('leads.hq.needed_to_send'.tr,
                    style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (_ownerName.text.trim().isEmpty || lead.ownerName.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: _ownerName,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'leads.owner_name'.tr,
                        labelStyle: TextStyle(
                            color: colors.textSecondary, fontSize: 13),
                        filled: true,
                        fillColor: colors.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                      ),
                    ),
                  )
                else
                  _ConfirmedRow(label: 'leads.owner'.tr, value: lead.ownerName),
                Text('leads.shop_type'.tr,
                    style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ShopType.values
                      .map((t) => ChoiceChip(
                            label: Text(t.localizedLabel),
                            selected: _shopType == t,
                            onSelected: (_) => setState(() => _shopType = t),
                            labelStyle: TextStyle(
                                color: _shopType == t
                                    ? scheme.primary
                                    : colors.textPrimary,
                                fontSize: 12.5),
                            backgroundColor: colors.card,
                            selectedColor:
                                scheme.primary.withValues(alpha: 0.2),
                            side: BorderSide(
                                color: _shopType == t
                                    ? scheme.primary
                                    : colors.border),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 14),
                _DocRow(
                  label: 'leads.hq.business_licence'.tr,
                  attached: _hasLicence,
                  onAttach: () => setState(() => _hasLicence = true),
                ),
                _DocRow(
                  label: 'leads.hq.patent_tax_paper'.tr,
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
                            if (!lead.documents.any((d) =>
                                d.type == DocumentType.businessLicense)) {
                              docs.add(LeadDocument(
                                id: '${lead.id}-DOC-${DateTime.now().microsecondsSinceEpoch}',
                                name: 'Business License.pdf',
                                type: DocumentType.businessLicense,
                                url: 'mock://documents/business_license.pdf',
                                uploadedDate: DateTime.now(),
                              ));
                            }
                            if (!lead.documents.any((d) =>
                                d.type == DocumentType.taxRegistration)) {
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
                              wonInfo: (won ?? const WonInfo(finalValue: 0))
                                  .copyWith(
                                shopType: _shopType,
                                onboardingStatus:
                                    OnboardingStatus.pendingApproval,
                              ),
                            );
                            Navigator.of(context).pop(updated);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('leads.send_to_hq'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
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
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: colors.success),
          const SizedBox(width: 8),
          SizedBox(
              width: 100,
              child: Text(label,
                  style:
                      TextStyle(color: colors.textSecondary, fontSize: 12.5))),
          Expanded(
            child: Text(value.isEmpty ? '—' : value,
                style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow(
      {required this.label, required this.attached, required this.onAttach});
  final String label;
  final bool attached;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(
              attached
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: attached ? colors.success : colors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ),
          if (!attached)
            TextButton.icon(
              onPressed: onAttach,
              icon: Icon(Icons.camera_alt_outlined,
                  size: 16, color: scheme.primary),
              label: Text('Scan',
                  style: TextStyle(color: scheme.primary, fontSize: 12.5)),
            ),
        ],
      ),
    );
  }
}
