import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/device/device_insets.dart';
import 'package:phone_form_field/phone_form_field.dart'; // Upgraded phone field package
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/credit_status.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead_source.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/priority.dart';

/// Create/edit bottom sheet. When [existing] is null this creates a new
/// lead in [PipelineStage.leads]; otherwise it returns an updated copy of
/// [existing] with the editable fields applied.
Future<Lead?> showLeadFormSheet(
    {required BuildContext context, Lead? existing}) {
  return showModalBottomSheet<Lead>(
    context: context,
    backgroundColor: context.appColors.surfaceSoft,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (_) => _LeadFormSheet(existing: existing),
  );
}

class _LeadFormSheet extends StatefulWidget {
  const _LeadFormSheet({this.existing});
  final Lead? existing;

  @override
  State<_LeadFormSheet> createState() => _LeadFormSheetState();
}

const _productOptions = ['Rebar', 'Mesh', 'Sheet', 'Sections', 'Mixed'];

class _LeadFormSheetState extends State<_LeadFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _company =
      TextEditingController(text: widget.existing?.companyName);
  late final _owner = TextEditingController(text: widget.existing?.ownerName);
  late final _address = TextEditingController(text: widget.existing?.address);
  late final _territory =
      TextEditingController(text: widget.existing?.territory);
  late final _rep =
      TextEditingController(text: widget.existing?.assignedRepName);
  late final _revenue = TextEditingController(
      text: widget.existing?.expectedRevenue.toStringAsFixed(0) ?? '');

  // State for the upgraded PhoneFormField
  PhoneNumber? _phoneValue;

  late LeadSource _source =
      widget.existing?.leadSource ?? LeadSource.fieldVisit;
  late Priority _priority = widget.existing?.priority ?? Priority.medium;
  late final List<String> _products =
      List.of(widget.existing?.interestedProducts ?? const []);

  bool get _isEdit => widget.existing != null;
  bool _showMore = false;

  @override
  void initState() {
    super.initState();
    // Parse existing plain phone string to PhoneNumber initialization object safely
    if (widget.existing?.phone != null && widget.existing!.phone.isNotEmpty) {
      try {
        _phoneValue = PhoneNumber.parse(widget.existing!.phone);
      } catch (_) {
        _phoneValue = null;
      }
    }
  }

  @override
  void dispose() {
    for (final c in [_company, _owner, _address, _territory, _rep, _revenue]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return Padding(
      // Handled using your custom context device insets helper extension
      padding: EdgeInsets.only(bottom: context.deviceInsets.keyboard),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row Header containing Title and new explicit Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_isEdit ? 'Edit lead' : 'New lead',
                                style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800)),
                            if (!_isEdit) ...[
                              const SizedBox(height: 4),
                              Text(
                                  "That's enough to start — don't grill a cold lead.",
                                  style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 12.5)),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        color: colors.textSecondary,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _field('Company / Shop name', _company, required: true),

                  // Upgraded PhoneFormField styled natively to match theme specs
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PhoneFormField(
                      initialValue: _phoneValue,
                      onChanged: (value) => setState(() => _phoneValue = value),
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                      // Always strictly required validation format execution rule
                      validator: (v) {
                        if (v == null || v.nsn.trim().isEmpty) {
                          return 'Required';
                        }
                        if (!v.isValid()) {
                          return 'Invalid phone number';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        label: const Text.rich(
                          TextSpan(
                            text: 'Phone',
                            children: [
                              TextSpan(
                                text: ' *',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
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
                  ),

                  const SizedBox(height: 4),
                  Text('Interested products (optional)',
                      style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _productOptions
                        .map((p) => FilterChip(
                              label: Text(p),
                              selected: _products.contains(p),
                              onSelected: (selected) => setState(() => selected
                                  ? _products.add(p)
                                  : _products.remove(p)),
                              labelStyle: TextStyle(
                                  color: _products.contains(p)
                                      ? scheme.primary
                                      : colors.textPrimary,
                                  fontSize: 12.5),
                              backgroundColor: colors.card,
                              selectedColor:
                                  scheme.primary.withValues(alpha: 0.2),
                              side: BorderSide(
                                  color: _products.contains(p)
                                      ? scheme.primary
                                      : colors.border),
                            ))
                        .toList(),
                  ),
                  if (!_isEdit && !_showMore) ...[
                    const SizedBox(height: 14),
                    TextButton.icon(
                      onPressed: () => setState(() => _showMore = true),
                      icon: Icon(Icons.add_rounded,
                          size: 16, color: scheme.primary),
                      label: Text('Add more details',
                          style:
                              TextStyle(color: scheme.primary, fontSize: 13)),
                    ),
                  ],
                  if (_isEdit || _showMore) ...[
                    const SizedBox(height: 8),
                    _field('Owner name', _owner),
                    _field('Address', _address),
                    _field('Territory / Province', _territory),
                    _field('Assigned sales rep', _rep),
                    _field('Expected revenue (\$)', _revenue,
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 8),
                    Text('Lead source',
                        style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: LeadSource.values
                          .map((s) => ChoiceChip(
                                label: Text(s.label),
                                selected: _source == s,
                                onSelected: (_) => setState(() => _source = s),
                                labelStyle: TextStyle(
                                    color: _source == s
                                        ? scheme.primary
                                        : colors.textPrimary,
                                    fontSize: 12),
                                backgroundColor: colors.card,
                                selectedColor:
                                    scheme.primary.withValues(alpha: 0.2),
                                side: BorderSide(
                                    color: _source == s
                                        ? scheme.primary
                                        : colors.border),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    Text('Priority',
                        style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: Priority.values
                          .map((p) => ChoiceChip(
                                label: Text(p.label),
                                selected: _priority == p,
                                onSelected: (_) =>
                                    setState(() => _priority = p),
                                labelStyle: TextStyle(
                                    color: _priority == p
                                        ? scheme.primary
                                        : colors.textPrimary,
                                    fontSize: 12),
                                backgroundColor: colors.card,
                                selectedColor:
                                    scheme.primary.withValues(alpha: 0.2),
                                side: BorderSide(
                                    color: _priority == p
                                        ? scheme.primary
                                        : colors.border),
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(_isEdit ? 'Save changes' : 'Create lead',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
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

  Widget _field(String label, TextEditingController controller,
      {bool required = false, TextInputType? keyboardType}) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: colors.textPrimary, fontSize: 14),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
        decoration: InputDecoration(
          label: Text.rich(
            TextSpan(
              text: label,
              children: required
                  ? const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red),
                      ),
                    ]
                  : null,
            ),
          ),
          labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
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
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final revenue = double.tryParse(_revenue.text.trim()) ?? 0;
    final base = widget.existing;

    // Extract format option string from PhoneNumber configuration model
    final phoneString = _phoneValue?.international ?? '';

    final lead = base == null
        ? Lead(
            id: 'LEAD-${DateTime.now().microsecondsSinceEpoch}',
            companyName: _company.text.trim(),
            ownerName: _owner.text.trim(),
            phone: phoneString,
            email: '',
            address: _address.text.trim(),
            province: _territory.text.trim(),
            district: '',
            latitude: 11.5564,
            longitude: 104.9282,
            storefrontImageUrl: '',
            businessRegistrationNumber: '',
            taxId: '',
            leadSource: _source,
            createdDate: DateTime.now(),
            expectedRevenue: revenue,
            currentRevenue: 0,
            assignedRepName: _rep.text.trim(),
            creditLimit: 0,
            creditStatus: CreditStatus.notApplicable,
            stage: PipelineStage.leads,
            priority: _priority,
            industry: 'Steel Distribution',
            territory: _territory.text.trim(),
            interestedProducts: _products,
          )
        : Lead(
            id: base.id,
            companyName: _company.text.trim(),
            ownerName: _owner.text.trim(),
            phone: phoneString,
            email: base.email,
            address: _address.text.trim(),
            province: base.province,
            district: base.district,
            latitude: base.latitude,
            longitude: base.longitude,
            storefrontImageUrl: base.storefrontImageUrl,
            businessRegistrationNumber: base.businessRegistrationNumber,
            taxId: base.taxId,
            leadSource: _source,
            createdDate: base.createdDate,
            expectedRevenue: revenue,
            currentRevenue: base.currentRevenue,
            assignedRepName: _rep.text.trim(),
            creditLimit: base.creditLimit,
            creditStatus: base.creditStatus,
            stage: base.stage,
            priority: _priority,
            industry: base.industry,
            territory: _territory.text.trim(),
            interestedProducts: _products,
            notes: base.notes,
            contacts: base.contacts,
            documents: base.documents,
            opportunityInfo: base.opportunityInfo,
            wonInfo: base.wonInfo,
          );

    Navigator.of(context).pop(lead);
  }
}
