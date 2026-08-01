import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/presentation/services/coach_keys.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/lead_usecase.dart';
import 'package:isi_steel_sales_mobile/features/localization/presentation/bloc/language_cubit.dart';
import 'package:isi_steel_sales_mobile/features/localization/presentation/widgets/language_reload_dialog.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/usecases/fetch_notifications.dart';
import 'package:isi_steel_sales_mobile/features/notification/presentation/screen/notifications_sheet.dart';
import 'package:isi_steel_sales_mobile/routes/app_routes.dart';

class MainAppBar extends StatelessWidget {
  const MainAppBar({
    super.key,
    required this.title,
    required this.onAvatarTap,
    required this.currentTabIndex,
    this.onBackToHomeTap,
    this.onNotificationTap,
  });

  final String title;
  final VoidCallback onAvatarTap;
  final int currentTabIndex;
  final VoidCallback? onBackToHomeTap;
  final VoidCallback? onNotificationTap;

  // Traditional Gold Palette
  static const Color _goldLight = Color(0xFFF3E5AB);
  static const Color _goldPrimary = Color(0xFFD4AF37);
  static const Color _goldDark = Color(0xFF996515);

  @override
  Widget build(BuildContext context) {
    final bool isHome = currentTabIndex == 0;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isHome ? Colors.transparent : scheme.surface,
        border: isHome
            ? null
            : Border(
                bottom: BorderSide(
                  color: _goldPrimary.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
        boxShadow: isHome
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12.w, 10.h, 16.w, 10.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Back Button Medallion (Conditionally rendered)
              if (!isHome) ...[
                _AppBarMedallionButton(
                  isHome: false,
                  onTap: onBackToHomeTap,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: scheme.onSurface,
                    size: 16.sp,
                  ),
                ),
                SizedBox(width: 12.w),
              ],

              // 2. Main Content (Logo or Title)
              Expanded(
                child: isHome
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: Image.asset(
                              'assets/logos/isi_main_screen_logo.png',
                              height: 40.h,
                              width: 140.w,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        title,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
              ),
              SizedBox(width: 12.w),

              // 3. Language Selector Popup Menu — 3D Medallion
              CoachKeys.wrap(
                CoachKeys.language,
                child: PopupMenuButton<String>(
                  offset: const Offset(0, 42),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    side: BorderSide(
                      color: _goldPrimary.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                  ),
                  color: scheme.surface,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: const ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onSelected: (code) async {
                    final languageCubit = context.read<LanguageCubit>();
                    final currentLang = languageCubit.state.languageCode;
                    if (code == currentLang) return;

                    final target = languageCubit.supportedLanguages.firstWhere(
                      (l) => l.code == code,
                      orElse: () => languageCubit.supportedLanguages.first,
                    );

                    final confirmed =
                        await showLanguageReloadConfirmDialog(context, target);
                    if (!confirmed || !context.mounted) return;

                    await languageCubit.changeLanguage(code);
                    navigatorKey.currentState?.pushNamedAndRemoveUntil(
                      Static.main,
                      (route) => false,
                    );
                  },
                  itemBuilder: (menuContext) {
                    final languageCubit = context.read<LanguageCubit>();
                    final currentLang = languageCubit.state.languageCode;

                    return languageCubit.supportedLanguages.map((language) {
                      final isSelected = currentLang == language.code;
                      return PopupMenuItem<String>(
                        value: language.code,
                        height: 44.h,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              language.flag,
                              style: TextStyle(fontSize: 18.sp),
                            ),
                            SizedBox(width: 10.w),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  language.nameKey.tr,
                                  style: TextStyle(
                                    color: scheme.onSurface,
                                    fontSize: 13.sp,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  language.regionKey.tr,
                                  style: TextStyle(
                                    color:
                                        scheme.onSurface.withValues(alpha: 0.5),
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 16.w),
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                size: 16.sp,
                                color: _goldPrimary,
                              ),
                          ],
                        ),
                      );
                    }).toList();
                  },
                  child: _AppBarMedallionButton(
                    isHome: isHome,
                    child: Icon(
                      Icons.language,
                      color: isHome ? Colors.white : scheme.onSurface,
                      size: 18.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),

              // 4. Notification Bell — 3D Medallion
              CoachKeys.wrap(
                CoachKeys.notification,
                child: _NotificationBell(
                  isInverseColor: isHome,
                  onTapOverride: onNotificationTap,
                ),
              ),
              SizedBox(width: 10.w),

              // 5. User Avatar — 3D Traditional Gold Frame
              CoachKeys.wrap(
                CoachKeys.profile,
                child: GestureDetector(
                  onTap: onAvatarTap,
                  child: Container(
                    width: 38.r,
                    height: 38.r,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      // Gold Metallic Outer Rim Frame
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_goldLight, _goldPrimary, _goldDark],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isHome ? 0.35 : 0.15),
                          offset: const Offset(0, 2),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(1.5.r), // Gold Border Width
                    child: Container(
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(10.5.r),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: CachedNetworkImage(
                        imageUrl:
                            'https://png.pngtree.com/png-clipart/20240111/original/pngtree-cool-smile-profile-emoji-png-image_14087472.png',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Icon(
                          Icons.person,
                          color: Color.fromARGB(255, 195, 172, 0),
                          size: 18,
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.person,
                          color: Color.fromARGB(255, 195, 172, 0),
                          size: 18,
                        ),
                      ),
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

/// 3D Tactile Medallion Container for App Bar Actions
class _AppBarMedallionButton extends StatelessWidget {
  const _AppBarMedallionButton({
    required this.child,
    this.onTap,
    this.isHome = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool isHome;

  static const Color _goldPrimary = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.r,
        height: 36.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isHome
                ? [
                    Colors.white.withValues(alpha: 0.25),
                    Colors.white.withValues(alpha: 0.08),
                  ]
                : [
                    scheme.surface,
                    Color.lerp(scheme.surface, scheme.onSurface, 0.05)!,
                  ],
          ),
          border: Border.all(
            color: _goldPrimary.withValues(alpha: isHome ? 0.6 : 0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: isHome ? 0.3 : (isDark ? 0.35 : 0.08),
              ),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({this.isInverseColor = false, this.onTapOverride});
  final bool isInverseColor;
  final VoidCallback? onTapOverride;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget buildBellIcon(bool hasNotifications) {
      return _AppBarMedallionButton(
        isHome: isInverseColor,
        onTap: onTapOverride ??
            () => showNotificationsSheet(
                  context: context,
                  fetchNotifications: sl<FetchNotifications>(),
                ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              color: isInverseColor ? Colors.white : scheme.onSurface,
              size: 20.sp,
            ),
            if (hasNotifications)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 9.r,
                  height: 9.r,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isInverseColor ? Colors.black38 : Colors.white,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.error.withValues(alpha: 0.6),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    if (onTapOverride != null) {
      return buildBellIcon(false);
    }

    return FutureBuilder(
      future: sl<FetchNotifications>().call(const NoParams()),
      builder: (context, snapshot) {
        final hasNotifications = (snapshot.data?.isNotEmpty ?? false);
        return buildBellIcon(hasNotifications);
      },
    );
  }
}
