import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

class GuestMyWorkGrid extends StatelessWidget {
  const GuestMyWorkGrid({super.key, required this.onRequireLogin});

  final VoidCallback onRequireLogin;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.pagePadding,
        vertical: context.rh(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section Title Header with Gold Accent Indicator
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: context.rh(14)),
            child: Row(
              children: [
                Container(
                  width: 4.w,
                  height: context.rh(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC88D2B),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(width: context.rw(8)),
                Text(
                  'shell.my_work'.tr.toUpperCase(),
                  style: TextStyle(
                    // Matches _SectionHeader in my_work_grid_section.dart — the
                    // guest and authenticated home must not diverge. See the
                    // note there for why the base widens above compact.
                    fontSize: context
                        .rsp(context.responsive(compact: 14.0, medium: 16.0)),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: appColors.textSecondary,
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
          SizedBox(height: context.rh(12)),
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
              SizedBox(width: context.rw(12)),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final appColors = context.appColors;
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: 'shell.login_required_label'.trParams({'feature': label}),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            height: context.rh(124),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: isDark ? appColors.card : scheme.surface,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color:
                    (isDark ? const Color(0xFFF3E5AB) : const Color(0xFFE5B54E))
                        .withValues(alpha: isDark ? 0.35 : 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? appColors.shadowColor.withValues(alpha: 0.3)
                      : const Color(0xFFC88D2B).withValues(alpha: 0.12),
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
                        color: tint.withValues(alpha: isDark ? 0.35 : 0.25),
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
                        color: tint.withValues(alpha: isDark ? 0.35 : 0.25),
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
                        width: context.rr(48),
                        height: context.rr(48),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tint.withValues(alpha: isDark ? 0.18 : 0.12),
                          border: Border.all(
                            color: tint.withValues(alpha: isDark ? 0.45 : 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            icon,
                            color: tint,
                            size: context.rr(22),
                          ),
                        ),
                      ),
                      SizedBox(height: context.rh(10)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: context.rsp(14),
                            fontWeight: FontWeight.w800,
                            color: appColors.textPrimary,
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
                          fontSize: context.rsp(10),
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
