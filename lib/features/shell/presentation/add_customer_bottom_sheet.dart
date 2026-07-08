import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phone_form_field/phone_form_field.dart';

import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/add_customer_bloc.dart';

void showAddCustomerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext modalContext) {
      return BlocProvider<AddCustomerBloc>(
        create: (context) => sl<AddCustomerBloc>(),
        child: const AddCustomerBottomSheet(),
      );
    },
  );
}

class AddCustomerBottomSheet extends StatefulWidget {
  const AddCustomerBottomSheet({super.key});

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

  String? _selectedShopType; // key (e.g. 'hardware_shop')
  String? _selectedRole;     // key (e.g. 'owner')

  String _gpsCoords = "";
  String _licenceFile = "";
  String _patentFile = "";

@override
void initState() {
  super.initState();
  _shopNameCtrl = TextEditingController();
  _ownerNameCtrl = TextEditingController();
  _contactNameCtrl = TextEditingController();
  
  // Initialize the controller with Cambodia set as the default country flag
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
    return BlocConsumer<AddCustomerBloc, AddCustomerState>(
      listener: (context, state) {
        if (state.status == AddCustomerStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('add_customer.success'.tr)),
          );
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        return Container(
          decoration: const BoxDecoration(
            color: Vibe.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, MediaQuery.of(context).viewInsets.bottom + 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: Vibe.stroke,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              _buildFormHeader(state),
              SizedBox(height: 20.h),
              if (state.status == AddCustomerStatus.submitting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Vibe.pink),
                  ),
                )
              else ...[
                _buildActiveStepBody(state),
                SizedBox(height: 24.h),
                _buildFormNavigationActionButtons(context, state),
              ]
            ],
          ),
        );
      },
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

    final stepText = 'add_customer.step_indicator'.tr
        .replaceAll('{current}', '$stepNumber')
        .replaceAll('{total}', '3');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Vibe.text, fontSize: 20.sp, fontWeight: FontWeight.w900)),
            Text('add_customer.subtitle'.tr, style: TextStyle(color: Vibe.text.withValues(alpha: 0.5), fontSize: 12.sp)),
          ],
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Vibe.bgSoft,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Vibe.stroke),
          ),
          child: Text(stepText, style: TextStyle(color: Vibe.pink, fontSize: 11.sp, fontWeight: FontWeight.w800)),
        )
      ],
    );
  }

  Widget _buildActiveStepBody(AddCustomerState state) {
    switch (state.currentStep) {
      case CustomerFormStep.shopDetails:
        return Form(
          key: _formKey1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputLabel('add_customer.shop_name'.tr, required: true),
              _buildTextField(_shopNameCtrl, 'add_customer.shop_name_hint'.tr),
              SizedBox(height: 14.h),
              _buildInputLabel('add_customer.shop_type'.tr, required: true),
              _buildDropdownField(
                value: _selectedShopType,
                hint: 'add_customer.pick_one'.tr,
                items: {
                  'hardware_shop': 'add_customer.shop_types.hardware_shop'.tr,
                  'retailer': 'add_customer.shop_types.retailer'.tr,
                  'wholesaler': 'add_customer.shop_types.wholesaler'.tr,
                  'project_contractor': 'add_customer.shop_types.project_contractor'.tr,
                },
                onChanged: (val) => setState(() => _selectedShopType = val),
              ),
              SizedBox(height: 14.h),
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
              _buildTextField(_contactNameCtrl, 'add_customer.contact_name_hint'.tr),
              SizedBox(height: 14.h),
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
              SizedBox(height: 14.h),
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
              label: _gpsCoords.isEmpty ? 'add_customer.gps_save'.tr : 'add_customer.gps_verified'.tr,
              sub: _gpsCoords.isEmpty ? 'add_customer.gps_hint'.tr : _gpsCoords,
              icon: Icons.location_on_rounded,
              completed: _gpsCoords.isNotEmpty,
              onTap: () => setState(() => _gpsCoords = "11.5564° N, 104.9282° E"),
            ),
            SizedBox(height: 14.h),
            _buildInputLabel('add_customer.compliance'.tr),
            _buildActionTriggerTile(
              label: 'add_customer.licence'.tr,
              sub: _licenceFile.isEmpty ? 'add_customer.licence_hint'.tr : 'add_customer.licence_attached'.tr,
              icon: Icons.assignment_rounded,
              completed: _licenceFile.isNotEmpty,
              onTap: () => setState(() => _licenceFile = "lic_reg_corp.jpg"),
            ),
            SizedBox(height: 10.h),
            _buildActionTriggerTile(
              label: 'add_customer.tax_paper'.tr,
              sub: _patentFile.isEmpty ? 'add_customer.tax_paper_hint'.tr : 'add_customer.tax_paper_attached'.tr,
              icon: Icons.receipt_long_rounded,
              completed: _patentFile.isNotEmpty,
              onTap: () => setState(() => _patentFile = "national_patent.jpg"),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Vibe.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Vibe.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Vibe.warning, size: 20),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'add_customer.credit_notice'.tr,
                      style: TextStyle(color: Vibe.warning, fontSize: 11.sp, fontWeight: FontWeight.w600, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildFormNavigationActionButtons(BuildContext context, AddCustomerState state) {
    final bloc = context.read<AddCustomerBloc>();
    final isFirstStep = state.currentStep == CustomerFormStep.shopDetails;
    final isLastStep = state.currentStep == CustomerFormStep.locationAndPapers;

    return Row(
      children: [
        if (!isFirstStep) ...[
          Expanded(
            flex: 1,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                side: const BorderSide(color: Vibe.stroke),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              ),
              onPressed: () => bloc.add(PreviousStep()),
              child: const Icon(Icons.arrow_back, color: Vibe.text),
            ),
          ),
          SizedBox(width: 12.w),
        ],
        Expanded(
          flex: 2,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              backgroundColor: isLastStep ? Vibe.success : Vibe.violet,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              elevation: 0,
            ),
            onPressed: () {
              if (state.currentStep == CustomerFormStep.shopDetails) {
                if (_formKey1.currentState!.validate() && _selectedShopType != null) {
                  bloc.add(UpdateShopDetails(
                    shopName: _shopNameCtrl.text,
                    shopType: _selectedShopType!,
                    ownerName: _ownerNameCtrl.text,
                  ));
                  bloc.add(NextStep());
                }
              } else if (state.currentStep == CustomerFormStep.contactPerson) {
                if (_formKey2.currentState!.validate() && _selectedRole != null) {
                  bloc.add(UpdateContactDetails(
                    name: _contactNameCtrl.text,
                    role: _selectedRole!,
                    phone: _phoneCtrl.value.international, // Transmits standard E.164 string format (e.g., +855...)
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
              isLastStep ? 'add_customer.send_to_hq'.tr : 'add_customer.next_step'.tr,
              style: TextStyle(
                color: isLastStep ? Colors.white : Vibe.bg,
                fontSize: 15.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== Reusable Widgets ====================

  Widget _buildInputLabel(String label, {bool required = false}) => Padding(
    padding: EdgeInsets.only(bottom: 6.h, left: 2.w),
    child: RichText(
      text: TextSpan(
        text: label,
        style: TextStyle(color: Vibe.text, fontSize: 13.sp, fontWeight: FontWeight.w700),
        children: required
            ? [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Vibe.danger, fontSize: 13.sp, fontWeight: FontWeight.w900),
                ),
              ]
            : null,
      ),
    ),
  );

  Widget _buildTextField(TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text}) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Vibe.text),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'add_customer.error.required'.tr : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Vibe.text.withValues(alpha: 0.3), fontSize: 13.sp),
          filled: true,
          fillColor: Vibe.bgSoft,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: Vibe.stroke),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: Vibe.text),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: Vibe.danger),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: Vibe.danger),
          ),
        ),
      );

  Widget _buildPhoneField(PhoneController controller, String hint) => PhoneFormField(
      controller: controller,
      // Remove defaultCountry from here entirely
      style: const TextStyle(color: Vibe.text),
      countryButtonStyle: const CountryButtonStyle(
        showFlag: true,
        showIsoCode: false,
        showDialCode: true,
        showDropdownIcon: true,
        textStyle: TextStyle(color: Vibe.text),
      ),
      validator: PhoneValidator.compose([
        PhoneValidator.required(context, errorText: 'add_customer.error.required'.tr),
        PhoneValidator.validMobile(context, errorText: 'add_customer.error.invalid_phone'.tr),
      ]),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Vibe.text.withValues(alpha: 0.3), fontSize: 13.sp),
        filled: true,
        fillColor: Vibe.bgSoft,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Vibe.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Vibe.text),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Vibe.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Vibe.danger),
        ),
      ),
    );

  Widget _buildDropdownField({
    required String? value,
    required String hint,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Vibe.bgSoft,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Vibe.stroke),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Vibe.text.withValues(alpha: 0.3), fontSize: 13.sp)),
          dropdownColor: Vibe.bgSoft,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Vibe.text),
          isExpanded: true,
          items: items.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key, // internal key
              child: Text(entry.value, style: const TextStyle(color: Vibe.text)),
            );
          }).toList(),
          onChanged: onChanged,
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
      borderRadius: BorderRadius.circular(14.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: completed ? Vibe.success.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: completed ? Vibe.success : Vibe.stroke,
            width: completed ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: completed ? Vibe.success : Vibe.text.withValues(alpha: 0.6)),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Vibe.text, fontSize: 14.sp, fontWeight: FontWeight.w700)),
                  Text(sub, style: TextStyle(color: Vibe.text.withValues(alpha: 0.4), fontSize: 11.sp)),
                ],
              ),
            ),
            Icon(
              completed ? Icons.check_circle_rounded : Icons.add_a_photo_rounded,
              color: completed ? Vibe.success : Vibe.text,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}