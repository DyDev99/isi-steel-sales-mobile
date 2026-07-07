import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/local/localized_builder.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_event.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/bloc/profile_state.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/widgets/change_password_sheet.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/widgets/edit_profile_sheet.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/widgets/profile_header.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/widgets/profile_info_section.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().load();
  }

  Future<void> _edit(BuildContext context, ProfileLoaded state) async {
    final updated = await showEditProfileSheet(context: context, profile: state.profile);
    if (updated == null || !context.mounted) return;
    final ok = await context.read<ProfileCubit>().updateProfile(updated);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'profile.updated_success'.tr : 'profile.updated_failure'.tr)),
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    final result = await showChangePasswordSheet(context: context);
    if (result == null || !context.mounted) return;
    final ok = await context.read<ProfileCubit>().changePassword(
          currentPassword: result.currentPassword,
          newPassword: result.newPassword,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'profile.password_success'.tr : 'profile.password_failure'.tr)),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Vibe.bgSoft,
        title: Text('profile.logout_confirm_title'.tr, style: const TextStyle(color: Vibe.text)),
        content: Text('profile.logout_confirm_body'.tr, style: const TextStyle(color: Vibe.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('profile.cancel'.tr)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('profile.logout'.tr)),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await context.read<ProfileCubit>().logout();
    if (!ok || !context.mounted) return;
    context.read<AuthBloc>().add(const LogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    return LocalizedBuilder(
      builder: (context) {
        return Scaffold(
          backgroundColor: Vibe.bg,
          appBar: AppBar(
            backgroundColor: Vibe.bg,
            iconTheme: const IconThemeData(color: Vibe.text),
            title: Text('profile.title'.tr, style: const TextStyle(color: Vibe.text, fontSize: 17, fontWeight: FontWeight.w800)),
          ),
          body: BlocConsumer<ProfileCubit, ProfileState>(
            listener: (context, state) {
              if (state is ProfileLoaded && state.actionError != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.actionError!)));
              }
            },
            builder: (context, state) => switch (state) {
              ProfileLoaded() => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  children: [
                    ProfileHeader(profile: state.profile),
                    const SizedBox(height: 24),
                    ProfileInfoSection(profile: state.profile),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: state.isSaving ? null : () => _edit(context, state),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: Text('profile.edit_profile'.tr),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: state.isSaving ? null : () => _changePassword(context),
                        icon: const Icon(Icons.lock_reset_rounded, size: 18),
                        label: Text('profile.change_password'.tr),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => _confirmLogout(context),
                        icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
                        label: Text('profile.logout'.tr, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ProfileError(:final message) => Center(child: Text(message, style: const TextStyle(color: Vibe.muted))),
              _ => const Center(child: CircularProgressIndicator(color: Vibe.violet)),
            },
          ),
        );
      },
    );
  }
}