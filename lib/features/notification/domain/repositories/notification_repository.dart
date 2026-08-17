import 'package:isi_steel_sales_mobile/features/notification/domain/entities/notification_item.dart';

/// Source of the rep's notifications.
///
/// Deliberately its own contract rather than a method on another feature's
/// repository — notifications were served by `LeadRepository`, which is why
/// removing the lead feature took the notifications sheet down with it.
///
/// The signed-in profile carries a `notifications.read` permission, so the
/// server almost certainly exposes a real feed. No endpoint for it is
/// documented in the mobile integration guides, so this is backed locally for
/// now; swapping in an HTTP implementation is a change behind this interface.
abstract interface class NotificationRepository {
  /// Newest first.
  Future<List<NotificationItem>> fetchNotifications();
}
