import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phone_form_field/phone_form_field.dart';

import 'package:isi_steel_sales_mobile/core/device/device_insets.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/add_customer_bloc.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/order_location_service.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/app_bottom_sheet.dart';

void showAddCustomerSheet(BuildContext context) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  final isTablet = screenWidth >= 600;

  if (isTablet) {
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
              width: AppBottomSheet.maxWidth,
              height: MediaQuery.sizeOf(context).height * 0.9,
              child: const AddCustomerBottomSheet(isTablet: true),
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
      constraints: const BoxConstraints(maxWidth: AppBottomSheet.maxWidth),
      builder: (BuildContext modalContext) {
        return const AddCustomerBottomSheet(
          isTablet: false,
        );
      },
    );
  }
}

class AddCustomerBottomSheet extends StatefulWidget {
  final bool isTablet;

  const AddCustomerBottomSheet({super.key, this.isTablet = false});

  @override
  State<AddCustomerBottomSheet> createState() => _AddCustomerBottomSheetState();
}

class _AddCustomerBottomSheetState extends State<AddCustomerBottomSheet> {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  // --- Form Controllers ---
  late TextEditingController _customerCodeCtrl;
  late TextEditingController _outletNameKhCtrl; // Outlet Name (KH)
  late TextEditingController _shopNameCtrl; // Outlet Name (EN)
  late TextEditingController _ownerNameCtrl; // Owner Name
  late TextEditingController _contactNameCtrl;
  late TextEditingController _addressCtrl; // Address
  late TextEditingController _cityCtrl;
  late PhoneController _phoneCtrl; // Phone Number

  String? _selectedShopType;
  String? _selectedRole;

  /// Display string for captured location fix (Lat/Long)
  String _gpsCoords = "";

  double? _latitude;
  double? _longitude;
  bool _capturingGps = false;

  // --- Photo Attachment Files ---
  String _outletPhotoFront = ""; // Photo of outlet (Front)
  String _outletPhotoInside = ""; // Photo of outlet (Inside)
  String _idCardPhoto = ""; // Photo of ID card
  String _patentTaxPhoto = ""; // Photo of Patent Tax (optional)

  double _fontSize(double basePhoneSize) {
    return widget.isTablet ? basePhoneSize * 1.25 : context.rsp(basePhoneSize);
  }

  double _spacing(double basePhoneSize) {
    return widget.isTablet ? basePhoneSize * 1.2 : context.rh(basePhoneSize);
  }

  @override
  void initState() {
    super.initState();
    _customerCodeCtrl = TextEditingController();
    _outletNameKhCtrl = TextEditingController();
    _shopNameCtrl = TextEditingController();
    _ownerNameCtrl = TextEditingController();
    _contactNameCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _cityCtrl = TextEditingController();

    _phoneCtrl = PhoneController(
      initialValue: const PhoneNumber(isoCode: IsoCode.KH, nsn: ''),
    );
  }

  Future<void> _captureGps() async {
    if (_capturingGps) return;
    setState(() => _capturingGps = true);
    final fix = await sl<OrderLocationService>().captureOnce();
    if (!mounted) return;

    setState(() {
      _capturingGps = false;
      if (fix == null) {
        _latitude = null;
        _longitude = null;
        _gpsCoords = "";
        return;
      }
      _latitude = fix.lat;
      _longitude = fix.lng;
      _gpsCoords =
          '${fix.lat.toStringAsFixed(5)}, ${fix.lng.toStringAsFixed(5)}';
    });

    if (fix == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('add_customer.gps_failed'.tr),
      ));
    }
  }

  @override
  void dispose() {
    _customerCodeCtrl.dispose();
    _outletNameKhCtrl.dispose();
    _shopNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _contactNameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
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
              widget.isTablet ? 36 : context.rw(16),
              widget.isTablet ? 24 : context.rh(16),
              widget.isTablet ? 36 : context.rw(16),
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
// Dragging the form dismisses the keyboard — same gesture as every
// other form in the app now.
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
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
                                  color:
                                      Theme.of(context).colorScheme.secondary,
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  title,
                  key: ValueKey(title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: _fontSize(22),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'add_customer.subtitle'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                  fontSize: _fontSize(13),
                ),
              ),
            ],
          ),
        ),
        if (!_showsAllSteps) ...[
          const SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.isTablet ? 20 : context.rw(12),
              vertical: widget.isTablet ? 10 : context.rh(6),
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
                fontSize: _fontSize(13),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    );
  }

  int get _stepColumns =>
      context.responsive(compact: 1, medium: 2, expanded: 3);

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
              _buildInputLabel('add_customer.customer_code'.tr, required: true),
              _buildTextField(
                  _customerCodeCtrl, 'add_customer.customer_code_hint'.tr),
              SizedBox(height: _spacing(18)),

              // Outlet Name (KH)
              _buildInputLabel('Outlet Name (KH)', required: true),
              _buildTextField(_outletNameKhCtrl, 'Enter outlet name in Khmer'),
              SizedBox(height: _spacing(18)),

              // Outlet Name (EN)
              _buildInputLabel('Outlet Name (EN)', required: true),
              _buildTextField(_shopNameCtrl, 'add_customer.shop_name_hint'.tr),
              SizedBox(height: _spacing(18)),

              _buildInputLabel('add_customer.shop_type'.tr, required: true),
              _buildDropdownField(
                value: _selectedShopType,
                hint: 'add_customer.pick_one'.tr,
                items: {
                  'Retailer': 'add_customer.shop_types.retailer'.tr,
                  'Wholesaler': 'add_customer.shop_types.wholesaler'.tr,
                  'Distributor': 'add_customer.shop_types.distributor'.tr,
                  'KeyAccount': 'add_customer.shop_types.key_account'.tr,
                },
                onChanged: (val) => setState(() => _selectedShopType = val),
              ),
              SizedBox(height: _spacing(18)),

              // Owner Name
              _buildInputLabel('Owner Name', required: true),
              _buildTextField(
                  _ownerNameCtrl, 'add_customer.owner_name_hint'.tr),
              SizedBox(height: _spacing(18)),

              // Address
              _buildInputLabel('Address', required: true),
              _buildTextField(_addressCtrl, 'add_customer.address_hint'.tr),
              SizedBox(height: _spacing(18)),

              _buildInputLabel('add_customer.city'.tr, required: true),
              _buildTextField(_cityCtrl, 'add_customer.city_hint'.tr),
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

              // Phone Number
              _buildInputLabel('Phone Number', required: true),
              _buildPhoneField(_phoneCtrl, 'add_customer.phone_hint'.tr),
            ],
          ),
        );

      case CustomerFormStep.locationAndPapers:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lat / Long Location Fix
            _buildInputLabel('Lat / Long', required: true),
            _buildActionTriggerTile(
              label: _gpsCoords.isEmpty
                  ? 'add_customer.gps_save'.tr
                  : 'add_customer.gps_verified'.tr,
              sub: _gpsCoords.isEmpty ? 'add_customer.gps_hint'.tr : _gpsCoords,
              icon: Icons.location_on_rounded,
              completed: _gpsCoords.isNotEmpty,
              onTap: () => unawaited(_captureGps()),
            ),
            SizedBox(height: _spacing(18)),

            // Photos & Documents
            _buildInputLabel('Photos & Documents', required: true),

            // Photo of Outlet (Front)
            _buildActionTriggerTile(
              label: 'Photo of Outlet (Front)',
              sub: _outletPhotoFront.isEmpty
                  ? 'Tap to capture front view'
                  : 'front_outlet.jpg attached',
              icon: Icons.storefront_rounded,
              completed: _outletPhotoFront.isNotEmpty,
              onTap: () =>
                  setState(() => _outletPhotoFront = "front_outlet.jpg"),
            ),
            SizedBox(height: _spacing(12)),

            // Photo of Outlet (Inside)
            _buildActionTriggerTile(
              label: 'Photo of Outlet (Inside)',
              sub: _outletPhotoInside.isEmpty
                  ? 'Tap to capture interior view'
                  : 'inside_outlet.jpg attached',
              icon: Icons.store_rounded,
              completed: _outletPhotoInside.isNotEmpty,
              onTap: () =>
                  setState(() => _outletPhotoInside = "inside_outlet.jpg"),
            ),
            SizedBox(height: _spacing(12)),

            // Photo of ID Card
            _buildActionTriggerTile(
              label: 'Photo of ID Card',
              sub: _idCardPhoto.isEmpty
                  ? 'Tap to capture owner ID'
                  : 'owner_id.jpg attached',
              icon: Icons.badge_rounded,
              completed: _idCardPhoto.isNotEmpty,
              onTap: () => setState(() => _idCardPhoto = "owner_id.jpg"),
            ),
            SizedBox(height: _spacing(12)),

            // Photo of Patent Tax (Optional)
            _buildActionTriggerTile(
              label: 'Photo of Patent Tax (Optional)',
              sub: _patentTaxPhoto.isEmpty
                  ? 'Tap to capture tax document'
                  : 'patent_tax.jpg attached',
              icon: Icons.receipt_long_rounded,
              completed: _patentTaxPhoto.isNotEmpty,
              onTap: () => setState(() => _patentTaxPhoto = "patent_tax.jpg"),
            ),
            SizedBox(height: _spacing(20)),

            Container(
              padding: EdgeInsets.all(widget.isTablet ? 20 : context.rw(14)),
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
                    size: _fontSize(22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'add_customer.credit_notice'.tr,
                      style: TextStyle(
                        color: context.appColors.warningAlt,
                        fontSize: _fontSize(13),
                        fontWeight: FontWeight.w600,
                        height: 1.3,
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
        CustomerFormStep.contactPerson =>
          'add_customer.steps.contact_person'.tr,
        CustomerFormStep.locationAndPapers =>
          'add_customer.steps.location_papers'.tr,
      };

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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  bool _commitAllSteps(AddCustomerBloc bloc) {
    final valid = (_formKey1.currentState?.validate() ?? false) &&
        (_formKey2.currentState?.validate() ?? false) &&
        _selectedShopType != null &&
        _selectedRole != null;
    if (!valid) return false;

    bloc.add(UpdateShopDetails(
      customerCode: _customerCodeCtrl.text,
      shopName: _shopNameCtrl.text,
      shopType: _selectedShopType!,
      ownerName: _ownerNameCtrl.text,
      addressLine1: _addressCtrl.text,
      city: _cityCtrl.text,
    ));
    bloc.add(UpdateContactDetails(
      name: _contactNameCtrl.text,
      role: _selectedRole!,
      phone: _phoneCtrl.value.international,
    ));
    bloc.add(UpdateLocationAndPapers(
      gpsLocation: _gpsCoords,
      latitude: _latitude,
      longitude: _longitude,
      businessLicencePath: _outletPhotoFront,
      taxPaperPath: _patentTaxPhoto,
    ));
    return true;
  }

  Widget _buildFormNavigationActionButtons(
      BuildContext context, AddCustomerState state) {
    final bloc = context.read<AddCustomerBloc>();
    final isFirstStep =
        _showsAllSteps || state.currentStep == CustomerFormStep.shopDetails;
    final isLastStep = _showsAllSteps ||
        state.currentStep == CustomerFormStep.locationAndPapers;

    final btnPadding = widget.isTablet
        ? const EdgeInsets.symmetric(vertical: 22)
        : EdgeInsets.symmetric(vertical: context.rh(16));

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
                size: _fontSize(22),
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                    customerCode: _customerCodeCtrl.text,
                    shopName: _shopNameCtrl.text,
                    shopType: _selectedShopType!,
                    ownerName: _ownerNameCtrl.text,
                    addressLine1: _addressCtrl.text,
                    city: _cityCtrl.text,
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
                  latitude: _latitude,
                  longitude: _longitude,
                  businessLicencePath: _outletPhotoFront,
                  taxPaperPath: _patentTaxPhoto,
                ));
                bloc.add(SubmitToHQ());
              }
            },
            child: Text(
              isLastStep
                  ? 'add_customer.send_to_hq'.tr
                  : 'add_customer.next_step'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isLastStep
                    ? Colors.white
                    : Theme.of(context).colorScheme.surface,
                fontSize: _fontSize(15),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String label, {bool required = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            fontSize: _fontSize(15),
          ),
          filled: true,
          fillColor: readOnly
              ? context.appColors.border.withValues(alpha: 0.2)
              : context.appColors.surfaceSoft,
          contentPadding: EdgeInsets.symmetric(
            horizontal: widget.isTablet ? 20 : context.rw(14),
            vertical: widget.isTablet ? 20 : context.rh(14),
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
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            fontSize: _fontSize(15),
          ),
          filled: true,
          fillColor: readOnly
              ? context.appColors.border.withValues(alpha: 0.2)
              : context.appColors.surfaceSoft,
          contentPadding: EdgeInsets.symmetric(
            horizontal: widget.isTablet ? 20 : context.rw(14),
            vertical: widget.isTablet ? 20 : context.rh(14),
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
        horizontal: widget.isTablet ? 20 : context.rw(14),
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
            overflow: TextOverflow.ellipsis,
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
              ? null
              : items.entries
                  .map((entry) => DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(
                          entry.value,
                          overflow: TextOverflow.ellipsis,
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
        padding: EdgeInsets.all(widget.isTablet ? 22 : context.rw(14)),
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
              size: _fontSize(22),
              color: completed
                  ? context.appColors.success
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: _fontSize(15),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                      fontSize: _fontSize(12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              completed
                  ? Icons.check_circle_rounded
                  : Icons.add_a_photo_rounded,
              color: completed
                  ? context.appColors.success
                  : Theme.of(context).colorScheme.onSurface,
              size: _fontSize(22),
            ),
          ],
        ),
      ),
    );
  }
}
