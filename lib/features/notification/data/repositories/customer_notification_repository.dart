import 'package:isi_steel_sales_mobile/features/customers/data/local/customer_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_status.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/entities/notification_item.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/repositories/notification_repository.dart';

/// Derives notifications from the rep's own synced customers.
///
/// These were previously generated from the mock lead pipeline. With the lead
/// feature removed, the customer cache is the only real book of record on the
/// device, so the feed is built from it: the items reference shops the rep
/// actually has, and they work offline because the cache is local.
///
/// This is a stand-in for a server feed, not a simulation of one. Every item
/// restates a fact already visible on the customer record — it invents no
/// events, so nothing here can tell the rep something untrue. When the real
/// endpoint is documented, replace this class; [NotificationRepository] is the
/// seam.
class CustomerNotificationRepository implements NotificationRepository {
  const CustomerNotificationRepository(this._customers);

  final CustomerLocalDataSource _customers;

  /// Enough to fill the sheet without scanning the whole directory.
  static const _scanLimit = 40;

  @override
  Future<List<NotificationItem>> fetchNotifications() async {
    final customers = await _customers.browse(page: 0, pageSize: _scanLimit);
    final items = <NotificationItem>[];

    for (final customer in customers) {
      final item = _forCustomer(customer, items.length);
      if (item != null) items.add(item);
    }

    // Newest first, which is the order the sheet renders without sorting.
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  /// One item per customer, chosen from whichever fact is most worth
  /// surfacing. Returns null when the record says nothing notable.
  NotificationItem? _forCustomer(Customer customer, int index) {
    final name = customer.shopName;

    NotificationItem build({
      required NotificationKind kind,
      required String title,
      required String body,
      required DateTime at,
    }) =>
        NotificationItem(
          id: 'NTF-${customer.id}-$index',
          kind: kind,
          title: title,
          body: body,
          createdAt: at,
        );

    return switch (customer.status) {
      // Awaiting a decision someone has to make.
      CustomerStatus.pendingApproval => build(
          kind: NotificationKind.creditPending,
          title: 'Approval pending',
          body: '$name is awaiting approval before it can trade.',
          at: customer.updatedAt,
        ),
      CustomerStatus.draft => build(
          kind: NotificationKind.customerAssigned,
          title: 'Draft customer',
          body: '$name is still a draft and cannot place orders yet.',
          at: customer.updatedAt,
        ),
      CustomerStatus.suspended || CustomerStatus.creditHold => build(
          kind: NotificationKind.creditPending,
          title: 'Trading suspended',
          body: '$name cannot trade until the hold is cleared.',
          at: customer.updatedAt,
        ),
      CustomerStatus.active when customer.lastVisitDate == null => build(
          kind: NotificationKind.followUpDue,
          title: 'No visit recorded',
          body: '$name has no visit on record yet.',
          at: customer.updatedAt,
        ),
      CustomerStatus.active => build(
          kind: NotificationKind.creditApproved,
          title: 'Customer active',
          body: '$name is approved and able to trade.',
          at: customer.lastOrderDate ?? customer.updatedAt,
        ),
      CustomerStatus.dormant => build(
          kind: NotificationKind.followUpDue,
          title: 'Follow-up due',
          body: '$name has gone quiet — worth a visit.',
          at: customer.lastOrderDate ?? customer.updatedAt,
        ),
      _ => null,
    };
  }
}
