import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_event.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:isi_steel_sales_mobile/features/profile/presentation/bloc/profile_state.dart';
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

  /// Settings blocks + account actions, in one list shared by both layouts.
  ///
  /// Sizing is deliberately *not* branched on `isTablet` here: the responsive
  /// helpers (`context.rh`/`rr`/`rsp`) already scale per window size class, and
  /// running a second hand-tuned ladder alongside them is what made this screen
  /// render at two different scales at once — the hardcoded tablet values were
  /// also *smaller* than what the helpers resolve to at `medium`, so type
  /// shrank on the wider screen. `isTablet` now decides structure only (see
  /// [_buildTabletLayout]), never dimensions.
  List<Widget> _actionSection(
      BuildContext context, ProfileLoaded state, ColorScheme scheme) {
    return [
      const AppearanceSection(),
      SizedBox(height: context.rh(16)),
      const LanguageSection(),
      SizedBox(height: context.rh(20)),
      // "Edit profile" is deliberately absent.
      //
      // The API exposes no profile-update endpoint — `/auth/me` is read-only,
      // and employee records are HR-owned, arriving through the directory. An
      // edit form here would either discard the change silently or be
      // overwritten by the system of record on the next sign-in, which is a
      // worse experience than not offering it. See
      // `AuthBackedProfileDataSource.updateProfile`.
      //
      // `showEditProfileSheet` and `ProfileCubit.updateProfile` are left in
      // place for when a real endpoint exists; restoring the button and its
      // handler is then the whole change.
      _ActionButton(
        icon: Icons.lock_reset_rounded,
        label: 'profile.change_password'.tr,
        onPressed: () => Navigator.of(context).pushNamed(Static.forgotPassword),
      ),
      SizedBox(height: context.rh(20)),
      _ActionButton(
        icon: Icons.logout_rounded,
        label: 'profile.logout'.tr,
        color: scheme.error,
        outlined: false,
        onPressed: () => _confirmLogout(context),
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
                fontSize: context.rsp(17),
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
        ..._actionSection(context, state, scheme),
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
                ..._actionSection(context, state, scheme),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A full-width account action. One widget for all three so the row of buttons
/// keeps a single height, radius, icon size, and type scale — previously the
/// two outlined buttons and the logout button each declared their own, and the
/// logout button silently lost the 14pt corner radius the others had.
///
/// [outlined] is the only visual variant: logout is a low-emphasis text button
/// so it does not compete with the two actions above it.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
    this.outlined = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  /// Overrides the foreground colour — the error tone, for logout.
  final Color? color;

  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.symmetric(vertical: context.rh(12));
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    final iconWidget = Icon(icon, size: context.rr(18), color: color);
    final labelWidget = Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: context.rsp(14),
        fontWeight: FontWeight.w700,
      ),
    );

    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton.icon(
              style: OutlinedButton.styleFrom(padding: padding, shape: shape),
              onPressed: onPressed,
              icon: iconWidget,
              label: labelWidget,
            )
          : TextButton.icon(
              style: TextButton.styleFrom(padding: padding, shape: shape),
              onPressed: onPressed,
              icon: iconWidget,
              label: labelWidget,
            ),
    );
  }
}