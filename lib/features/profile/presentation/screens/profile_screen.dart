import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/bloc/profile_state.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/widgets/change_password_sheet.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/widgets/edit_profile_sheet.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/widgets/profile_header.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/widgets/profile_info_section.dart';
// import 'package:isi_steel_sales_mobile/routes/app_routes.dart'; // for Static.login on logout nav

/// Worker profile: identity/contact/work-context readout, edit, change
/// password, and logout. Expects `ProfileCubit` provided above it and
/// calls `load()` once on first build.
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
      SnackBar(content: Text(ok ? 'Profile updated' : 'Could not update profile')),
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
      SnackBar(content: Text(ok ? 'Password updated' : 'Could not update password')),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Vibe.bgSoft,
        title: const Text('Log out?', style: TextStyle(color: Vibe.text)),
        content: const Text('You will need to sign in again to continue.', style: TextStyle(color: Vibe.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log out')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<ProfileCubit>().logout();
    // On ProfileLoggedOut, navigate to Static.login and clear the stack, e.g.:
    // if (context.mounted) {
    //   Navigator.of(context).pushNamedAndRemoveUntil(Static.login, (route) => false);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vibe.bg,
      appBar: AppBar(
        backgroundColor: Vibe.bg,
        iconTheme: const IconThemeData(color: Vibe.text),
        title: const Text('Profile', style: TextStyle(color: Vibe.text, fontSize: 17, fontWeight: FontWeight.w800)),
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
                    label: const Text('Edit Profile'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: state.isSaving ? null : () => _changePassword(context),
                    icon: const Icon(Icons.lock_reset_rounded, size: 18),
                    label: const Text('Change Password'),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _confirmLogout(context),
                    // NOTE: swap this for your app's error/danger token if
                    // `Vibe` defines one (not confirmed in the files I've
                    // seen) — using a plain red as a safe default.
                    icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
                    label: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ProfileError(:final message) => Center(child: Text(message, style: const TextStyle(color: Vibe.muted))),
          _ => const Center(child: CircularProgressIndicator(color: Vibe.violet)),
        },
      ),
    );
  }
}
