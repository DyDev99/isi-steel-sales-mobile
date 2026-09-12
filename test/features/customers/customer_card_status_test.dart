import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/app_theme.dart';
import 'package:isi_steel_sales_mobile/core/theme/app_typography.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_status.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/widgets/customer_card.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/widgets/customer_status_badge.dart';

/// The card renders a customer's trading status.
///
/// It is not decoration: `suspended`, `closed` and `creditHold` all mean *do
/// not start writing an order*, and a rep needs to know that from the list —
/// before tapping through and building a quotation they cannot submit.
///
/// The status is read off the entity's stable `status` code rather than the
/// API's pre-translated `statusDisplay`, so a row rendered from the offline
/// cache reads in the current language even when it was synced under another.
Customer _customer({
  required CustomerStatus status,
  String shopName = 'Phnom Penh Steel Outlet',
  String? khName,
}) =>
    Customer(
      id: 'c1',
      customerCode: 'ISI-PP0099',
      shopName: shopName,
      khName: khName,
      ownerName: 'Sok Dara',
      phone: '012345678',
      address: 'St. 271',
      province: 'Phnom Penh',
      district: 'Mean Chey',
      territory: 'PP-NORTH',
      latitude: 11.55,
      longitude: 104.91,
      creditLimit: 5000,
      status: status,
      assignedRepId: 'rep-1',
      assignedRepName: 'Rep One',
      updatedAt: DateTime.utc(2026, 9, 1),
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await LocalizationService.instance.load('en');
  });

  Future<void> pump(
    WidgetTester tester,
    Customer customer, {
    double textScale = 1.0,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, _) => MaterialApp(
          theme: AppTheme.light(AppTypography.latinFontFamily),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              // Scrollable, because that is how the card is actually mounted
              // (a `SliverList` in `customers_screen.dart`). In a bare Scaffold
              // body a tall card reports a vertical overflow that the app never
              // has, which would make this suite fail on a layout that is fine.
              body: ListView(
                children: [
                  CustomerCard(
                    customer: customer,
                    isFavorite: false,
                    onTap: () {},
                    onFavoriteToggle: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the badge carrying the customer\'s own status',
      (tester) async {
    await pump(tester, _customer(status: CustomerStatus.suspended));

    final badge =
        tester.widget<CustomerStatusBadge>(find.byType(CustomerStatusBadge));
    expect(badge.status, CustomerStatus.suspended);
    expect(find.text('Suspended'), findsOneWidget);
  });

  testWidgets('every status renders its own label, never a default',
      (tester) async {
    // A card that showed "Active" for everything would be worse than showing
    // nothing — it would actively tell a rep a closed account is tradeable.
    const expected = {
      CustomerStatus.draft: 'Draft',
      CustomerStatus.pendingApproval: 'Pending approval',
      CustomerStatus.active: 'Active',
      CustomerStatus.suspended: 'Suspended',
      CustomerStatus.closed: 'Closed',
      CustomerStatus.dormant: 'Dormant',
      CustomerStatus.creditHold: 'Credit Hold',
    };

    for (final entry in expected.entries) {
      await pump(tester, _customer(status: entry.key));
      expect(find.text(entry.value), findsOneWidget,
          reason: '${entry.key.name} rendered the wrong label');
    }
  });

  testWidgets('the badge does not crowd out the shop name', (tester) async {
    // The name is Expanded and the badge is not, so a long name must ellipsize
    // rather than push the badge off the card.
    await pump(
      tester,
      _customer(
        status: CustomerStatus.creditHold,
        shopName: 'Phnom Penh Steel Outlet and Construction Supply Company',
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(CustomerStatusBadge), findsOneWidget);
    expect(find.text('Credit Hold'), findsOneWidget);
  });

  testWidgets('survives 200% text scale without overflowing', (tester) async {
    // FS-A11Y-2. A badge added to a Row is the classic way a card starts
    // overflowing at large scales.
    await pump(tester, _customer(status: CustomerStatus.pendingApproval),
        textScale: 2.0);

    expect(tester.takeException(), isNull);
  });

  group('in Khmer', () {
    setUp(() => LocalizationService.instance.load('km'));
    tearDown(() => LocalizationService.instance.load('en'));

    testWidgets('the status label follows the active language', (tester) async {
      await pump(tester, _customer(status: CustomerStatus.active));

      expect(find.text('សកម្ម'), findsOneWidget); // Active
      expect(find.text('Active'), findsNothing);
    });

    testWidgets('no status leaks its translation key', (tester) async {
      for (final status in CustomerStatus.values) {
        await pump(tester, _customer(status: status));

        final leaked = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .whereType<String>()
            .where((s) => s.startsWith('customers.'))
            .toList();
        expect(leaked, isEmpty,
            reason: '${status.name} fell through to its key');
      }
    });
  });
}
