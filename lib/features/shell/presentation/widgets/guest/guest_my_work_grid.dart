import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

/// "My work" preview for guests — a 2×2 grid of the tools they unlock by signing
/// in. Every card is locked: a tap calls [onRequireLogin].
///
/// **No `CoachKeys` here, deliberately** — see the note in
/// `guest_quick_action_grid.dart`. Sharing the dashboard's static GlobalKeys is
/// what caused the "Duplicate GlobalKeys / RenderObject mutated during layout"
/// crash when the Home tab swapped guest → dashboard on login.
class GuestMyWorkGrid extends StatelessWidget {
  const GuestMyWorkGrid({super.key, required this.onRequireLogin});

  /// Triggered whenever a guest taps an action that requires an account.
  final VoidCallback onRequireLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
            child: Text(
              'MY WORK',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
                color:
                    theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6) ??
                        theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _WorkCard(
                  label: 'My Leads',
                  icon: Icons.layers_outlined,
                  tint: theme.colorScheme.primary,
                  badgeText: '1 due',
                  isActive: false,
                  onTap: onRequireLogin,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _WorkCard(
                  label: 'My Visits',
                  icon: Icons.assignment_turned_in_outlined,
                  tint: context.appColors.success,
                  badgeText: '3 today',
                  isActive: true,
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
                  label: 'My Customers',
                  icon: Icons.people_alt_outlined,
                  tint: context.appColors.warningAlt,
                  isActive: false,
                  onTap: onRequireLogin,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _WorkCard(
                  label: 'My Quotes & Orders',
                  icon: Icons.description_outlined,
                  tint: context.appColors.warning,
                  isActive: false,
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
    required this.isActive,
    required this.onTap,
    this.badgeText,
  });

  final String label;
  final IconData icon;
  final Color tint;
  final bool isActive;
  final VoidCallback onTap;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: '$label. Login required.',
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 116.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: colors.border),
              boxShadow: colors.cardShadow,
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 46.r,
                        height: 46.r,
                        decoration: BoxDecoration(
                          color: tint.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child:
                            Center(child: Icon(icon, color: tint, size: 22.r)),
                      ),
                      SizedBox(height: 12.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
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
                // Badge pinned to the card's own top-right corner. The previous
                // version positioned it at `right: -32.w` off the icon, which
                // pushed it outside the card and looked broken.
                if (badgeText != null)
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: scheme.secondary,
                        borderRadius: BorderRadius.circular(100.r),
                      ),
                      child: Text(
                        badgeText!,
                        style: TextStyle(
                          color: scheme.onSecondary,
                          fontSize: 9.sp,
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
