import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phone_form_field/phone_form_field.dart';

import 'package:isi_steel_sales_mobile/core/device/device_insets.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_text_context.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/add_customer_bloc.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/app_bottom_sheet.dart';

void showAddCustomerSheet(
  BuildContext context, {
  required List<Lead> wonLeads,
}) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  final isTablet = screenWidth >= 600;

  if (isTablet) {
    // showGeneralDialog completely overrides bottom sheet max-width constraints
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AddCustomerSheet',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              // Was `double.infinity`, which is what the comment above means by
              // overriding the sheet's max width — on a 1032pt iPad this form
              // spanned the whole screen and put Cancel and Save ~700pt apart.
              // Capped to the same measure every other sheet uses; `Align`
              // above centres it (FS-UX-3, FS-RSP-5).
              width: AppBottomSheet.maxWidth,
              height: MediaQuery.sizeOf(context).height * 0.9,
              child: AddCustomerBottomSheet(
                wonLeads: wonLeads,
                isTablet: true,
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
      },
    );
  } else {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      // Was `double.infinity` on both axes, which spanned the whole 1032pt of
      // an iPad and left this form's Cancel and Save ~700pt apart. Capped and
      // centred like every other sheet (FS-UX-3, FS-RSP-5).
      constraints: const BoxConstraints(maxWidth: AppBottomSheet.maxWidth),
      builder: (BuildContext modalContext) {
        return AddCustomerBottomSheet(
          wonLeads: wonLeads,
          isTablet: false,
        );
      },
    );
  }
}

class AddCustomerBottomSheet extends StatefulWidget {
  final List<Lead> wonLeads;
  final bool isTablet;

  const AddCustomerBottomSheet({
    super.key,
    required this.wonLeads,
    this.isTablet = false,
  });

  @override
  State<AddCustomerBottomSheet> createState() => _AddCustomerBottomSheetState();
}

class _AddCustomerBottomSheetState extends State<AddCustomerBottomSheet> {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  late TextEditingController _shopNameCtrl;
  late TextEditingController _ownerNameCtrl;
  late TextEditingController _contactNameCtrl;
  late PhoneController _phoneCtrl;

  Lead? _selectedLead;
  String? _selectedShopType;
  String? _selectedRole;

  String _gpsCoords = "";
  String _licenceFile = "";
  String _patentFile = "";

  // Helper to ensure text and dimensions remain legible on larger screens
  double _fontSize(double basePhoneSize) {
    return widget.isTablet ? basePhoneSize * 1.25 : context.rsp(basePhoneSize);
  }

  double _spacing(double basePhoneSize) {
    return widget.isTablet ? basePhoneSize * 1.2 : context.rh(basePhoneSize);
  }

  @override
  void initState() {
    super.initState();
    _shopNameCtrl = TextEditingController();
    _ownerNameCtrl = TextEditingController();
    _contactNameCtrl = TextEditingController();

    _phoneCtrl = PhoneController(
      initialValue: const PhoneNumber(isoCode: IsoCode.KH, nsn: ''),
    );
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _contactNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocProvider<AddCustomerBloc>(
      create: (context) => sl<AddCustomerBloc>(),
      child: BlocConsumer<AddCustomerBloc, AddCustomerState>(
        listener: (context, state) {
          if (state.status == AddCustomerStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('add_customer.success'.tr)),
            );
            if (context.mounted) {
              Navigator.pop(context);
            }
          }
        },
        builder: (context, state) {
          final content = Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(widget.isTablet ? 24 : context.rr(28)),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              widget.isTablet ? 36 : context.rw(24),
              widget.isTablet ? 24 : context.rh(16),
              widget.isTablet ? 36 : context.rw(24),
              widget.isTablet
                  ? 32
                  : context.deviceInsets.sheetBottomInset(
                      extra: context.rh(24),
                    ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: widget.isTablet ? 60 : context.rw(42),
                    height: widget.isTablet ? 6 : context.rh(5),
                    decoration: BoxDecoration(
                      color: context.appColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: _spacing(12)),
                _buildFormHeader(state),
                SizedBox(height: _spacing(24)),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      child: state.status == AddCustomerStatus.submitting
                          ? Center(
                              key: const ValueKey('submitting_loader'),
                              child: Padding(
                                padding: EdgeInsets.all(_spacing(40)),
                                child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            )
                          : _showsAllSteps
                              ? _buildAllStepsBody()
                              : KeyedSubtree(
                                  key: ValueKey(state.currentStep),
                                  child: _buildActiveStepBody(state),
                                ),
                    ),
                  ),
                ),
                SizedBox(height: _spacing(24)),
                _buildFormNavigationActionButtons(context, state),
              ],
            ),
          );

          return AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: bottomInset),
            child: SizedBox(
              width: double.infinity,
              child: content,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormHeader(AddCustomerState state) {
    String title = 'add_customer.steps.shop_details'.tr;
    int stepNumber = 1;

    if (state.currentStep == CustomerFormStep.contactPerson) {
      title = 'add_customer.steps.contact_person'.tr;
      stepNumber = 2;
    } else if (state.currentStep == CustomerFormStep.locationAndPapers) {
      title = 'add_customer.steps.location_papers'.tr;
      stepNumber = 3;
    }

    // With every step on screen there is no "current" step to name, and a
    // "Step 1 of 3" counter next to three visible steps is actively confusing.
    // Each column carries its own heading instead (see _buildAllStepsBody).
    if (_showsAllSteps) {
      title = 'add_customer.title'.tr;
    }

    final stepText = 'add_customer.step_indicator'
        .tr
        .replaceAll('{current}', '$stepNumber')
        .replaceAll('{total}', '3');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                title,
                key: ValueKey(title),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: _fontSize(24),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'add_customer.subtitle'.tr,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
                fontSize: _fontSize(14),
              ),
            ),
          ],
        ),
        if (!_showsAllSteps)
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isTablet ? 20 : context.rw(16),
            vertical: widget.isTablet ? 10 : context.rh(8),
          ),
          decoration: BoxDecoration(
            color: context.appColors.surfaceSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.appColors.border),
          ),
          child: Text(
            stepText,
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: _fontSize(14),
              fontWeight: FontWeight.w800,
            ),
          ),
        )
      ],
    );
  }

  /// How many form steps are shown at once.
  ///
  /// The form has three steps. On a phone they are a stepper — one at a time —
  /// which is unchanged. A tablet has the width to show them together, so the
  /// rep fills the whole customer record on one surface instead of paging
  /// through it three times. Column count follows available width, not device
  /// type (FS-RSP-1); at `medium` the third step wraps onto a second row, so
  /// every step is still visible, just in two columns rather than three.
  int get _stepColumns => context.responsive(compact: 1, medium: 2, expanded: 3);

  bool get _showsAllSteps => _stepColumns > 1;

  Widget _buildActiveStepBody(AddCustomerState state) =>
      _buildStepBody(state.currentStep);

  Widget _buildStepBody(CustomerFormStep step) {
    switch (step) {
      case CustomerFormStep.shopDetails:
        return Form(
          key: _formKey1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputLabel('shell.select_won_lead'.tr, required: true),
              _buildLeadDropdownField(),
              if (_selectedLead != null) ...[
                SizedBox(height: _spacing(6)),
                Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: _fontSize(16),
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'add_customer.prefilled_editable_hint'.tr,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4),
                          fontSize: _fontSize(13),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: _spacing(18)),
              _buildInputLabel('add_customer.shop_name'.tr, required: true),
              _buildTextField(_shopNameCtrl, 'add_customer.shop_name_hint'.tr),
              SizedBox(height: _spacing(18)),
              _buildInputLabel('add_customer.shop_type'.tr, required: true),
              _buildDropdownField(
                value: _selectedShopType,
                hint: 'add_customer.pick_one'.tr,
                items: {
                  'hardware_shop': 'add_customer.shop_types.hardware_shop'.tr,
                  'retailer': 'add_customer.shop_types.retailer'.tr,
                  'wholesaler': 'add_customer.shop_types.wholesaler'.tr,
                  'project_contractor':
                      'add_customer.shop_types.project_contractor'.tr,
                },
                onChanged: (val) => setState(() => _selectedShopType = val),
              ),
              SizedBox(height: _spacing(18)),
              _buildInputLabel('add_customer.owner_name'.tr, required: true),
              _buildTextField(_ownerNameCtrl, 'add_customer.owner_name_hint'.tr),
            ],
          ),
        );

      case CustomerFormStep.contactPerson:
        return Form(
          key: _formKey2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputLabel('add_customer.contact_name'.tr, required: true),
              _buildTextField(
                  _contactNameCtrl, 'add_customer.contact_name_hint'.tr),
              SizedBox(height: _spacing(18)),
              _buildInputLabel('add_customer.role'.tr, required: true),
              _buildDropdownField(
                value: _selectedRole,
                hint: 'add_customer.pick_one'.tr,
                items: {
                  'owner': 'add_customer.roles.owner'.tr,
                  'manager': 'add_customer.roles.manager'.tr,
                  'buyer': 'add_customer.roles.buyer'.tr,
                },
                onChanged: (val) => setState(() => _selectedRole = val),
              ),
              SizedBox(height: _spacing(18)),
              _buildInputLabel('add_customer.phone'.tr, required: true),
              _buildPhoneField(_phoneCtrl, 'add_customer.phone_hint'.tr),
            ],
          ),
        );

      case CustomerFormStep.locationAndPapers:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputLabel('add_customer.telemetry'.tr),
            _buildActionTriggerTile(
              label: _gpsCoords.isEmpty
                  ? 'add_customer.gps_save'.tr
                  : 'add_customer.gps_verified'.tr,
              sub: _gpsCoords.isEmpty ? 'add_customer.gps_hint'.tr : _gpsCoords,
              icon: Icons.location_on_rounded,
              completed: _gpsCoords.isNotEmpty,
              onTap: () =>
                  setState(() => _gpsCoords = "11.5564° N, 104.9282° E"),
            ),
            SizedBox(height: _spacing(18)),
            _buildInputLabel('add_customer.compliance'.tr),
            _buildActionTriggerTile(
              label: 'add_customer.licence'.tr,
              sub: _licenceFile.isEmpty
                  ? 'add_customer.licence_hint'.tr
                  : 'add_customer.licence_attached'.tr,
              icon: Icons.assignment_rounded,
              completed: _licenceFile.isNotEmpty,
              onTap: () => setState(() => _licenceFile = "lic_reg_corp.jpg"),
            ),
            SizedBox(height: _spacing(12)),
            _buildActionTriggerTile(
              label: 'add_customer.tax_paper'.tr,
              sub: _patentFile.isEmpty
                  ? 'add_customer.tax_paper_hint'.tr
                  : 'add_customer.tax_paper_attached'.tr,
              icon: Icons.receipt_long_rounded,
              completed: _patentFile.isNotEmpty,
              onTap: () => setState(() => _patentFile = "national_patent.jpg"),
            ),
            SizedBox(height: _spacing(20)),
            Container(
              padding: EdgeInsets.all(widget.isTablet ? 20 : context.rw(16)),
              decoration: BoxDecoration(
                color: context.appColors.warningAlt.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: context.appColors.warningAlt.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: context.appColors.warningAlt,
                    size: _fontSize(24),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'add_customer.credit_notice'.tr,
                      style: TextStyle(
                        color: context.appColors.warningAlt,
                        fontSize: _fontSize(14),
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  String _stepTitle(CustomerFormStep step) => switch (step) {
        CustomerFormStep.shopDetails => 'add_customer.steps.shop_details'.tr,
        CustomerFormStep.contactPerson => 'add_customer.steps.contact_person'.tr,
        CustomerFormStep.locationAndPapers =>
          'add_customer.steps.location_papers'.tr,
      };

  /// All three steps at once, in [_stepColumns] columns.
  ///
  /// `Wrap` rather than a fixed `Row`: at two columns the third step needs to
  /// fall onto a second line, and Wrap does that without a second layout path.
  /// The item width is computed from the real constraints instead of a
  /// fraction of the screen, so this stays correct inside a sheet that is
  /// itself inset by the keyboard.
  Widget _buildAllStepsBody() {
    const steps = CustomerFormStep.values;
    final gap = context.rw(24);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _stepColumns;
        final itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: context.rh(24),
          children: [
            for (final step in steps)
              SizedBox(
                width: itemWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _stepTitle(step),
                      style: TextStyle(
                        fontSize: _fontSize(16),
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: _spacing(12)),
                    _buildStepBody(step),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  /// Validates and commits every step, for the all-steps-visible layout.
  ///
  /// The stepper path commits each step as the rep advances past it; with all
  /// steps on screen there is no "advance", so the same three events fire
  /// together on submit. Returns false if either form fails, leaving the
  /// inline validation messages to explain why.
  bool _commitAllSteps(AddCustomerBloc bloc) {
    final valid = (_formKey1.currentState?.validate() ?? false) &&
        (_formKey2.currentState?.validate() ?? false) &&
        _selectedShopType != null &&
        _selectedRole != null;
    if (!valid) return false;

    bloc.add(UpdateShopDetails(
      shopName: _shopNameCtrl.text,
      shopType: _selectedShopType!,
      ownerName: _ownerNameCtrl.text,
    ));
    bloc.add(UpdateContactDetails(
      name: _contactNameCtrl.text,
      role: _selectedRole!,
      phone: _phoneCtrl.value.international,
    ));
    bloc.add(UpdateLocationAndPapers(
      gpsLocation: _gpsCoords,
      businessLicencePath: _licenceFile,
      taxPaperPath: _patentFile,
    ));
    return true;
  }

  Widget _buildFormNavigationActionButtons(
      BuildContext context, AddCustomerState state) {
    final bloc = context.read<AddCustomerBloc>();
    // With every step visible there is nothing to page through: the Back arrow
    // has no meaning and the primary action always submits.
    final isFirstStep =
        _showsAllSteps || state.currentStep == CustomerFormStep.shopDetails;
    final isLastStep = _showsAllSteps ||
        state.currentStep == CustomerFormStep.locationAndPapers;

    final btnPadding = widget.isTablet
        ? const EdgeInsets.symmetric(vertical: 22)
        : EdgeInsets.symmetric(vertical: context.rh(18));

    return Row(
      children: [
        if (!isFirstStep) ...[
          Expanded(
            flex: 1,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: btnPadding,
                side: BorderSide(color: context.appColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => bloc.add(PreviousStep()),
              child: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.onSurface,
                size: _fontSize(24),
              ),
            ),
          ),
          SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: btnPadding,
              backgroundColor: isLastStep
                  ? context.appColors.success
                  : Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            onPressed: () {
              if (_showsAllSteps) {
                if (_commitAllSteps(bloc)) bloc.add(SubmitToHQ());
              } else if (state.currentStep == CustomerFormStep.shopDetails) {
                if (_formKey1.currentState!.validate() &&
                    _selectedShopType != null) {
                  bloc.add(UpdateShopDetails(
                    shopName: _shopNameCtrl.text,
                    shopType: _selectedShopType!,
                    ownerName: _ownerNameCtrl.text,
                  ));
                  bloc.add(NextStep());
                }
              } else if (state.currentStep == CustomerFormStep.contactPerson) {
                if (_formKey2.currentState!.validate() &&
                    _selectedRole != null) {
                  bloc.add(UpdateContactDetails(
                    name: _contactNameCtrl.text,
                    role: _selectedRole!,
                    phone: _phoneCtrl.value.international,
                  ));
                  bloc.add(NextStep());
                }
              } else if (isLastStep) {
                bloc.add(UpdateLocationAndPapers(
                  gpsLocation: _gpsCoords,
                  businessLicencePath: _licenceFile,
                  taxPaperPath: _patentFile,
                ));
                bloc.add(SubmitToHQ());
              }
            },
            child: Text(
              isLastStep
                  ? 'add_customer.send_to_hq'.tr
                  : 'add_customer.next_step'.tr,
              style: TextStyle(
                color: isLastStep
                    ? Colors.white
                    : Theme.of(context).colorScheme.surface,
                fontSize: _fontSize(16),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeadDropdownField() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isTablet ? 20 : context.rw(16),
        vertical: widget.isTablet ? 12 : context.rh(6),
      ),
      decoration: BoxDecoration(
        color: context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Lead>(
          value: _selectedLead,
          hint: Text(
            'add_customer.pick_one'.tr,
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
              fontSize: _fontSize(15),
            ),
          ),
          dropdownColor: context.appColors.surfaceSoft,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Theme.of(context).colorScheme.onSurface,
            size: _fontSize(24),
          ),
          isExpanded: true,
          items: widget.wonLeads.map((lead) {
            return DropdownMenuItem<Lead>(
              value: lead,
              child: Text(
                context.localized(lead.displayName),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: _fontSize(15),
                ),
              ),
            );
          }).toList(),
          onChanged: (Lead? lead) {
            setState(() {
              _selectedLead = lead;
              if (lead != null) {
                _shopNameCtrl.text = lead.companyName;
                _ownerNameCtrl.text = lead.ownerName;
                _contactNameCtrl.text = lead.ownerName;
                _selectedShopType = 'hardware_shop';
                _selectedRole = 'owner';
              }
            });
          },
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label, {bool required = false}) => Padding(
        padding: EdgeInsets.only(bottom: 8, left: 2),
        child: RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: _fontSize(15),
              fontWeight: FontWeight.w700,
            ),
            children: required
                ? [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: _fontSize(15),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ]
                : null,
          ),
        ),
      );

  Widget _buildTextField(TextEditingController controller, String hint,
          {bool readOnly = false,
          TextInputType keyboardType = TextInputType.text}) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        style: TextStyle(
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: readOnly ? 0.6 : 1.0),
          fontSize: _fontSize(15),
        ),
        validator: (v) => (v == null || v.trim().isEmpty)
            ? 'add_customer.error.required'.tr
            : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.3),
            fontSize: _fontSize(15),
          ),
          filled: true,
          fillColor: readOnly
              ? context.appColors.border.withValues(alpha: 0.2)
              : context.appColors.surfaceSoft,
          contentPadding: EdgeInsets.symmetric(
            horizontal: widget.isTablet ? 20 : context.rw(16),
            vertical: widget.isTablet ? 20 : context.rh(16),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.appColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      );

  Widget _buildPhoneField(PhoneController controller, String hint,
          {bool readOnly = false}) =>
      PhoneFormField(
        controller: controller,
        enabled: !readOnly,
        style: TextStyle(
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: readOnly ? 0.6 : 1.0),
          fontSize: _fontSize(15),
        ),
        countryButtonStyle: CountryButtonStyle(
          showFlag: true,
          showIsoCode: false,
          showDialCode: true,
          showDropdownIcon: !readOnly,
          textStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: _fontSize(15),
          ),
        ),
        validator: PhoneValidator.compose([
          PhoneValidator.required(context,
              errorText: 'add_customer.error.required'.tr),
          PhoneValidator.validMobile(context,
              errorText: 'add_customer.error.invalid_phone'.tr),
        ]),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.3),
            fontSize: _fontSize(15),
          ),
          filled: true,
          fillColor: readOnly
              ? context.appColors.border.withValues(alpha: 0.2)
              : context.appColors.surfaceSoft,
          contentPadding: EdgeInsets.symmetric(
            horizontal: widget.isTablet ? 20 : context.rw(16),
            vertical: widget.isTablet ? 20 : context.rh(16),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.appColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      );

  Widget _buildDropdownField({
    required String? value,
    required String hint,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
    bool isDisabled = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isTablet ? 20 : context.rw(16),
        vertical: widget.isTablet ? 12 : context.rh(6),
      ),
      decoration: BoxDecoration(
        color: isDisabled
            ? context.appColors.border.withValues(alpha: 0.2)
            : context.appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
              fontSize: _fontSize(15),
            ),
          ),
          dropdownColor: context.appColors.surfaceSoft,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Theme.of(context).colorScheme.onSurface,
            size: _fontSize(24),
          ),
          isExpanded: true,
          items: isDisabled
              ? (_selectedLead != null && value != null
                  ? [
                      DropdownMenuItem(
                        value: value,
                        child: Text(
                          items[value] ?? '',
                          style: TextStyle(fontSize: _fontSize(15)),
                        ),
                      )
                    ]
                  : null)
              : items.entries
                  .map((entry) => DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: _fontSize(15),
                          ),
                        ),
                      ))
                  .toList(),
          onChanged: isDisabled ? null : onChanged,
        ),
      ),
    );
  }

  Widget _buildActionTriggerTile({
    required String label,
    required String sub,
    required IconData icon,
    required bool completed,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(widget.isTablet ? 22 : context.rw(18)),
        decoration: BoxDecoration(
          color: completed
              ? context.appColors.success.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: completed
                ? context.appColors.success
                : context.appColors.border,
            width: completed ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: _fontSize(24),
              color: completed
                  ? context.appColors.success
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: _fontSize(16),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    sub,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                      fontSize: _fontSize(13),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              completed
                  ? Icons.check_circle_rounded
                  : Icons.add_a_photo_rounded,
              color: completed
                  ? context.appColors.success
                  : Theme.of(context).colorScheme.onSurface,
              size: _fontSize(24),
            ),
          ],
        ),
      ),
    );
  }
}