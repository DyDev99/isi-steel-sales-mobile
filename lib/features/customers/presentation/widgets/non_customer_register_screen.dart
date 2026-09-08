import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/datasources/non_customer_demo_data.dart';

/// Registers a party that buys through one of our SAP customers.
///
/// **Demo only.** Nothing is validated against the server, nothing is saved and
/// nothing reaches SAP. Save shows a confirmation and pops.
///
/// **Why this form is short.** Customer registration collects a business-partner
/// block, a sales area, credit terms and five photographs, because SAP will
/// refuse to create a customer master without them. None of that applies here:
/// a non-customer is never invoiced, so there is no ledger to place them in and
/// no ERP record to keep in step. Asking for it anyway would be a ten-minute
/// form for a record that carries no commercial weight — and a rep standing in
/// a yard would simply not fill it in.
///
/// What is left is identity and one link. The link is the point: it decides
/// which dealer's volume this party's purchases roll up to.
class NonCustomerRegisterScreen extends StatefulWidget {
  const NonCustomerRegisterScreen({super.key});

  static const routeName = 'non-customer-register';

  @override
  State<NonCustomerRegisterScreen> createState() =>
      _NonCustomerRegisterScreenState();
}

class _NonCustomerRegisterScreenState extends State<NonCustomerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _identityController = TextEditingController();
  final _locationController = TextEditingController();
  final _noteController = TextEditingController();

  NonCustomerKind _kind = NonCustomerKind.subDealer;
  LinkableCustomerDemo? _linkedCustomer;

  /// Set when Save is pressed without a linked customer.
  ///
  /// Tracked separately from the form's own validators because the link is not
  /// a text field — a `FormField` wrapper would work and would put a validation
  /// concern inside a picker that has no other reason to know about forms.
  bool _linkMissing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _identityController.dispose();
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickLinkedCustomer() async {
    final picked = await showModalBottomSheet<LinkableCustomerDemo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LinkedCustomerPicker(),
    );

    if (picked != null && mounted) {
      setState(() {
        _linkedCustomer = picked;
        _linkMissing = false;
      });
    }
  }

  void _submit() {
    final formValid = _formKey.currentState?.validate() ?? false;
    final linkChosen = _linkedCustomer != null;

    setState(() => _linkMissing = !linkChosen);

    if (!formValid || !linkChosen) {
      // Both are checked before returning so a rep missing two things is told
      // about two things. Reporting the first failure only means a second
      // round trip through the form for a fault that was already visible.
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demo screen — nothing was saved.'),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Register Non Customer'),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              context.rw(16),
              context.rh(12),
              context.rw(16),
              context.rh(24),
            ),
            children: [
              const _DemoNotice(),
              SizedBox(height: context.rh(20)),

              // Identity first. It is what the rep is looking at while they
              // type, and a form that opens on an abstract classification
              // before the name reads as paperwork rather than a record of
              // somebody standing in front of them.
              const _SectionLabel('Identity'),
              SizedBox(height: context.rh(10)),
              _Field(
                label: 'Name',
                required: true,
                controller: _nameController,
                hint: 'Shop, company or person',
                textCapitalization: TextCapitalization.words,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'A name is required'
                    : null,
              ),
              SizedBox(height: context.rh(14)),
              _KindPicker(
                selected: _kind,
                onChanged: (kind) => setState(() => _kind = kind),
              ),
              SizedBox(height: context.rh(14)),
              _Field(
                label: 'Phone',
                required: true,
                controller: _phoneController,
                hint: '012 345 678',
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                ],
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'A phone number is required'
                    : null,
              ),
              SizedBox(height: context.rh(14)),
              _Field(
                label: 'ID or licence number',
                controller: _identityController,
                hint: 'National ID, or business licence',
                // Optional, and said so on the label rather than only in a
                // validator. A sub-dealer met at a roadside yard often will not
                // produce one, and a required field here means the record is
                // never created at all — worse than a record without an ID.
                helper: 'Optional. Leave blank if none was shown.',
              ),
              SizedBox(height: context.rh(14)),
              _Field(
                label: 'Location',
                required: true,
                controller: _locationController,
                hint: 'District, province',
                textCapitalization: TextCapitalization.words,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'A location is required'
                    : null,
              ),

              SizedBox(height: context.rh(26)),
              const _SectionLabel('Linked SAP customer'),
              SizedBox(height: context.rh(6)),
              Text(
                'Purchases by this party are counted against the customer you '
                'pick here. Without it the record has nowhere to report to.',
                style: TextStyle(
                  fontSize: context.rsp(11.5),
                  height: 1.4,
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(height: context.rh(10)),
              _LinkedCustomerField(
                customer: _linkedCustomer,
                showError: _linkMissing,
                onTap: _pickLinkedCustomer,
              ),

              SizedBox(height: context.rh(26)),
              const _SectionLabel('Note'),
              SizedBox(height: context.rh(10)),
              _Field(
                label: 'What they buy',
                controller: _noteController,
                hint: 'Roofing sheet weekly, rebar for a project…',
                maxLines: 3,
                helper: 'Optional.',
              ),

              SizedBox(height: context.rh(28)),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: context.rh(15)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save non customer',
                    style: TextStyle(
                      fontSize: context.rsp(14),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Says the screen is a demo, once, at the top.
class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(context.rr(12)),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: context.rr(16),
            color: scheme.primary,
          ),
          SizedBox(width: context.rw(8)),
          Expanded(
            child: Text(
              'Demo screen. Nothing entered here is saved or sent to SAP.',
              style: TextStyle(
                fontSize: context.rsp(11.5),
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: context.rsp(11),
        fontWeight: FontWeight.w900,
        letterSpacing: 0.7,
        color: context.appColors.textPrimary,
      ),
    );
  }
}

/// A labelled text field matching the create-customer form's decoration.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.helper,
    this.required = false,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? helper;
  final bool required;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: context.rsp(12),
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: TextStyle(
                  fontSize: context.rsp(12),
                  fontWeight: FontWeight.w700,
                  color: scheme.error,
                ),
              ),
          ],
        ),
        SizedBox(height: context.rh(6)),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          validator: validator,
          style: TextStyle(
            fontSize: context.rsp(14),
            color: colors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            helperStyle: TextStyle(
              fontSize: context.rsp(10.5),
              color: colors.textSecondary,
            ),
            hintStyle: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.3),
              fontSize: context.rsp(14),
            ),
            filled: true,
            fillColor: colors.surfaceSoft,
            contentPadding: EdgeInsets.symmetric(
              horizontal: context.rw(14),
              vertical: context.rh(14),
            ),
            enabledBorder: border(colors.border),
            focusedBorder: border(scheme.onSurface),
            errorBorder: border(scheme.error),
            focusedErrorBorder: border(scheme.error),
          ),
        ),
      ],
    );
  }
}

/// Picks what kind of party this is.
class _KindPicker extends StatelessWidget {
  const _KindPicker({required this.selected, required this.onChanged});

  final NonCustomerKind selected;
  final ValueChanged<NonCustomerKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type',
          style: TextStyle(
            fontSize: context.rsp(12),
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: context.rh(8)),
        Wrap(
          spacing: context.rw(8),
          runSpacing: context.rh(8),
          children: [
            for (final kind in NonCustomerKind.values)
              InkWell(
                onTap: () => onChanged(kind),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.rw(12),
                    vertical: context.rh(8),
                  ),
                  decoration: BoxDecoration(
                    color:
                        kind == selected ? scheme.primary : colors.surfaceSoft,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: kind == selected ? scheme.primary : colors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        kind.icon,
                        size: context.rr(14),
                        color: kind == selected
                            ? scheme.onPrimary
                            : colors.textSecondary,
                      ),
                      SizedBox(width: context.rw(6)),
                      Text(
                        kind.label,
                        style: TextStyle(
                          fontSize: context.rsp(12),
                          fontWeight: FontWeight.w700,
                          color: kind == selected
                              ? scheme.onPrimary
                              : colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Shows the chosen SAP customer, or invites the rep to pick one.
class _LinkedCustomerField extends StatelessWidget {
  const _LinkedCustomerField({
    required this.customer,
    required this.showError,
    required this.onTap,
  });

  final LinkableCustomerDemo? customer;
  final bool showError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final chosen = customer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(context.rr(14)),
            decoration: BoxDecoration(
              color: colors.surfaceSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: showError ? scheme.error : colors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.link_rounded,
                  size: context.rr(18),
                  color: chosen == null ? colors.textSecondary : scheme.primary,
                ),
                SizedBox(width: context.rw(10)),
                Expanded(
                  child: chosen == null
                      ? Text(
                          'Choose a customer',
                          style: TextStyle(
                            fontSize: context.rsp(14),
                            color: scheme.onSurface.withValues(alpha: 0.35),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chosen.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: context.rsp(14),
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            SizedBox(height: context.rh(2)),
                            Text(
                              '${chosen.code} · ${chosen.territory}',
                              style: TextStyle(
                                fontSize: context.rsp(11.5),
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: context.rr(20),
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (showError) ...[
          SizedBox(height: context.rh(6)),
          Text(
            'Pick the customer this party buys through',
            style: TextStyle(
              fontSize: context.rsp(11),
              color: scheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// Bottom sheet listing the SAP customers a non-customer can point at.
class _LinkedCustomerPicker extends StatefulWidget {
  const _LinkedCustomerPicker();

  @override
  State<_LinkedCustomerPicker> createState() => _LinkedCustomerPickerState();
}

class _LinkedCustomerPickerState extends State<_LinkedCustomerPicker> {
  String _query = '';

  List<LinkableCustomerDemo> get _results {
    final term = _query.trim().toLowerCase();
    if (term.isEmpty) return demoLinkableCustomers;

    return demoLinkableCustomers
        .where((c) =>
            c.name.toLowerCase().contains(term) ||
            c.code.toLowerCase().contains(term))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final results = _results;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
      decoration: BoxDecoration(
        color: colors.canvas,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: context.rh(10)),
          Container(
            width: context.rw(40),
            height: context.rh(4),
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.rw(16),
              context.rh(16),
              context.rw(16),
              context.rh(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Link to customer',
                  style: TextStyle(
                    fontSize: context.rsp(16),
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: context.rh(12)),
                TextField(
                  autofocus: false,
                  onChanged: (value) => setState(() => _query = value),
                  style: TextStyle(
                    fontSize: context.rsp(14),
                    color: colors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search name or code',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: context.rr(18),
                      color: colors.textSecondary,
                    ),
                    hintStyle: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.3),
                      fontSize: context.rsp(14),
                    ),
                    filled: true,
                    fillColor: colors.surfaceSoft,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: context.rh(12)),
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
              ],
            ),
          ),
          Flexible(
            child: results.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(context.rr(28)),
                    child: Text(
                      'No customer matches that.',
                      style: TextStyle(
                        fontSize: context.rsp(13),
                        color: colors.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.fromLTRB(
                      context.rw(16),
                      0,
                      context.rw(16),
                      context.rh(24),
                    ),
                    itemCount: results.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(height: context.rh(8)),
                    itemBuilder: (context, index) {
                      final customer = results[index];
                      return InkWell(
                        onTap: () => Navigator.of(context).pop(customer),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.all(context.rr(12)),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      customer.code,
                                      style: TextStyle(
                                        fontSize: context.rsp(11),
                                        fontWeight: FontWeight.w700,
                                        color: scheme.primary,
                                      ),
                                    ),
                                    SizedBox(height: context.rh(2)),
                                    Text(
                                      customer.name,
                                      style: TextStyle(
                                        fontSize: context.rsp(14),
                                        fontWeight: FontWeight.w700,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: context.rh(2)),
                                    Text(
                                      customer.territory,
                                      style: TextStyle(
                                        fontSize: context.rsp(11.5),
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: context.rr(20),
                                color: colors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
