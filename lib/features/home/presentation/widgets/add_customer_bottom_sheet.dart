import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/add_customer_bloc.dart';

void showAddCustomerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext modalContext) {
      // The BLoC is injected at the very root of the modal sheet
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
  late TextEditingController _phoneCtrl;
  
  String? _selectedShopType;
  String? _selectedRole;
  
  String _gpsCoords = "";
  String _licenceFile = "";
  String _patentFile = "";

  @override
  void initState() {
    super.initState();
    _shopNameCtrl = TextEditingController();
    _ownerNameCtrl = TextEditingController();
    _contactNameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
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
    // Because this widget is a child of BlocProvider inside the bottom sheet builder,
    // this context has full access to AddCustomerBloc.
    return BlocConsumer<AddCustomerBloc, AddCustomerState>(
      listener: (context, state) {
        if (state.status == AddCustomerStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dispatched directly to HQ pipeline! Pending SAP review.')),
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
                  decoration: BoxDecoration(color: Vibe.stroke, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 20.h),
              _buildFormHeader(state),
              SizedBox(height: 20.h),
              if (state.status == AddCustomerStatus.submitting)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Vibe.pink)))
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
    String title = "Depot Setup";
    String stepText = "Step 1 of 3";
    
    if (state.currentStep == CustomerFormStep.contactPerson) {
      title = "Contact Representative";
      stepText = "Step 2 of 3";
    } else if (state.currentStep == CustomerFormStep.locationAndPapers) {
      title = "Verification & Papers";
      stepText = "Step 3 of 3";
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Vibe.text, fontSize: 20.sp, fontWeight: FontWeight.w900)),
            Text("Prospect Onboarding Pipeline", style: TextStyle(color: Vibe.text.withOpacity(0.5), fontSize: 12.sp)),
          ],
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(color: Vibe.bgSoft, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: Vibe.stroke)),
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
              _buildInputLabel("Shop Name"),
              _buildTextField(_shopNameCtrl, "Enter registered commercial brand name"),
              SizedBox(height: 14.h),
              _buildInputLabel("Type of Shop"),
              _buildDropdownField(
                value: _selectedShopType,
                hint: "Pick one...",
                items: ['Hardware shop', 'Retailer', 'Wholesaler', 'Project / contractor'],
                onChanged: (val) => setState(() => _selectedShopType = val),
              ),
              SizedBox(height: 14.h),
              _buildInputLabel("Owner Name"),
              _buildTextField(_ownerNameCtrl, "Full legal name of identity documentation holder"),
            ],
          ),
        );

      case CustomerFormStep.contactPerson:
        return Form(
          key: _formKey2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputLabel("Contact Name"),
              _buildTextField(_contactNameCtrl, "Primary operative agent name"),
              SizedBox(height: 14.h),
              _buildInputLabel("Role Designation"),
              _buildDropdownField(
                value: _selectedRole,
                hint: "Pick one...",
                items: ['Owner', 'Manager', 'Buyer'],
                onChanged: (val) => setState(() => _selectedRole = val),
              ),
              SizedBox(height: 14.h),
              _buildInputLabel("Phone Number"),
              _buildTextField(_phoneCtrl, "Active contact point identifier", keyboardType: TextInputType.phone),
            ],
          ),
        );

      case CustomerFormStep.locationAndPapers:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputLabel("Physical Telemetry"),
            _buildActionTriggerTile(
              label: _gpsCoords.isEmpty ? "Save shop location (GPS)" : "Coordinates Verified",
              sub: _gpsCoords.isEmpty ? "Tap to record current hardware GPS entry" : _gpsCoords,
              icon: Icons.location_on_rounded,
              completed: _gpsCoords.isNotEmpty,
              onTap: () => setState(() => _gpsCoords = "11.5564° N, 104.9282° E"),
            ),
            SizedBox(height: 14.h),
            _buildInputLabel("Compliance Papers"),
            _buildActionTriggerTile(
              label: "Business Licence Document",
              sub: _licenceFile.isEmpty ? "Upload clear scan or photograph" : "Attached: lic_reg_corp.jpg",
              icon: Icons.assignment_rounded,
              completed: _licenceFile.isNotEmpty,
              onTap: () => setState(() => _licenceFile = "lic_reg_corp.jpg"),
            ),
            SizedBox(height: 10.h),
            _buildActionTriggerTile(
              label: "Tax Paper (Patent)",
              sub: _patentFile.isEmpty ? "Upload current ongoing validation patent details" : "Attached: national_patent.jpg",
              icon: Icons.receipt_long_rounded,
              completed: _patentFile.isNotEmpty,
              onTap: () => setState(() => _patentFile = "national_patent.jpg"),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(color: Vibe.warning.withOpacity(0.08), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: Vibe.warning.withOpacity(0.3))),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Vibe.warning, size: 20),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      "HQ finance adds bank details, sets the credit limit and approves in SAP. You never set credit.",
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
                  bloc.add(UpdateShopDetails(shopName: _shopNameCtrl.text, shopType: _selectedShopType!, ownerName: _ownerNameCtrl.text));
                  bloc.add(NextStep());
                }
              } else if (state.currentStep == CustomerFormStep.contactPerson) {
                if (_formKey2.currentState!.validate() && _selectedRole != null) {
                  bloc.add(UpdateContactDetails(name: _contactNameCtrl.text, role: _selectedRole!, phone: _phoneCtrl.text));
                  bloc.add(NextStep());
                }
              } else if (isLastStep) {
                bloc.add(UpdateLocationAndPapers(gpsLocation: _gpsCoords, businessLicencePath: _licenceFile, taxPaperPath: _patentFile));
                bloc.add(SubmitToHQ());
              }
            },
            child: Text(
              isLastStep ? "Send to HQ" : "Next Step",
              style: TextStyle(color: isLastStep ? Colors.white : Vibe.bg, fontSize: 15.sp, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String label) => Padding(
    padding: EdgeInsets.only(bottom: 6.h, left: 2.w),
    child: Text(label, style: TextStyle(color: Vibe.text, fontSize: 13.sp, fontWeight: FontWeight.w700)),
  );

  Widget _buildTextField(TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text}) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    style: const TextStyle(color: Vibe.text),
    validator: (v) => (v == null || v.trim().isEmpty) ? "Field required" : null,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Vibe.text.withOpacity(0.3), fontSize: 13.sp),
      filled: true,
      fillColor: Vibe.bgSoft,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Vibe.stroke)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Vibe.text)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Vibe.danger)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Vibe.danger)),
    ),
  );

  Widget _buildDropdownField({required String? value, required String hint, required List<String> items, required ValueChanged<String?> onChanged}) => Container(
    padding: EdgeInsets.symmetric(horizontal: 16.w),
    decoration: BoxDecoration(color: Vibe.bgSoft, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: Vibe.stroke)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        hint: Text(hint, style: TextStyle(color: Vibe.text.withOpacity(0.3), fontSize: 13.sp)),
        dropdownColor: Vibe.bgSoft,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Vibe.text),
        isExpanded: true,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Vibe.text)))).toList(),
        onChanged: onChanged,
      ),
    ),
  );

  Widget _buildActionTriggerTile({required String label, required String sub, required IconData icon, required bool completed, required VoidCallback onTap}) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14.r),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: completed ? Vibe.success.withOpacity(0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: completed ? Vibe.success : Vibe.stroke, width: completed ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: completed ? Vibe.success : Vibe.text.withOpacity(0.6)),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Vibe.text, fontSize: 14.sp, fontWeight: FontWeight.w700)),
                Text(sub, style: TextStyle(color: Vibe.text.withOpacity(0.4), fontSize: 11.sp)),
              ],
            ),
          ),
          Icon(completed ? Icons.check_circle_rounded : Icons.add_a_photo_rounded, color: completed ? Vibe.success : Vibe.text, size: 20),
        ],
      ),
    ),
  );
}