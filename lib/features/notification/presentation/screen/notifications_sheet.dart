import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/entities/notification_item.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/usecases/fetch_notifications.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/app_bottom_sheet.dart';

/// Opens the notifications sheet.
///
/// Goes through [showAppBottomSheet] rather than calling `showModalBottomSheet`
/// directly: that shared helper owns the sheet chrome every other sheet in the
/// app uses (surface colour, 20pt corner radius, drag handle, keyboard inset,
/// safe area, tablet width). This sheet previously re-declared its own and had
/// drifted to a 22pt radius with no handle — visibly a different sheet from the
/// language and theme pickers it sits beside.
Future<void> showNotificationsSheet({
  required BuildContext context,
  required FetchNotifications fetchNotifications,
  bool isGuest = false,
  VoidCallback? onLogin,
}) {
  return showAppBottomSheet<void>(
    context: context,
    heightFactor: 0.7,
    builder: (_) => _NotificationsSheet(
      fetchNotifications: fetchNotifications,
      isGuest: isGuest,
      onLogin: onLogin,
    ),
  );
}

class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet({
    required this.fetchNotifications,
    this.isGuest = false,
    this.onLogin,
  });

  final FetchNotifications fetchNotifications;
  final bool isGuest;
  final VoidCallback? onLogin;

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  // Store the future here to prevent re-fetching on every setState/filter change
  late Future<List<NotificationItem>> _notificationsFuture;

  // Null means "All" notifications are selected
  NotificationKind? _selectedFilter;

  @override
  void initState() {
    super.initState();
    if (!widget.isGuest) {
      _notificationsFuture = widget.fetchNotifications(const NoParams());
    }
  }

  ({IconData icon, Color color}) _style(
      BuildContext context, NotificationKind kind) {
    final colors = context.appColors;
    return switch (kind) {
      NotificationKind.creditApproved => (
          icon: Icons.verified_rounded,
          color: colors.success
        ),
      NotificationKind.customerAssigned => (
          icon: Icons.person_add_alt_1_rounded,
          color: colors.accentPurple
        ),
      NotificationKind.opportunityMoved => (
          icon: Icons.trending_up_rounded,
          color: colors.warning
        ),
      NotificationKind.creditPending => (
          icon: Icons.hourglass_top_rounded,
          color: colors.warning
        ),
      NotificationKind.followUpDue => (
          icon: Icons.event_repeat_rounded,
          color: Theme.of(context).colorScheme.error
        ),
    };
  }

  /// Filter-chip label for [kind].
  ///
  /// Plain `.tr` lookups: [LocalizationService.translate] returns the *key* for
  /// a missing entry, never an empty string, so the previous
  /// `'…'.tr.isEmpty ? 'Approved' : '…'.tr` guards could never fire — a missing
  /// key rendered as `notifications.filter.approved` on screen regardless. The
  /// keys are present in both bundles instead.
  String _filterLabel(NotificationKind kind) => switch (kind) {
        NotificationKind.creditApproved => 'notifications.filter.approved'.tr,
        NotificationKind.customerAssigned => 'notifications.filter.assigned'.tr,
        NotificationKind.opportunityMoved =>
          'notifications.filter.opportunity'.tr,
        NotificationKind.creditPending => 'notifications.filter.pending'.tr,
        NotificationKind.followUpDue => 'notifications.filter.followup'.tr,
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return LocalizedBuilder(
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            context.pagePadding,
            context.rh(16),
            context.pagePadding,
            context.rh(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'notifications.title'.tr,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: context.rsp(17),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: context.rh(12)),

              // Filter Chips UI (Only show if not a guest)
              if (!widget.isGuest) ...[
                _FilterChips(
                  selected: _selectedFilter,
                  labelFor: _filterLabel,
                  colorFor: (kind) => _style(context, kind).color,
                  onSelected: (kind) =>
                      setState(() => _selectedFilter = kind),
                ),
                SizedBox(height: context.rh(12)),
              ],

              Expanded(
                child: widget.isGuest
                    ? _buildGuestMessage(context)
                    : FutureBuilder<List<NotificationItem>>(
                        future: _notificationsFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(
                              child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.primary),
                            );
                          }

                          // Apply the active filter here
                          final allItems = snapshot.data!;
                          final items = _selectedFilter == null
                              ? allItems
                              : allItems
                                  .where((item) => item.kind == _selectedFilter)
                                  .toList();

                          if (items.isEmpty) {
                            return Center(
                              child: Text(
                                _selectedFilter == null
                                    ? 'notifications.empty'.tr
                                    : 'notifications.filter.no_results'.tr,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colors.textHint,
                                  fontSize: context.rsp(13.5),
                                ),
                              ),
                            );
                          }

                          // Phone keeps the flat chronological list; a 390pt
                          // column split three ways is unreadable. Wider
                          // windows group by status instead, which is what
                          // uses the width rather than just spanning it.
                          if (context.windowSize.isCompact) {
                            return ListView.separated(
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  SizedBox(height: context.rh(4)),
                              itemBuilder: (context, i) => _NotificationTile(
                                  item: items[i], style: _style),
                            );
                          }

                          return SingleChildScrollView(
                            child: _StatusColumns(
                              items: items,
                              styleFor: _style,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuestMessage(BuildContext context) {
    final colors = context.appColors;

    // Scrollable, not a bare centred Column: the sheet is capped at a fraction
    // of the viewport, and on a short one — landscape, or a small phone with
    // the tablet type scale — this block is taller than the space it gets and
    // overflowed the flex (verified at 800x600: 177px over). Centring still
    // applies whenever the content does fit.
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.rw(24)),
          child: Column(
            // min + Center: the block sits centred while it fits, and the
            // scroll view takes over when it doesn't. A bare centred Column
            // overflowed the flex on a short viewport (177px over at 800x600),
            // which is reachable in landscape and at the tablet type scale.
            mainAxisSize: MainAxisSize.min,
            children: [
            Icon(
              Icons.waving_hand_rounded,
              size: context.rr(56),
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: context.rh(16)),
            Text(
              // `notifications.*` (plural), not `notification.*`: the singular
              // namespace existed only in en.json, so every string in this
              // guest state rendered as a raw key in Khmer.
              'notifications.welcome_title'.tr,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: context.rsp(18),
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: context.rh(8)),
            Text(
              'notifications.welcome_body'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: context.rsp(14),
                height: 1.4,
              ),
            ),
            if (widget.onLogin != null) ...[
              SizedBox(height: context.rh(20)),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onLogin!.call();
                  },
                  icon: Icon(Icons.login_rounded, size: context.rr(18)),
                  label: Text(
                    'notifications.login'.tr,
                    style: TextStyle(
                      fontSize: context.rsp(14),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: context.rh(14)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The horizontal filter row: an "All" chip followed by one chip per
/// [NotificationKind].
class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selected,
    required this.labelFor,
    required this.colorFor,
    required this.onSelected,
  });

  final NotificationKind? selected;
  final String Function(NotificationKind) labelFor;
  final Color Function(NotificationKind) colorFor;

  /// Null clears the filter (the "All" chip, or deselecting the active one).
  final ValueChanged<NotificationKind?> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = TextStyle(
      fontSize: context.rsp(12.5),
      fontWeight: FontWeight.w600,
    );

    Widget chip({
      required String label,
      required bool isSelected,
      required Color selectedColor,
      required VoidCallback onTap,
    }) =>
        Padding(
          padding: EdgeInsets.only(right: context.rw(8)),
          child: ChoiceChip(
            label: Text(label),
            labelStyle: labelStyle,
            labelPadding: EdgeInsets.symmetric(horizontal: context.rw(6)),
            padding: EdgeInsets.symmetric(
                horizontal: context.rw(6), vertical: context.rh(6)),
            selected: isSelected,
            onSelected: (_) => onTap(),
            selectedColor: selectedColor.withValues(alpha: 0.2),
          ),
        );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(
            label: 'notifications.filter.all'.tr,
            isSelected: selected == null,
            selectedColor: scheme.primary,
            onTap: () => onSelected(null),
          ),
          ...NotificationKind.values.map(
            (kind) => chip(
              label: labelFor(kind),
              isSelected: selected == kind,
              selectedColor: colorFor(kind),
              onTap: () => onSelected(selected == kind ? null : kind),
            ),
          ),
        ],
      ),
    );
  }
}

/// One notification row: coloured icon tile, title, body.
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.style});

  final NotificationItem item;
  final ({IconData icon, Color color}) Function(BuildContext, NotificationKind)
      style;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final s = style(context, item.kind);

    // Mock data carries either a translation key or literal copy; a dot is what
    // distinguishes the two.
    final displayTitle = item.title.contains('.') ? item.title.tr : item.title;
    final displayBody = item.body.contains('.') ? item.body.tr : item.body;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.rh(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: context.rr(36),
            height: context.rr(36),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: s.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(s.icon, color: s.color, size: context.rr(18)),
          ),
          SizedBox(width: context.rw(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayTitle,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: context.rsp(14),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: context.rh(2)),
                Text(
                  displayBody,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: context.rsp(13),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status columns (tablet)
// ─────────────────────────────────────────────────────────────────────────────

/// The status buckets the tablet layout groups notifications into.
///
/// Derived **statically** from [NotificationKind] rather than read from the
/// server. `NotificationItem` carries no status field, and inventing a
/// read/unread flag as mock data would be exactly the hardcoded-demo-data
/// failure `docs/FEATURE_UI_STANDARD.md` FS-NN-5 forbids. This mapping is real
/// information — it is the only thing that decides what "needs action" means —
/// and it lives in the presentation layer because it is a display concern, not
/// a domain one (FS-NN-6).
///
/// If the backend later grows a genuine status field, this enum is the single
/// place to switch over to it.
enum _NotificationGroup { actionNeeded, approved, updates }

_NotificationGroup _groupOf(NotificationKind kind) => switch (kind) {
      NotificationKind.creditPending ||
      NotificationKind.followUpDue =>
        _NotificationGroup.actionNeeded,
      NotificationKind.creditApproved => _NotificationGroup.approved,
      NotificationKind.customerAssigned ||
      NotificationKind.opportunityMoved =>
        _NotificationGroup.updates,
    };

String _groupLabel(_NotificationGroup group) => switch (group) {
      _NotificationGroup.actionNeeded => 'notifications.group.action_needed'.tr,
      _NotificationGroup.approved => 'notifications.group.approved'.tr,
      _NotificationGroup.updates => 'notifications.group.updates'.tr,
    };

/// Lays the notification list out as one column per status.
///
/// Phone keeps the flat chronological list — a 390pt column split three ways is
/// unreadable. Above `compact` the sheet is full width (see
/// `AppBottomSheet.maxWidth`), and columns are what actually *use* that width
/// rather than merely spanning it (FS-RSP-7).
///
/// `Wrap`, not a fixed `Row`: at two columns the third bucket has to fall onto a
/// second line, and Wrap does that without a second layout path. Column widths
/// come from the real constraints, so this stays correct inside a sheet that is
/// itself inset by the keyboard.
class _StatusColumns extends StatelessWidget {
  const _StatusColumns({required this.items, required this.styleFor});

  final List<NotificationItem> items;
  final ({IconData icon, Color color}) Function(BuildContext, NotificationKind)
      styleFor;

  @override
  Widget build(BuildContext context) {
    final columns = context.responsive(compact: 1, medium: 2, expanded: 3);
    final gap = context.rw(16);

    // Every bucket is rendered even when empty, so the columns do not reshuffle
    // as notifications arrive or a filter is applied (FS-UX-2).
    final grouped = <_NotificationGroup, List<NotificationItem>>{
      for (final group in _NotificationGroup.values)
        group: items.where((i) => _groupOf(i.kind) == group).toList(),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: context.rh(16),
          children: [
            for (final entry in grouped.entries)
              SizedBox(
                width: itemWidth,
                child: _StatusColumn(
                  label: _groupLabel(entry.key),
                  items: entry.value,
                  styleFor: styleFor,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatusColumn extends StatelessWidget {
  const _StatusColumn({
    required this.label,
    required this.items,
    required this.styleFor,
  });

  final String label;
  final List<NotificationItem> items;
  final ({IconData icon, Color color}) Function(BuildContext, NotificationKind)
      styleFor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: context.rsp(13),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // A count, not a colour alone — colour is never the sole carrier of
            // meaning (FS-A11Y-3).
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.rw(8),
                vertical: context.rh(2),
              ),
              decoration: BoxDecoration(
                color: colors.surfaceSoft,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                '${items.length}',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: context.rsp(11),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: context.rh(8)),
        if (items.isEmpty)
          Text(
            'notifications.group.none_here'.tr,
            style: TextStyle(
              color: colors.textHint,
              fontSize: context.rsp(12.5),
            ),
          )
        else
          for (final item in items) ...[
            _NotificationTile(item: item, style: styleFor),
            SizedBox(height: context.rh(4)),
          ],
      ],
    );
  }
}
