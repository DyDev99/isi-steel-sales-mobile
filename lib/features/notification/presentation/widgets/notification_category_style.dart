import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/entities/notification_category.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/entities/notification_priority.dart';

/// How a category is drawn: an icon and an accent colour.
class NotificationCategoryStyle {
  const NotificationCategoryStyle({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

/// Icon, colour and label for a notification category.
///
/// ## Tokens only
///
/// Every colour comes from `context.appColors` or the active `ColorScheme`, so
/// the inbox restyles with the app in light and dark without a single raw hex —
/// `docs/skills/FEATURE_UI_STANDARD.md` §14 makes that a blocking rule, and a
/// hand-picked red here is exactly the kind of thing that reads fine in light
/// mode and disappears in dark.
///
/// ## The unknown category is drawn, not hidden
///
/// [NotificationCategory.unknown] gets a neutral bell rather than being filtered
/// out. The backend's category list grows independently of the app's release
/// cycle, and a notification a rep cannot see is far worse than one with a
/// generic icon — §5.1 keeps every notification findable precisely because a rep
/// who half-remembers being told something has to be able to look it up.
extension NotificationCategoryPresentation on NotificationCategory {
  NotificationCategoryStyle style(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return switch (this) {
      NotificationCategory.assignment => NotificationCategoryStyle(
          icon: Icons.route_rounded, color: colors.accentPurple),
      NotificationCategory.quote => NotificationCategoryStyle(
          icon: Icons.request_quote_rounded, color: colors.info),
      NotificationCategory.order => NotificationCategoryStyle(
          icon: Icons.receipt_long_rounded, color: scheme.primary),
      NotificationCategory.finance => NotificationCategoryStyle(
          icon: Icons.account_balance_wallet_rounded, color: colors.warning),
      NotificationCategory.kpi => NotificationCategoryStyle(
          icon: Icons.insights_rounded, color: colors.success),
      NotificationCategory.approval => NotificationCategoryStyle(
          icon: Icons.fact_check_rounded, color: colors.warningAlt),
      NotificationCategory.account => NotificationCategoryStyle(
          icon: Icons.storefront_rounded, color: colors.brandNavy),
      NotificationCategory.system => NotificationCategoryStyle(
          icon: Icons.settings_suggest_rounded, color: colors.iconMuted),
      NotificationCategory.announce => NotificationCategoryStyle(
          icon: Icons.campaign_rounded, color: colors.info),
      NotificationCategory.security => NotificationCategoryStyle(
          icon: Icons.shield_rounded, color: scheme.error),
      NotificationCategory.unknown => NotificationCategoryStyle(
          icon: Icons.notifications_none_rounded, color: colors.iconMuted),
    };
  }

  /// The chip and section label.
  ///
  /// A local translation, not the server's `displayName`. The two serve
  /// different surfaces: the **settings screen** must render the server's list
  /// verbatim so a category added server-side appears without a release (§13),
  /// while these filter chips are drawn from the enum and can be translated
  /// properly — including into Khmer, which the server's English `displayName`
  /// would not be.
  String get label => switch (this) {
        NotificationCategory.assignment =>
          'notifications.category.assignment'.tr,
        NotificationCategory.quote => 'notifications.category.quote'.tr,
        NotificationCategory.order => 'notifications.category.order'.tr,
        NotificationCategory.finance => 'notifications.category.finance'.tr,
        NotificationCategory.kpi => 'notifications.category.kpi'.tr,
        NotificationCategory.approval => 'notifications.category.approval'.tr,
        NotificationCategory.account => 'notifications.category.account'.tr,
        NotificationCategory.system => 'notifications.category.system'.tr,
        NotificationCategory.announce => 'notifications.category.announce'.tr,
        NotificationCategory.security => 'notifications.category.security'.tr,
        NotificationCategory.unknown => 'notifications.category.other'.tr,
      };
}

/// The accent for a priority tier, for the leading stripe on a P1.
///
/// Only P1 is marked. §5.2 makes P1 the tier that bypasses both quiet hours and
/// the rep's own opt-out — a route cancelled at midnight for an 06:00 start —
/// and giving every tier its own colour would spend the emphasis that makes P1
/// legible at a glance.
extension NotificationPriorityPresentation on NotificationPriority {
  Color? accent(BuildContext context) => this == NotificationPriority.p1
      ? Theme.of(context).colorScheme.error
      : null;
}
