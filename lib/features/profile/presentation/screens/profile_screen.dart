import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/local/localized_builder.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_event.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/bloc/profile_state.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/widgets/edit_profile_sheet.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/widgets/profile_header.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/widgets/profile_info_section.dart';
import 'package:isi_steel_sales_mobile/features/settings/theme/presentation/widgets/appearance_section.dart';
import 'package:isi_steel_sales_mobile/routes/app_routes.dart';

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
    final updated =
        await showEditProfileSheet(context: context, profile: state.profile);
    if (updated == null || !context.mounted) return;
    final ok = await context.read<ProfileCubit>().updateProfile(updated);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(ok
              ? 'profile.updated_success'.tr
              : 'profile.updated_failure'.tr)),
    );
  }



  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appColors.surfaceSoft,
        title: Text('profile.logout_confirm_title'.tr,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text('profile.logout_confirm_body'.tr,
            style: TextStyle(color: context.appColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('profile.cancel'.tr)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('profile.logout'.tr)),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await context.read<ProfileCubit>().logout();
    if (!ok || !context.mounted) return;
    // Drop the token/session (AuthBloc returns the user to guest browsing) and
    // pop back to the shell — the app stays open, guest-first.
    context.read<AuthBloc>().add(const LogoutRequested());
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return LocalizedBuilder(
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return Scaffold(
          backgroundColor: scheme.surface,
          appBar: AppBar(
            backgroundColor: scheme.surface,
            iconTheme: IconThemeData(color: scheme.onSurface),
            title: Text('profile.title'.tr,
                style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
          ),
          body: BlocConsumer<ProfileCubit, ProfileState>(
            listener: (context, state) {
              if (state is ProfileLoaded && state.actionError != null) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(state.actionError!)));
              }
            },
            builder: (context, state) => switch (state) {
              ProfileLoaded() => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  children: [
                    ProfileHeader(profile: state.profile),
                    const SizedBox(height: 24),
                    ProfileInfoSection(profile: state.profile),
                    const SizedBox(height: 16),
                    const AppearanceSection(),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            state.isSaving ? null : () => _edit(context, state),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: Text('profile.edit_profile'.tr),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pushNamed(Static.forgotPassword),

                        icon: const Icon(Icons.lock_reset_rounded, size: 18),
                        label: Text('profile.change_password'.tr),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => _confirmLogout(context),
                        icon: Icon(Icons.logout_rounded,
                            size: 18, color: scheme.error),
                        label: Text('profile.logout'.tr,
                            style: TextStyle(
                                color: scheme.error,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ProfileError(:final message) => Center(
                  child: Text(message,
                      style:
                          TextStyle(color: context.appColors.textSecondary))),
              _ => Center(
                  child: CircularProgressIndicator(color: scheme.primary)),
            },
          ),
        );
      },
    );
  }
}
