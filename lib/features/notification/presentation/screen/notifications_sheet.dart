import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart'; // Handles the .tr extension
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart'; // Triggers reactive rebuilds
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/notification_item.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/usecases/fetch_notifications.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/lead_usecase.dart';

Future<void> showNotificationsSheet({
  required BuildContext context,
  required FetchNotifications fetchNotifications,
}) {
  final colors = context.appColors;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: colors.surfaceSoft, // Replaced Vibe.bgSoft
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (_) => _NotificationsSheet(fetchNotifications: fetchNotifications),
  );
}

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet({required this.fetchNotifications});
  final FetchNotifications fetchNotifications;

  ({IconData icon, Color color}) _style(BuildContext context, NotificationKind kind) {
    final colors = context.appColors;
    return switch (kind) {
      NotificationKind.creditApproved => (
          icon: Icons.verified_rounded,
          color: colors.success // Replaced Vibe.success
        ),
      NotificationKind.leadAssigned => (
          icon: Icons.person_add_alt_1_rounded,
          color: colors.accentPurple // Replaced Vibe.violet
        ),
      NotificationKind.opportunityMoved => (
          icon: Icons.trending_up_rounded,
          color: colors.warning // Replaced Vibe.amber
        ),
      NotificationKind.creditPending => (
          icon: Icons.hourglass_top_rounded,
          color: colors.warning // Replaced Vibe.amber
        ),
      NotificationKind.followUpDue => (
          icon: Icons.event_repeat_rounded,
          color: Theme.of(context).colorScheme.error // Replaced Vibe.danger with Material 3 semantic error
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SafeArea(
      // LocalizedBuilder forces a sub-tree rebuild when language changes smoothly
      child: LocalizedBuilder(
        builder: (context) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'notifications.title'.tr,
                    style: TextStyle(
                        color: colors.textPrimary, // Replaced Vibe.text
                        fontSize: 17,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: FutureBuilder<List<NotificationItem>>(
                      future: fetchNotifications(const NoParams()),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(
                              child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.primary)); // Replaced Vibe.pink with primary theme indicator
                        }
                        final items = snapshot.data!;
                        if (items.isEmpty) {
                          return Center(
                            child: Text(
                              'notifications.no_notifications'.tr,
                              style: TextStyle(color: colors.textHint), // Replaced Vibe.muted
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 4),
                          itemBuilder: (context, i) {
                            final item = items[i];
                            final s = _style(context, item.kind);

                            // Check if title or body are localized system translation keys
                            // If they are regular strings, use fallback item.title directly.
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
                                    child:
                                        Icon(s.icon, color: s.color, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayTitle,
                                          style: TextStyle(
                                              color: colors.textPrimary, // Replaced Vibe.text
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          displayBody,
                                          style: TextStyle(
                                              color: colors.textSecondary, // Replaced Vibe.muted with readable textSecondary
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
}