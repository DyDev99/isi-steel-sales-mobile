import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/lead_usecase.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/utils/colors.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/presentation/services/coach_keys.dart';
import 'package:isi_steel_sales_mobile/features/localization/presentation/bloc/language_cubit.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/usecases/fetch_notifications.dart';
import 'package:isi_steel_sales_mobile/features/notification/presentation/screen/notifications_sheet.dart';

class MainAppBar extends StatelessWidget {
  const MainAppBar({
    super.key,
    required this.title,
    required this.onAvatarTap,
    required this.currentTabIndex,
    this.onBackToHomeTap,
    this.onNotificationTap, // Added callback for the notification icon
  });

  final String title;
  final VoidCallback onAvatarTap;
  final int currentTabIndex;
  final VoidCallback? onBackToHomeTap;
  final VoidCallback? onNotificationTap;

  void _showLanguageMenu(BuildContext context) {
    final languageCubit = context.read<LanguageCubit>();
    String currentLang = languageCubit.state.languageCode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final scheme = Theme.of(context).colorScheme;
            final colors = context.appColors;
            Widget buildLangCard({
              required String label,
              required String subLabel,
              required String code,
              required String flag,
            }) {
              final isSelected = currentLang == code;

              return Padding(
                padding: EdgeInsets.only(bottom: 4.2.h),
                child: InkWell(
                  onTap: () async {
                    if (code == currentLang) {
                      Navigator.pop(sheetContext);
                      return;
                    }
                    setModalState(() => currentLang = code);
                    await languageCubit.changeLanguage(code);
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                  borderRadius: BorderRadius.circular(16.r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? scheme.surface
                          : scheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isSelected ? scheme.primary : colors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(flag, style: TextStyle(fontSize: 22.sp)),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  color: scheme.onSurface,
                                  fontSize: 16.sp,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                              Text(
                                subLabel,
                                style: TextStyle(
                                  color: scheme.onSurface.withValues(alpha: 0.5),
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 20.w,
                          height: 20.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? scheme.primary : colors.border,
                              width: 2,
                            ),
                          ),
                          padding: EdgeInsets.all(3.w),
                          child: isSelected
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: scheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 18.h),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 5.h,
                        decoration: BoxDecoration(
                          color: colors.border,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 21.6.h),
                    Text(
                      'language.choose_title'.tr,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 3.6.h),
                    Text(
                      'language.choose_subtitle'.tr,
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 21.6.h),
                    buildLangCard(
                      label: 'language.english'.tr,
                      subLabel: 'language.english_region'.tr,
                      code: 'en',
                      flag: '🇺🇸',
                    ),
                    buildLangCard(
                      label: 'language.khmer'.tr,
                      subLabel: 'language.khmer_region'.tr,
                      code: 'kh',
                      flag: '🇰🇭',
                    ),
                    SizedBox(height: 10.8.h),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

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
            : Border(bottom: BorderSide(color: colors.border)),
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
                          borderRadius:
                              BorderRadius.circular(12.r),
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

              // 3. Language Selector — coach anchor.
              CoachKeys.wrap(
                CoachKeys.language,
                child: IconButton(
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
                  onPressed: () => _showLanguageMenu(context),
                ),
              ),
              SizedBox(width: 16.w),

              // 4. Notification Bell — coach anchor.
              CoachKeys.wrap(
                CoachKeys.notification,
                child: _NotificationBell(
                  isInverseColor: isHome,
                  onTapOverride: onNotificationTap, // Pass the override callback down
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
                      color: isHome ? Colors.white.withValues(alpha: 0.2) : null,
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
  
  /// If provided, bypasses the notification fetch and triggers this callback instead (e.g. for guest login)
  final VoidCallback? onTapOverride;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // If an override is provided (like a login prompt for guests), render a simple icon 
    // without triggering the FutureBuilder API call.
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

    // Default behavior for authenticated users
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