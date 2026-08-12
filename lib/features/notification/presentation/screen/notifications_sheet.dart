import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/notification_item.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/usecases/fetch_notifications.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/lead_usecase.dart';
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
      NotificationKind.leadAssigned => (
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
        NotificationKind.leadAssigned => 'notifications.filter.assigned'.tr,
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

                          return ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                SizedBox(height: context.rh(4)),
                            itemBuilder: (context, i) =>
                                _NotificationTile(item: items[i], style: _style),
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
