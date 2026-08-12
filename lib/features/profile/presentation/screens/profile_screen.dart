import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_event.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/bloc/profile_state.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/widgets/edit_profile_sheet.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/widgets/profile_header.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/widgets/profile_info_section.dart';
import 'package:isi_steel_sales_mobile/features/localization/presentation/widgets/language_section.dart';
import 'package:isi_steel_sales_mobile/features/settings/theme/presentation/widgets/appearance_section.dart';
import 'package:isi_steel_sales_mobile/routes/app_routes.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

    context.read<AuthBloc>().add(const LogoutRequested());
  }

  List<Widget> _actionSection(BuildContext context, ProfileLoaded state,
      bool isTablet, ColorScheme scheme) {
    return [
      const AppearanceSection(),
      SizedBox(height: isTablet ? 24 : context.rh(16)),
      const LanguageSection(),
      SizedBox(height: isTablet ? 28 : context.rh(20)),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: state.isSaving ? null : () => _edit(context, state),
          icon: Icon(Icons.edit_rounded, size: isTablet ? 22 : context.rr(18)),
          label: Text(
            'profile.edit_profile'.tr,
            style: TextStyle(fontSize: isTablet ? 16 : context.rsp(14)),
          ),
        ),
      ),
      SizedBox(height: isTablet ? 14 : context.rh(10)),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () => Navigator.of(context).pushNamed(Static.forgotPassword),
          icon: Icon(Icons.lock_reset_rounded,
              size: isTablet ? 22 : context.rr(18)),
          label: Text(
            'profile.change_password'.tr,
            style: TextStyle(fontSize: isTablet ? 16 : context.rsp(14)),
          ),
        ),
      ),
      SizedBox(height: isTablet ? 28 : context.rh(20)),
      SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 12),
          ),
          onPressed: () => _confirmLogout(context),
          icon: Icon(Icons.logout_rounded,
              size: isTablet ? 22 : context.rr(18), color: scheme.error),
          label: Text(
            'profile.logout'.tr,
            style: TextStyle(
              color: scheme.error,
              fontSize: isTablet ? 16 : context.rsp(14),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LocalizedBuilder(
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final screenWidth = MediaQuery.sizeOf(context).width;
        final isTablet = screenWidth >= 600;

        return Scaffold(
          backgroundColor: scheme.surface,
          appBar: AppBar(
            backgroundColor: scheme.surface,
            iconTheme: IconThemeData(color: scheme.onSurface),
            title: Text(
              'profile.title'.tr,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: isTablet ? 22 : context.rsp(17),
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
          body: BlocConsumer<ProfileCubit, ProfileState>(
            listener: (context, state) {
              if (state is ProfileLoaded && state.actionError != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    content: Text(state.actionError!)));
              }
            },
            builder: (context, state) => switch (state) {
              ProfileLoaded() => RefreshIndicator(
                  color: scheme.primary,
                  onRefresh: () => context.read<ProfileCubit>().load(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 960 : double.infinity,
                      ),
                      child: isTablet
                          ? _buildTabletLayout(context, state, scheme)
                          : _buildPhoneLayout(context, state, scheme),
                    ),
                  ),
                ),
              ProfileError(:final message) => Center(
                  child: Text(message,
                      style:
                          TextStyle(color: context.appColors.textSecondary))),
              _ =>
                Center(child: CircularProgressIndicator(color: scheme.primary)),
            },
          ),
        );
      },
    );
  }

  // Phone: a single calm, scrollable column — everything stacked in the
  // order people naturally expect (who you are, then your details, then
  // settings, then account actions).
  Widget _buildPhoneLayout(
      BuildContext context, ProfileLoaded state, ColorScheme scheme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        ProfileHeader(profile: state.profile),
        SizedBox(height: context.rh(24)),
        ProfileInfoSection(profile: state.profile),
        SizedBox(height: context.rh(16)),
        ..._actionSection(context, state, false, scheme),
      ],
    );
  }

  // Tablet: a two-column "identity card" layout — the header lives in a
  // fixed, calm sidebar on the left so it never scrolls away, while details
  // and settings scroll independently on the right. This reads closer to a
  // premium account/settings page than a stretched phone screen.
  Widget _buildTabletLayout(
      BuildContext context, ProfileLoaded state, ColorScheme scheme) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 300,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(
                color: colors.surfaceSoft,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.border.withValues(alpha: 0.5)),
              ),
              child: ProfileHeader(profile: state.profile, isTablet: true),
            ),
          ),
          const SizedBox(width: 28),
          Expanded(
            child: ListView(
              children: [
                ProfileInfoSection(profile: state.profile, isTablet: true),
                const SizedBox(height: 24),
                ..._actionSection(context, state, true, scheme),
              ],
            ),
          ),
        ],
      ),
    );
  }
}