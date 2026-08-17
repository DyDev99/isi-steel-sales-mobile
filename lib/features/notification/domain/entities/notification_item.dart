/// What a notification is about. Purely a display category — the label and
/// colour are resolved from it, nothing branches on it for behaviour.
enum NotificationKind {
  creditApproved,

  /// A customer was assigned to this rep. Was `leadAssigned` while the lead
  /// feature owned this type; notifications are customer-driven now.
  customerAssigned,

  opportunityMoved,
  creditPending,
  followUpDue,
}

/// A single item in the notifications sheet.
///
/// This entity used to live in `features/lead`, which is why the notification
/// feature had no domain of its own. It owns it now, so nothing here depends
/// on a pipeline that no longer exists.
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final NotificationKind kind;

  /// A localisation key or raw text from the server.
  final String title;
  final String body;

  final DateTime createdAt;
}
