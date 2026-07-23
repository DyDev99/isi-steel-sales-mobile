import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

/// Quick-action row for guests. Every card is a locked affordance: tapping any
/// of them calls [onRequireLogin] rather than performing the action.
///
/// **No `CoachKeys` here, deliberately.** The authenticated dashboard tags its
/// real quick-action cards with static `CoachKeys` GlobalKeys for the onboarding
/// spotlight. Reusing those keys on the guest cards put the *same* GlobalKey in
/// two subtrees at once — when the Home tab's `StreamBuilder` swaps guest →
/// dashboard on login, the duplicate key is reparented mid-layout and Flutter
/// throws "Duplicate GlobalKeys / RenderObject mutated during layout". A guest
/// never sees the coaching tutorial, so the keys simply don't belong here.
class GuestQuickActionsSection extends StatelessWidget {
  const GuestQuickActionsSection({super.key, required this.onRequireLogin});

  /// Triggered whenever a guest taps an action that requires an account.
  final VoidCallback onRequireLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 10.h),
            child: Text(
              'shell.quick_actions'.tr,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color:
                    theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6) ??
                        theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.assignment_outlined,
                  tint: theme.colorScheme.primary,
                  label: 'shell.new_quote'.tr,
                  onTap: onRequireLogin,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _ActionCard(
                  icon: Icons.bar_chart_rounded,
                  tint: context.appColors.success,
                  label: 'shell.new_lead'.tr,
                  onTap: onRequireLogin,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _ActionCard(
                  icon: Icons.inventory_2_outlined,
                  tint: context.appColors.warning,
                  label: 'shell.depot_stock'.tr,
                  onTap: onRequireLogin,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _ActionCard(
                  icon: Icons.person_add_alt_1_outlined,
                  tint: context.appColors.accentPurple,
                  label: 'shell.add_customer'.tr,
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

/// A single locked action tile. Colours come from theme tokens so the row works
/// in dark mode — the previous hardcoded `Color(0xFF…)` values did not.
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.tint,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'shell.login_required_label'.trParams({'feature': label}),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: colors.border),
              boxShadow: colors.cardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38.r,
                  height: 38.r,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(child: Icon(icon, color: tint, size: 19.r)),
                ),
                SizedBox(height: 8.h),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
