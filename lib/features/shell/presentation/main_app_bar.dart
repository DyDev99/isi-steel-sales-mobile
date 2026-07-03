import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/usecases/fetch_notifications.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/lead_usecase.dart';
import 'package:isi_steel_sales_mobile/features/notification/presentation/screen/notifications_sheet.dart';

/// Persistent top bar owned by [MainShell] — stays visible (and functional)
/// across every tab, unlike the old per-screen header/bell that disappeared
/// whenever you left the Home tab.
class MainAppBar extends StatelessWidget {
  const MainAppBar({super.key, required this.title, required this.onAvatarTap});

  final String title;
  final VoidCallback onAvatarTap;

  // Helper method to show the language change options
 void _showLanguageMenu(BuildContext context) {
    // Track current selection locally for UI presentation 
    // (Hook this up to your real state manager later like Bloc/Provider)
    String currentLang = 'en'; 

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Allows custom shapes & backgrounds
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Widget buildLangCard({
              required String label,
              required String subLabel,
              required String code,
              required String flag,
            }) {
              final isSelected = currentLang == code;
              
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: InkWell(
                  onTap: () {
                    setModalState(() => currentLang = code);
                    // TODO: Trigger your actual localization switch here
                    Future.delayed(const Duration(milliseconds: 250), () {
                      if (context.mounted) Navigator.pop(context);
                    });
                  },
                  borderRadius: BorderRadius.circular(16.r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: isSelected ? Vibe.bg : Vibe.violet.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isSelected ? Vibe.violet : Vibe.stroke,
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
                                  color: Vibe.text,
                                  fontSize: 16.sp,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                ),
                              ),
                              Text(
                                subLabel,
                                style: TextStyle(
                                  color: Vibe.text.withOpacity(0.5),
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
                              color: isSelected ? Vibe.violet : Vibe.stroke,
                              width: 2,
                            ),
                          ),
                          padding: EdgeInsets.all(3.w),
                          child: isSelected
                              ? Container(
                                  decoration: const BoxDecoration(
                                    color: Vibe.violet,
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
              decoration: const BoxDecoration(
                color: Vibe.bg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
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
                          color: Vibe.stroke,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'Choose Language',
                      style: TextStyle(
                        color: Vibe.text,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Select your preferred language interface',
                      style: TextStyle(
                        color: Vibe.text.withOpacity(0.5),
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    buildLangCard(
                      label: 'English',
                      subLabel: 'United States',
                      code: 'en',
                      flag: '🇺🇸',
                    ),
                    buildLangCard(
                      label: 'ភាសាខ្មែរ',
                      subLabel: 'Cambodia',
                      code: 'km',
                      flag: '🇰🇭',
                    ),
                    SizedBox(height: 12.h),
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
    return SafeArea(
      bottom: false,
      child: Container(
        height: 56.h,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        decoration: const BoxDecoration(
          color: Vibe.bg,
          border: Border(bottom: BorderSide(color: Vibe.stroke)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Vibe.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 20.w),
                  IconButton(
                    icon: const Icon(Icons.language, color: Vibe.text, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    style: const ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => _showLanguageMenu(context),
                  ),
                ],
              ),
            ),
            const _NotificationBell(),
            SizedBox(width: 12.w),
            GestureDetector(
              onTap: onAvatarTap,
              child: Container(
                width: 36.w,
                height: 36.h,
                decoration: BoxDecoration(
                  gradient: Vibe.cta,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  'https://png.pngtree.com/png-clipart/20240111/original/pngtree-cool-smile-profile-emoji-png-image_14087472.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.person, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: sl<FetchNotifications>().call(const NoParams()),
      builder: (context, snapshot) {
        final hasNotifications = (snapshot.data?.isNotEmpty ?? false);
        return InkWell(
          onTap: () => showNotificationsSheet(context: context, fetchNotifications: sl<FetchNotifications>()),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, color: Vibe.text, size: 24),
                if (hasNotifications)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Vibe.danger, shape: BoxShape.circle),
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