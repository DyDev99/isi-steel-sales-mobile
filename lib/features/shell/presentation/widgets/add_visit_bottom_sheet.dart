import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/territory_type.dart';

void showAddVisitSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext modalContext) => const AddVisitBottomSheet(),
  );
}

/// Quick "Add My Visit" form — UI only, mirrors [showAddCustomerSheet]'s
/// bottom-sheet style. There's no create-visit use case wired up yet (the
/// route dashboard is read-only, driven by `WatchTodayRoutes`), so submit
/// just confirms and closes rather than persisting anything.
class AddVisitBottomSheet extends StatefulWidget {
  const AddVisitBottomSheet({super.key});

  @override
  State<AddVisitBottomSheet> createState() => _AddVisitBottomSheetState();
}

class _AddVisitBottomSheetState extends State<AddVisitBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _shopNameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _notesCtrl;

  TerritoryType? _territoryType;
  DateTime _visitDate = DateTime.now();
  TimeOfDay _plannedTime =
      TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _shopNameCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _visitDate = picked);
  }

  Future<void> _pickTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _plannedTime);
    if (picked != null) setState(() => _plannedTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _territoryType == null) {
      if (_territoryType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pick a territory type')),
        );
      }
      return;
    }
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Visit to ${_shopNameCtrl.text} added to today\'s route')),
    );
    Navigator.pop(context);
  }

  String get _dateLabel =>
      '${_visitDate.day}/${_visitDate.month}/${_visitDate.year}';
  String get _timeLabel => _plannedTime.format(context);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Vibe.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24.w, 16.h, 24.w, MediaQuery.of(context).viewInsets.bottom + 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42.w,
              height: 5.h,
              decoration: BoxDecoration(
                  color: Vibe.stroke, borderRadius: BorderRadius.circular(10)),
            ),
          ),
          SizedBox(height: 20.h),
          Text('Add My Visit',
              style: TextStyle(
                  color: Vibe.text,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900)),
          Text('Add a stop to today\'s route',
              style: TextStyle(
                  color: Vibe.text.withValues(alpha: 0.5), fontSize: 12.sp)),
          SizedBox(height: 20.h),
          if (_submitting)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Vibe.violet)))
          else ...[
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('Shop Name'),
                  _buildTextField(_shopNameCtrl, 'Shop or customer name'),
                  SizedBox(height: 14.h),
                  _buildInputLabel('Address'),
                  _buildTextField(_addressCtrl, 'Street, district, province'),
                  SizedBox(height: 14.h),
                  _buildInputLabel('Territory Type'),
                  _buildDropdownField(),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel('Visit Date'),
                            _buildPickerTile(
                                icon: Icons.calendar_today_rounded,
                                label: _dateLabel,
                                onTap: _pickDate),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel('Planned Time'),
                            _buildPickerTile(
                                icon: Icons.schedule_rounded,
                                label: _timeLabel,
                                onTap: _pickTime),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  _buildInputLabel('Notes (optional)'),
                  _buildTextField(_notesCtrl, 'Purpose of visit, reminders…',
                      required: false, maxLines: 3),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  backgroundColor: Vibe.violet,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r)),
                  elevation: 0,
                ),
                onPressed: _submit,
                child: Text('Add Visit',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) => Padding(
        padding: EdgeInsets.only(bottom: 6.h, left: 2.w),
        child: Text(label,
            style: TextStyle(
                color: Vibe.text,
                fontSize: 13.sp,
                fontWeight: FontWeight.w700)),
      );

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool required = true,
    int maxLines = 1,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Vibe.text),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Field required' : null
            : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: Vibe.text.withValues(alpha: 0.3), fontSize: 13.sp),
          filled: true,
          fillColor: Vibe.bgSoft,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Vibe.stroke)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Vibe.text)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Vibe.danger)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Vibe.danger)),
        ),
      );

  Widget _buildDropdownField() => Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
            color: Vibe.bgSoft,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Vibe.stroke)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<TerritoryType>(
            value: _territoryType,
            hint: Text('Pick one…',
                style: TextStyle(
                    color: Vibe.text.withValues(alpha: 0.3), fontSize: 13.sp)),
            dropdownColor: Vibe.bgSoft,
            icon:
                const Icon(Icons.keyboard_arrow_down_rounded, color: Vibe.text),
            isExpanded: true,
            items: TerritoryType.values
                .map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.label,
                        style: const TextStyle(color: Vibe.text))))
                .toList(),
            onChanged: (val) => setState(() => _territoryType = val),
          ),
        ),
      );

  Widget _buildPickerTile(
          {required IconData icon,
          required String label,
          required VoidCallback onTap}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
          decoration: BoxDecoration(
              color: Vibe.bgSoft,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Vibe.stroke)),
          child: Row(
            children: [
              Icon(icon, size: 16, color: Vibe.muted),
              SizedBox(width: 8.w),
              Expanded(
                  child: Text(label,
                      style: TextStyle(
                          color: Vibe.text,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700))),
            ],
          ),
        ),
      );
}
