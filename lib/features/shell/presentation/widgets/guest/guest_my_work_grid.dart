import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

class GuestMyWorkGrid extends StatelessWidget {
  const GuestMyWorkGrid({super.key, required this.onRequireLogin});

  final VoidCallback onRequireLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section Title Header with Gold Accent Indicator
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 14.h),
            child: Row(
              children: [
                Container(
                  width: 4.w,
                  height: 16.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC88D2B),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'shell.my_work'.tr.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.7) ??
                        theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          // 2x2 Grid Layout
          Row(
            children: [
              Expanded(
                child: _WorkCard(
                  label: 'Add customer',
                  icon: Icons.person_add_alt_1_outlined,
                  tint: const Color(0xFF4285F4),
                  onTap: onRequireLogin,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _WorkCard(
                  label: 'shell.my_visits'.tr,
                  icon: Icons.assignment_turned_in_outlined,
                  tint: const Color(0xFF34A853),
                  badgeText: '3 today',
                  badgeColor: const Color(0xFFC88D2B),
                  onTap: onRequireLogin,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _WorkCard(
                  label: 'shell.my_customers'.tr,
                  icon: Icons.people_alt_outlined,
                  tint: const Color(0xFFEA4335),
                  onTap: onRequireLogin,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _WorkCard(
                  label: 'shell.my_quotes_orders'.tr,
                  icon: Icons.description_outlined,
                  tint: const Color(0xFFFBBC05),
                  onTap: onRequireLogin,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkCard extends StatelessWidget {
  const _WorkCard({
    required this.label,
    required this.icon,
    required this.tint,
    required this.onTap,
    this.badgeText,
    this.badgeColor,
  });

  final String label;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;
  final String? badgeText;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'shell.login_required_label'.trParams({'feature': label}),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            height: 124.h,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: const Color(0xFFE5B54E).withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC88D2B).withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Top-left corner decorative ring
                Positioned(
                  top: -18.r,
                  left: -18.r,
                  child: Container(
                    width: 48.r,
                    height: 48.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: tint.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                // Bottom-right corner decorative ring
                Positioned(
                  bottom: -18.r,
                  right: -18.r,
                  child: Container(
                    width: 48.r,
                    height: 48.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: tint.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                // Card Main Content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Circular Icon Shape
                      Container(
                        width: 48.r,
                        height: 48.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tint.withValues(alpha: 0.12),
                          border: Border.all(
                            color: tint.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            icon,
                            color: tint,
                            size: 22.r,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E293B),
                            letterSpacing: -0.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Top-right pill badge (e.g., "3 today")
                if (badgeText != null)
                  Positioned(
                    top: 10.h,
                    right: 10.w,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: badgeColor ?? scheme.secondary,
                        borderRadius: BorderRadius.circular(100.r),
                        boxShadow: [
                          BoxShadow(
                            color: (badgeColor ?? scheme.secondary)
                                .withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        badgeText!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
