import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/device/device_insets.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/notification_item.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/usecases/fetch_notifications.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/lead_usecase.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/app_bottom_sheet.dart';

Future<void> showNotificationsSheet({
  required BuildContext context,
  required FetchNotifications fetchNotifications,
  bool isGuest = false,
  VoidCallback? onLogin,
}) {
  final colors = context.appColors;
  return showModalBottomSheet<void>(
    constraints: const BoxConstraints(maxWidth: AppBottomSheet.maxWidth),
    context: context,
    backgroundColor: colors.surfaceSoft,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
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

  // Helper to generate readable labels for the filter chips
  String _getFilterLabel(NotificationKind kind) {
    return switch (kind) {
      NotificationKind.creditApproved => 'notifications.filter.approved'.tr.isEmpty ? 'Approved' : 'notifications.filter.approved'.tr,
      NotificationKind.leadAssigned => 'notifications.filter.assigned'.tr.isEmpty ? 'Assigned' : 'notifications.filter.assigned'.tr,
      NotificationKind.opportunityMoved => 'notifications.filter.opportunity'.tr.isEmpty ? 'Opportunity' : 'notifications.filter.opportunity'.tr,
      NotificationKind.creditPending => 'notifications.filter.pending'.tr.isEmpty ? 'Pending' : 'notifications.filter.pending'.tr,
      NotificationKind.followUpDue => 'notifications.filter.followup'.tr.isEmpty ? 'Follow Up' : 'notifications.filter.followup'.tr,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SafeArea(
      child: LocalizedBuilder(
        builder: (context) {
          return SizedBox(
            height: context.deviceInsets.screenSize.height * 0.7,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'notifications.title'.tr,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  
                  // Filter Chips UI (Only show if not a guest)
                  if (!widget.isGuest) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: Text('notifications.filter.all'.tr.isEmpty ? 'All' : 'notifications.filter.all'.tr),
                            selected: _selectedFilter == null,
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedFilter = null);
                            },
                            selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                          ),
                          const SizedBox(width: 8),
                          ...NotificationKind.values.map((kind) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(_getFilterLabel(kind)),
                                selected: _selectedFilter == kind,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedFilter = selected ? kind : null;
                                  });
                                },
                                selectedColor: _style(context, kind).color.withValues(alpha: 0.2),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Expanded(
                    child: widget.isGuest
                        ? _buildGuestMessage(context)
                        : FutureBuilder<List<NotificationItem>>(
                            future: _notificationsFuture, // Uses initialized future
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Center(
                                    child: CircularProgressIndicator(
                                        color: Theme.of(context).colorScheme.primary));
                              }
                              
                              // Apply the active filter here
                              final allItems = snapshot.data!;
                              final items = _selectedFilter == null 
                                  ? allItems 
                                  : allItems.where((item) => item.kind == _selectedFilter).toList();

                              if (items.isEmpty) {
                                return Center(
                                  child: Text(
                                    _selectedFilter == null 
                                        ? 'notifications.no_notifications'.tr
                                        : 'notifications.no_filtered_results'.tr.isEmpty ? 'No notifications match this filter.' : 'notifications.no_filtered_results'.tr,
                                    style: TextStyle(color: colors.textHint),
                                  ),
                                );
                              }
                              
                              return ListView.separated(
                                itemCount: items.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 4),
                                itemBuilder: (context, i) {
                                  final item = items[i];
                                  final s = _style(context, item.kind);

                                  final displayTitle = item.title.contains('.')
                                      ? item.title.tr
                                      : item.title;
                                  final displayBody = item.body.contains('.')
                                      ? item.body.tr
                                      : item.body;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: s.color.withValues(alpha: 0.16),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(s.icon, color: s.color, size: 18),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                displayTitle,
                                                style: TextStyle(
                                                    color: colors.textPrimary,
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w700),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                displayBody,
                                                style: TextStyle(
                                                    color: colors.textSecondary,
                                                    fontSize: 12.5),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGuestMessage(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.waving_hand_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'notification.welcome_title'.tr,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'notification.welcome_body'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (widget.onLogin != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onLogin!.call();
                  },
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: Text('notification.login'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}