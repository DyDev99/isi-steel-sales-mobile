// package:isi_steel_sales_mobile/features/lead/domain/entities/notification_item.dart

enum NotificationKind {
  creditApproved,
  leadAssigned,
  opportunityMoved,
  creditPending,
  followUpDue,
}

class NotificationItem {
  final String id;
  final NotificationKind kind;
  final String title; // Can be a localization key or raw text from server
  final String body; // Can be a localization key or raw text from server
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
  });
}
