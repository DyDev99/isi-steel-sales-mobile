import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isi_steel_sales_mobile/core/localization/active_language.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/entities/notification_action.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/entities/notification_message.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/entities/notification_state.dart';
import 'package:isi_steel_sales_mobile/features/notification/presentation/widgets/notification_category_style.dart';

/// One row in the inbox.
///
/// Renders the §5.1 state vocabulary honestly:
///
/// | state | treatment |
/// |---|---|
/// | `unread` | bold, unread dot |
/// | `read` | normal weight |
/// | `actioned` | normal, with a tick |
/// | `expired` | greyed, "no longer current" |
/// | `resolved_elsewhere` | greyed, "already actioned by someone else" |
///
/// The two greyed states carry an **explanatory subtitle**, not just a colour
/// change. A rep who acknowledged something offline and finds it closed needs to
/// know that somebody else decided — a silently greyed row reads as a bug in the
/// app rather than as information.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onAction,
    this.actionInFlight = false,
  });

  final NotificationMessage notification;
  final VoidCallback? onTap;

  /// Fired for an inline action button. Null hides the button row entirely —
  /// used by the compact sheet, where three buttons per row would not fit.
  final void Function(NotificationAction action)? onAction;

  /// One action at a time, app-wide: an `api_call` is a real decision and the
  /// client cannot undo a double-fire.
  final bool actionInFlight;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final style = notification.category.style(context);
    final isStale = notification.state.isStale;

    // Greyed states fade the whole row rather than restyling every child.
    final foreground = isStale ? colors.textHint : colors.textPrimary;
    final secondary = isStale ? colors.textDisabled : colors.textSecondary;

    final actions =
        onAction == null ? const <NotificationAction>[] : notification.actions;

    return Semantics(
      // The unread state is a visual dot; a screen reader needs it said.
      label: notification.isUnread
          ? '${'notifications.status.unread'.tr}. ${notification.title}'
          : notification.title,
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.rw(12),
            vertical: context.rh(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Leading(
                icon: style.icon,
                color: isStale ? colors.iconMuted : style.color,
                // §5.2: only P1 gets a marker, so the emphasis still means
                // something when it appears.
                urgent:
                    notification.priority.accent(context) != null && !isStale,
              ),
              SizedBox(width: context.rw(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: foreground,
                              fontSize: context.rsp(14),
                              // Bold while unread (§5.1). The one visual
                              // difference a rep scans for.
                              fontWeight: notification.isUnread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ),
                        SizedBox(width: context.rw(8)),
                        Text(
                          _relativeTime(notification.createdAt),
                          style: TextStyle(
                            color: colors.textHint,
                            fontSize: context.rsp(11),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (notification.isUnread) ...[
                          SizedBox(width: context.rw(6)),
                          Container(
                            margin: EdgeInsets.only(top: context.rh(4)),
                            width: context.rr(7),
                            height: context.rr(7),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: context.rh(4)),
                    Text(
                      notification.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondary,
                        fontSize: context.rsp(12.5),
                        height: 1.4,
                      ),
                    ),
                    if (_statusNote(notification) case final note?) ...[
                      SizedBox(height: context.rh(6)),
                      Text(
                        note,
                        style: TextStyle(
                          color: colors.textHint,
                          fontSize: context.rsp(11.5),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (notification.isOutstandingAction) ...[
                      SizedBox(height: context.rh(8)),
                      _AckPill(),
                    ],
                    if (actions.isNotEmpty) ...[
                      SizedBox(height: context.rh(10)),
                      _ActionRow(
                        actions: actions,
                        onAction: onAction!,
                        disabled: actionInFlight,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The explanatory subtitle a closed item carries.
  ///
  /// §5.1 tables one per terminal state, and they are not decoration: a rep
  /// looking at a greyed row needs to know whether their moment passed, somebody
  /// else decided, or they themselves already dealt with it.
  String? _statusNote(NotificationMessage notification) =>
      switch (notification.state) {
        NotificationState.expired => 'notifications.note.expired'.tr,
        NotificationState.resolvedElsewhere =>
          'notifications.note.resolved_elsewhere'.tr,
        NotificationState.actioned => 'notifications.note.actioned'.tr,
        NotificationState.dismissed => 'notifications.note.dismissed'.tr,
        NotificationState.unread || NotificationState.read => null,
      };

  /// A compact relative age, falling back to a localised date past a week.
  ///
  /// `DateFormat.yMMMd` is given the active language explicitly. The
  /// no-argument constructors silently fall back to `en_US` and would render
  /// English dates to a Khmer-reading rep — the exact failure
  /// `AppBootstrapService` initialises `intl` locale data to prevent.
  String _relativeTime(DateTime createdAt) {
    final now = DateTime.now().toUtc();
    final age = now.difference(createdAt);

    if (age.inMinutes < 1) return 'notifications.time.now'.tr;
    if (age.inMinutes < 60) {
      return 'notifications.time.minutes'.trParams({'n': age.inMinutes});
    }
    if (age.inHours < 24) {
      return 'notifications.time.hours'.trParams({'n': age.inHours});
    }
    if (age.inDays < 7) {
      return 'notifications.time.days'.trParams({'n': age.inDays});
    }
    return DateFormat.MMMd(ActiveLanguage.code).format(createdAt.toLocal());
  }
}

class _Leading extends StatelessWidget {
  const _Leading({
    required this.icon,
    required this.color,
    required this.urgent,
  });

  final IconData icon;
  final Color color;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: context.rr(38),
      height: context.rr(38),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(11),
        border: urgent
            ? Border.all(
                color: scheme.error.withValues(alpha: 0.55), width: 1.4)
            : null,
      ),
      child: Icon(icon, size: context.rr(19), color: color),
    );
  }
}

/// The "needs your acknowledgement" marker.
///
/// Deliberately says *acknowledgement*, not *unread*. §8.3: reading is not
/// acting, and this pill stays on a row the rep has already opened — which is
/// the whole point, because that item still escalates to a supervisor until
/// `POST /action` lands.
class _AckPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rw(8),
        vertical: context.rh(3),
      ),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pending_actions_rounded,
              size: context.rr(12), color: colors.warning),
          SizedBox(width: context.rw(4)),
          // `Flexible`, not a bare `Text`. The row is `mainAxisSize: min`, so an
          // unbounded child overflows the moment the label is longer than the
          // space left beside the icon — which Khmer is, being longer than Latin
          // and unable to break on spaces. Verified as a 28px overflow at 390pt
          // before this was added.
          Flexible(
            child: Text(
              // Its own string, not the tab's label. The two mean different
              // things — the tab is a place, the pill is a claim about this one
              // row — and sharing a key made "Action needed" appear twice on
              // screen with no way to tell them apart.
              'notifications.needs_ack'.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.warning,
                fontSize: context.rsp(10.5),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The inline action buttons (§12).
///
/// The list is already capped at three by the mapper, so nothing is truncated
/// here — the cap lives in one place rather than being re-applied per surface.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.actions,
    required this.onAction,
    required this.disabled,
  });

  final List<NotificationAction> actions;
  final void Function(NotificationAction action) onAction;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: context.rw(8),
      runSpacing: context.rh(6),
      children: [
        for (final action in actions)
          // Destructive actions are outlined in the error colour so "Reject"
          // never looks like "Approve" at a glance. Confirmation itself is the
          // caller's job — §12 requires it, and a dialog cannot be raised from
          // inside a list tile without owning the route.
          TextButton(
            onPressed: disabled ? null : () => onAction(action),
            style: TextButton.styleFrom(
              minimumSize: Size(0, context.rh(34)),
              padding: EdgeInsets.symmetric(horizontal: context.rw(14)),
              foregroundColor:
                  action.destructive ? scheme.error : scheme.primary,
              backgroundColor:
                  (action.destructive ? scheme.error : scheme.primary)
                      .withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              // Server-localised already, via `Accept-Language`. Never `.tr`.
              action.label,
              style: TextStyle(
                fontSize: context.rsp(12),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}
