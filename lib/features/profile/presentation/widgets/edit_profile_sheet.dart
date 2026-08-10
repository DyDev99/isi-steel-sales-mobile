import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
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
                borderRadius: BorderRadius.circular(20),
              ),
              child: _EditProfileSheet(profile: profile, isTablet: true),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
          child: child,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _EditProfileSheet(profile: profile, isTablet: false),
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textColor = TextStyle(
      color: scheme.onSurface,
      fontSize: _fontSize(15),
    );

    return Padding(
      padding: EdgeInsets.only(
          bottom: widget.isTablet
              ? 0
              : MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: EdgeInsets.all(widget.isTablet ? 32.0 : 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'profile.edit_profile'.tr,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: _fontSize(18),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (widget.isTablet)
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),
              SizedBox(height: widget.isTablet ? 20 : context.rh(16)),
              TextFormField(
                controller: _nameController,
                style: textColor,
                decoration: InputDecoration(
                  labelText: 'profile.full_name'.tr,
                  labelStyle: TextStyle(fontSize: _fontSize(14)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'profile.required'.tr
                    : null,
              ),
              SizedBox(height: widget.isTablet ? 16 : context.rh(12)),
              TextFormField(
                controller: _phoneController,
                style: textColor,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'profile.phone'.tr,
                  labelStyle: TextStyle(fontSize: _fontSize(14)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'profile.required'.tr
                    : null,
              ),
              SizedBox(height: widget.isTablet ? 16 : context.rh(12)),
              TextFormField(
                controller: _territoryController,
                style: textColor,
                decoration: InputDecoration(
                  labelText: 'profile.territory'.tr,
                  labelStyle: TextStyle(fontSize: _fontSize(14)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'profile.required'.tr
                    : null,
              ),
              SizedBox(height: widget.isTablet ? 28 : context.rh(20)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    padding: EdgeInsets.symmetric(
                        vertical: widget.isTablet ? 18 : 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'profile.save_changes'.tr,
                    style: TextStyle(
                      fontSize: _fontSize(15),
                      fontWeight: FontWeight.bold,
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