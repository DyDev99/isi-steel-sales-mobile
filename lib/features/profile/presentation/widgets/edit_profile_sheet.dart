import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/app_bottom_sheet.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/keyboard_aware_scroll_view.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/features/profile/domain/entities/worker_profile.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

Future<WorkerProfile?> showEditProfileSheet({
  required BuildContext context,
  required WorkerProfile profile,
}) {
  final isTablet = MediaQuery.sizeOf(context).width >= 600;

  if (isTablet) {
    return showGeneralDialog<WorkerProfile>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'EditProfile',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 560,
              decoration: BoxDecoration(
                color: context.appColors.surfaceSoft,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: _EditProfileSheet(profile: profile, isTablet: true),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  return showModalBottomSheet<WorkerProfile>(
    constraints: const BoxConstraints(maxWidth: double.infinity),
    context: context,
    backgroundColor: context.appColors.surfaceSoft,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    // AppBottomSheet supplies the keyboard inset, the safe area and the 0.9
    // height cap. Without the cap this three-field form plus the keyboard
    // overflowed on a short screen; the sheet draws its own handle, hence
    // showHandle: false.
    builder: (_) => AppBottomSheet(
      showHandle: false,
      child: _EditProfileSheet(profile: profile, isTablet: false),
    ),
  );
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.profile,
    this.isTablet = false,
  });
  final WorkerProfile profile;
  final bool isTablet;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController =
      TextEditingController(text: widget.profile.fullName);
  late final _phoneController =
      TextEditingController(text: widget.profile.phone);
  late final _territoryController =
      TextEditingController(text: widget.profile.territory);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _territoryController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      widget.profile.copyWith(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        territory: _territoryController.text.trim(),
      ),
    );
  }

  double _fontSize(double basePhoneSize) {
    return widget.isTablet ? basePhoneSize * 1.15 : context.rsp(basePhoneSize);
  }

  InputDecoration _fieldDecoration(BuildContext context, String label) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      labelStyle:
          TextStyle(fontSize: _fontSize(14), color: colors.textSecondary),
      filled: true,
      fillColor: colors.surfaceStrong.withValues(alpha: 0.35),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.border.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.error),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final textColor = TextStyle(
      color: scheme.onSurface,
      fontSize: _fontSize(15),
    );

    // The keyboard inset was applied here by hand for the phone path;
    // AppBottomSheet owns it now, and applying it twice would leave a gap the
    // height of the keyboard under the content. The tablet path passed 0 here
    // and still does — it is a centred dialog, which the inset would not move.
    //
    // The scroll view is the actual fix: three fields and a keyboard did not
    // fit a short screen, and a Column that cannot scroll overflows instead of
    // letting the user reach the field they are typing in.
    return Form(
      key: _formKey,
      child: KeyboardAwareScrollView(
        padding: EdgeInsets.fromLTRB(
          widget.isTablet ? 32 : 20,
          widget.isTablet ? 28 : 12,
          widget.isTablet ? 32 : 20,
          widget.isTablet ? 32 : 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle — a small, familiar "this is casual, relax" cue
            // on the phone-sized bottom sheet.
            if (!widget.isTablet)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'profile.edit_profile'.tr,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: _fontSize(19),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                if (widget.isTablet)
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            ),
            SizedBox(height: widget.isTablet ? 24 : context.rh(18)),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.name,
              style: textColor,
              decoration: _fieldDecoration(context, 'profile.full_name'.tr),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'profile.required'.tr
                  : null,
            ),
            SizedBox(height: widget.isTablet ? 16 : context.rh(14)),
            TextFormField(
              controller: _phoneController,
              textInputAction: TextInputAction.next,
              style: textColor,
              keyboardType: TextInputType.phone,
              decoration: _fieldDecoration(context, 'profile.phone'.tr),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'profile.required'.tr
                  : null,
            ),
            SizedBox(height: widget.isTablet ? 16 : context.rh(14)),
            TextFormField(
              controller: _territoryController,
              textInputAction: TextInputAction.done,
              style: textColor,
              decoration: _fieldDecoration(context, 'profile.territory'.tr),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'profile.required'.tr
                  : null,
            ),
            SizedBox(height: widget.isTablet ? 28 : context.rh(24)),
            SizedBox(
              width: double.infinity,
              height: widget.isTablet ? 56 : 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      scheme.primary,
                      scheme.primary.withValues(alpha: 0.82),
                    ],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: scheme.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'profile.save_changes'.tr,
                    style: TextStyle(
                      fontSize: _fontSize(15),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
