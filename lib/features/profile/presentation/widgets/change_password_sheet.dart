import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';

class ChangePasswordResult {
  const ChangePasswordResult(
      {required this.currentPassword, required this.newPassword});
  final String currentPassword;
  final String newPassword;
}

Future<ChangePasswordResult?> showChangePasswordSheet(
    {required BuildContext context}) {
  return showModalBottomSheet<ChangePasswordResult>(
    context: context,
    backgroundColor: context.appColors.surfaceSoft,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => const _ChangePasswordSheet(),
  );
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ChangePasswordResult(
          currentPassword: _currentController.text,
          newPassword: _newController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textColor = TextStyle(color: scheme.onSurface);
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
              Text('profile.change_password'.tr,
                  style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currentController,
                obscureText: true,
                style: textColor,
                decoration:
                    InputDecoration(labelText: 'profile.current_password'.tr),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'profile.required'.tr : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newController,
                obscureText: true,
                style: textColor,
                decoration:
                    InputDecoration(labelText: 'profile.new_password'.tr),
                validator: (v) => (v == null || v.length < 8)
                    ? 'profile.password_min_length'.tr
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                style: textColor,
                decoration: InputDecoration(
                    labelText: 'profile.confirm_new_password'.tr),
                validator: (v) => v != _newController.text
                    ? 'profile.passwords_dont_match'.tr
                    : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('profile.update_password'.tr),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
