import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/features/profile/domain/entities/worker_profile.dart';

Future<WorkerProfile?> showEditProfileSheet({
  required BuildContext context,
  required WorkerProfile profile,
}) {
  return showModalBottomSheet<WorkerProfile>(
    context: context,
    backgroundColor: Vibe.bgSoft,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _EditProfileSheet(profile: profile),
  );
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.profile});
  final WorkerProfile profile;

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('profile.edit_profile'.tr,
                  style: const TextStyle(
                      color: Vibe.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Vibe.text),
                decoration: InputDecoration(labelText: 'profile.full_name'.tr),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'profile.required'.tr
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                style: const TextStyle(color: Vibe.text),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: 'profile.phone'.tr),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'profile.required'.tr
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _territoryController,
                style: const TextStyle(color: Vibe.text),
                decoration: InputDecoration(labelText: 'profile.territory'.tr),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'profile.required'.tr
                    : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Vibe.violet,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('profile.save_changes'.tr),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
