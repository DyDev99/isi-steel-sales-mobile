import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/utils/colors.dart';
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
        border:
            isHome ? null : Border(bottom: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(8.w, 12.h, 18.w, 12.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Back Button (Conditionally rendered)
              if (!isHome) ...[
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: scheme.onSurface,
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onBackToHomeTap,
                ),
                SizedBox(width: 12.w),
              ],

              // 2. Main Content (Logo or Title) - Takes up remaining flexible space
              Expanded(
                child: isHome
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: Image.asset(
                            'assets/logos/isi_main_screen_logo.png',
                            height: 40.h,
                            width: 140.w,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : Text(
                        title,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
              ),
              SizedBox(width: 16.w),

              // 3. Language Selector Popup Menu — coach anchor.
              CoachKeys.wrap(
                CoachKeys.language,
                child: PopupMenuButton<String>(
                  offset: const Offset(0, 36),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  color: scheme.surface,
                  icon: Icon(
                    Icons.language,
                    color: isHome ? Colors.white : scheme.onSurface,
                    size: 20,
                  ),
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
                        height: 42.h,
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
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  language.regionKey.tr,
                                  style: TextStyle(
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.5),
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
                                color: scheme.primary,
                              ),
                          ],
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              SizedBox(width: 16.w),

              // 4. Notification Bell — coach anchor.
              CoachKeys.wrap(
                CoachKeys.notification,
                child: _NotificationBell(
                  isInverseColor: isHome,
                  onTapOverride: onNotificationTap,
                ),
              ),
              SizedBox(width: 16.w),

              // 5. User Avatar — coach anchor.
              CoachKeys.wrap(
                CoachKeys.profile,
                child: GestureDetector(
                  onTap: onAvatarTap,
                  child: Container(
                    width: 36.w,
                    height: 36.h,
                    decoration: BoxDecoration(
                      gradient: isHome ? null : AppColors.ctaGradient,
                      color:
                          isHome ? Colors.white.withValues(alpha: 0.2) : null,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CachedNetworkImage(
                      imageUrl:
                          'https://png.pngtree.com/png-clipart/20240111/original/pngtree-cool-smile-profile-emoji-png-image_14087472.png',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Icon(Icons.person,
                          color: Colors.white, size: 18),
                      errorWidget: (context, url, error) => const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 18),
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

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({this.isInverseColor = false, this.onTapOverride});
  final bool isInverseColor;
  final VoidCallback? onTapOverride;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (onTapOverride != null) {
      return InkWell(
        onTap: onTapOverride,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            Icons.notifications_none_rounded,
            color: isInverseColor ? Colors.white : scheme.onSurface,
            size: 24,
          ),
        ),
      );
    }

    return FutureBuilder(
      future: sl<FetchNotifications>().call(const NoParams()),
      builder: (context, snapshot) {
        final hasNotifications = (snapshot.data?.isNotEmpty ?? false);
        return InkWell(
          onTap: () => showNotificationsSheet(
              context: context, fetchNotifications: sl<FetchNotifications>()),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  color: isInverseColor ? Colors.white : scheme.onSurface,
                  size: 24,
                ),
                if (hasNotifications)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: scheme.error, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}