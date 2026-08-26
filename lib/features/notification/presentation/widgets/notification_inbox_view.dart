import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/entities/notification_action.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/entities/notification_category.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/entities/notification_message.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/entities/notification_query.dart';
import 'package:isi_steel_sales_mobile/features/notification/presentation/bloc/notification_inbox_cubit.dart';
import 'package:isi_steel_sales_mobile/features/notification/presentation/bloc/notification_inbox_state.dart';
import 'package:isi_steel_sales_mobile/features/notification/presentation/bloc/push_permission_cubit.dart';
import 'package:isi_steel_sales_mobile/features/notification/presentation/widgets/notification_category_style.dart';
import 'package:isi_steel_sales_mobile/features/notification/presentation/widgets/notification_tile.dart';
import 'package:isi_steel_sales_mobile/features/notification/presentation/widgets/push_permission_card.dart';

/// The inbox body, shared by the bell sheet and the full-screen route.
///
/// One widget for both because they are the same surface at two sizes — a sheet
/// on a phone tap, a screen when a deep link opens `app://notifications`. Two
/// copies would drift, and the swipe rules and empty states are exactly the
/// things that would drift silently.
///
/// Expects both a [NotificationInboxCubit] — already started — and a
/// [PushPermissionCubit] above it. The permission cubit is required rather than
/// optional because §14 puts the explainer and the declined banner *here*,
/// beside the notifications they are about, and a surface that silently omitted
/// them would be the one place a rep never learns why nothing is arriving.
class NotificationInboxView extends StatelessWidget {
  const NotificationInboxView({
    super.key,
    this.onOpenNotification,
    this.onOpenSettings,
    this.showTabs = true,
  });

  /// Called when a row is tapped, after it has been marked read.
  ///
  /// Navigation lives with the caller: this widget does not know whether it is
  /// inside a sheet that must pop first or a screen that can push.
  final void Function(NotificationMessage notification)? onOpenNotification;

  /// Opens the OS notification settings for this app, for the declined banner.
  final VoidCallback? onOpenSettings;

  /// Hidden in the sheet on a compact screen, where three tabs plus filter chips
  /// plus a list is more chrome than content.
  final bool showTabs;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationInboxCubit, NotificationInboxState>(
      // Only surface an error the rep asked for. A background catch-up failure
      // sets `status` and nothing else — interrupting somebody to report a sync
      // they did not request is noise, and offline is a normal state (ADR-002
      // §4).
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (context, state) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(state.errorMessage!)),
        );
        context.read<NotificationInboxCubit>().acknowledgeError();
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTabs) _ScopeTabs(scope: state.query.scope),
            _CategoryChips(selected: state.query.category),
            SizedBox(height: context.rh(8)),
            Expanded(
                child: _Body(
                    state: state,
                    onOpen: onOpenNotification,
                    onOpenSettings: onOpenSettings)),
          ],
        );
      },
    );
  }
}

/// Inbox · Action needed · History (§5.1, §5.4).
class _ScopeTabs extends StatelessWidget {
  const _ScopeTabs({required this.scope});

  final NotificationScope scope;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    Widget tab(NotificationScope value, String label) {
      final selected = value == scope;
      return Expanded(
        child: InkWell(
          onTap: () => context.read<NotificationInboxCubit>().setScope(value),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            // ≥48dp target height (FEATURE_UI_STANDARD §14).
            constraints: BoxConstraints(minHeight: context.rh(40)),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? scheme.primary.withValues(alpha: 0.1) : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              // Khmer runs longer than Latin and cannot break on spaces, so the
              // tab labels are the first place the type scale bites on a tablet.
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? scheme.primary : colors.textSecondary,
                fontSize: context.rsp(12),
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: context.rh(8)),
      child: Row(
        children: [
          tab(NotificationScope.inbox, 'notifications.tab.inbox'.tr),
          tab(NotificationScope.actionNeeded,
              'notifications.tab.action_needed'.tr),
          tab(NotificationScope.history, 'notifications.tab.history'.tr),
        ],
      ),
    );
  }
}

/// Category filter chips.
///
/// Drawn from [NotificationCategory.addressable] — the compile-time enum — and
/// **not** from the preferences API. That is the opposite of the settings screen
/// on purpose: §13 requires *settings* to render the server's list so a new
/// category is manageable without a release, while these chips need a
/// translated Khmer label and an icon, neither of which the server's English
/// `displayName` provides. A category this build has not heard of still appears
/// in the list itself, under `unknown`.
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected});

  final NotificationCategory? selected;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NotificationInboxCubit>();

    return SizedBox(
      height: context.rh(38),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _Chip(
            label: 'notifications.filter.all'.tr,
            selected: selected == null,
            onTap: () => cubit.setCategory(null),
          ),
          for (final category in NotificationCategory.addressable)
            _Chip(
              label: category.label,
              color: category.style(context).color,
              selected: selected == category,
              // Tapping the active chip clears it — the same affordance the
              // customer filter sheet uses, so the gesture means one thing
              // app-wide.
              onTap: () =>
                  cubit.setCategory(selected == category ? null : category),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = color ?? scheme.primary;

    return Padding(
      padding: EdgeInsets.only(right: context.rw(8)),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: accent.withValues(alpha: 0.16),
        labelStyle: TextStyle(
          fontSize: context.rsp(12),
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          color: selected ? accent : context.appColors.textSecondary,
        ),
        side: BorderSide(
          color: selected
              ? accent.withValues(alpha: 0.5)
              : context.appColors.border,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: context.rw(8),
          vertical: context.rh(6),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.onOpen,
    required this.onOpenSettings,
  });

  final NotificationInboxState state;
  final void Function(NotificationMessage notification)? onOpen;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PushPermissionCubit, PushPermissionState>(
      builder: (context, permission) => _build(context, permission),
    );
  }

  Widget _build(BuildContext context, PushPermissionState permission) {
    final cubit = context.read<NotificationInboxCubit>();

    // The permission surfaces sit above the list rather than on their own
    // screen, which is what §14 describes: the explainer arrives in context,
    // beside the notifications it is asking to accelerate.
    final permissionHeader = _permissionHeader(context, permission);

    if (!state.loadedOnce) {
      return Center(
        child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary),
      );
    }

    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: state.items.isEmpty
          // `AlwaysScrollableScrollPhysics` is what keeps pull-to-refresh
          // working on an empty inbox — which is precisely when a rep is most
          // likely to pull, wondering where their route went.
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (permissionHeader != null) permissionHeader,
                SizedBox(height: context.rh(80)),
                _EmptyState(scope: state.query.scope),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              // +1 when a permission surface is present, so it scrolls with the
              // list instead of pinning and stealing height from it.
              itemCount:
                  state.items.length + (permissionHeader == null ? 0 : 1),
              separatorBuilder: (_, __) => SizedBox(height: context.rh(2)),
              itemBuilder: (context, index) {
                if (permissionHeader != null) {
                  if (index == 0) return permissionHeader;
                  index -= 1;
                }
                final notification = state.items[index];
                return _SwipeableTile(
                  notification: notification,
                  actionInFlight: state.actionInFlightId == notification.id,
                  onOpen: onOpen,
                );
              },
            ),
    );
  }

  /// The §14 explainer, or the declined banner, or nothing.
  ///
  /// Resolved through `context.read` inside a guard rather than
  /// `context.watch<PushPermissionCubit?>()`: provider treats `T?` as a
  /// *different* type from `T`, so a nullable lookup never finds a
  /// `BlocProvider<PushPermissionCubit>` and would throw at runtime while
  /// analysing perfectly. Both call sites provide the cubit, so this is a plain
  /// lookup wrapped in a `BlocBuilder` for the rebuild.
  Widget? _permissionHeader(BuildContext context, PushPermissionState state) {
    if (state.showExplainer) {
      final permission = context.read<PushPermissionCubit>();
      return PushPermissionCard(
        onEnable: permission.accept,
        onDefer: permission.defer,
        busy: state.requesting,
      );
    }
    if (state.showDeclinedBanner) {
      return PushPermissionDeclinedBanner(onOpenSettings: onOpenSettings);
    }
    return null;
  }
}

/// A row, swipeable to dismiss where the spec allows it.
///
/// §5.4: an item with `requires_ack` **cannot be dismissed** — the server
/// answers 409 — so those rows are not wrapped in a [Dismissible] at all. A
/// swipe that animates the row away and then springs it back is a worse
/// explanation than a swipe that simply does not engage.
class _SwipeableTile extends StatelessWidget {
  const _SwipeableTile({
    required this.notification,
    required this.actionInFlight,
    required this.onOpen,
  });

  final NotificationMessage notification;
  final bool actionInFlight;
  final void Function(NotificationMessage notification)? onOpen;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NotificationInboxCubit>();

    final tile = NotificationTile(
      notification: notification,
      actionInFlight: actionInFlight,
      onTap: () {
        // Read, then navigate. Reading is not acting (§8.3): opening the record
        // clears the unread dot and nothing more, so a route assignment still
        // counts against the badge until it is acknowledged.
        cubit.open(notification);
        onOpen?.call(notification);
      },
      onAction: (action) => _runAction(context, cubit, action),
    );

    if (!notification.isDismissible) return tile;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: _DismissBackground(),
      onDismissed: (_) => cubit.dismiss(notification),
      child: tile,
    );
  }

  /// Runs an inline action, confirming first when it is destructive.
  ///
  /// §12: `destructive: true` must be confirmed. Rejecting a quotation from a
  /// lock screen is one mis-tap from a decision nobody meant to make, and the
  /// cubit refuses an unconfirmed destructive action outright rather than
  /// trusting every call site to remember.
  Future<void> _runAction(
    BuildContext context,
    NotificationInboxCubit cubit,
    NotificationAction action,
  ) async {
    var confirmed = true;

    if (action.destructive) {
      confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text('notifications.confirm.title'.tr),
              content: Text('notifications.confirm.body'
                  .trParams({'action': action.label})),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text('common.cancel'.tr),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(dialogContext).colorScheme.error,
                  ),
                  child: Text(action.label),
                ),
              ],
            ),
          ) ??
          false;
    }

    if (!confirmed) return;
    // The dialog awaited above may have outlived this element.
    if (!context.mounted) return;
    await cubit.runAction(notification, action, confirmed: confirmed);
  }
}

class _DismissBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: context.rw(20)),
      decoration: BoxDecoration(
        color: scheme.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(Icons.archive_rounded,
          color: scheme.error, size: context.rr(20)),
    );
  }
}

/// Per-tab empty copy.
///
/// Three messages rather than one, because "nothing here" means three different
/// things: an inbox with nothing new, no outstanding work (which is *good news*
/// and should read that way), and an empty history.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.scope});

  final NotificationScope scope;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final (icon, key) = switch (scope) {
      NotificationScope.inbox => (Icons.inbox_rounded, 'notifications.empty'),
      NotificationScope.actionNeeded => (
          Icons.task_alt_rounded,
          'notifications.empty_action_needed'
        ),
      NotificationScope.history => (
          Icons.history_rounded,
          'notifications.empty_history'
        ),
    };

    return Column(
      children: [
        Icon(icon, size: context.rr(40), color: colors.iconMuted),
        SizedBox(height: context.rh(12)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.rw(24)),
          child: Text(
            key.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textHint,
              fontSize: context.rsp(13),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
