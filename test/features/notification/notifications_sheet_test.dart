import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/responsive/breakpoints.dart';
import 'package:isi_steel_sales_mobile/core/theme/app_theme.dart';
import 'package:isi_steel_sales_mobile/core/theme/app_typography.dart';

import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/entities/notification_item.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/repositories/notification_repository.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/usecases/fetch_notifications.dart';
import 'package:isi_steel_sales_mobile/features/notification/presentation/screen/notifications_sheet.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotificationRepository extends Mock
    implements NotificationRepository {}

class _StubFetchNotifications extends FetchNotifications {
  _StubFetchNotifications(this.items) : super(_MockNotificationRepository());

  final List<NotificationItem> items;

  @override
  Future<List<NotificationItem>> call(NoParams params) async => items;
}

NotificationItem _item(String id, NotificationKind kind) => NotificationItem(
      id: id,
      kind: kind,
      title: 'Credit approved',
      body: 'The credit limit for ISI Steel Co. was approved.',
      createdAt: DateTime(2026, 8, 12),
    );

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  const phone = Size(390, 844);
  const tablet = Size(834, 1112); // iPad Air portrait — `medium`

  /// Opens the real sheet, so the test exercises `showNotificationsSheet`'s
  /// chrome (via `showAppBottomSheet`) rather than the private widget alone.
  Future<void> openSheet(
    WidgetTester tester, {
    required Size size,
    required bool isGuest,
    List<NotificationItem> items = const [],
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize:
            Breakpoints.fromWidth(size.width).isCompact ? phone : size,
        builder: (context, _) => MaterialApp(
          theme: AppTheme.light(AppTypography.latinFontFamily),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showNotificationsSheet(
                    context: context,
                    fetchNotifications: _StubFetchNotifications(items),
                    isGuest: isGuest,
                    onLogin: () {},
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    // Explicit pumps rather than pumpAndSettle: the modal route keeps a ticker
    // alive long enough that settling is unreliable here, and a fixed advance
    // past the sheet's entrance animation is all this test needs.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  double fontSizeOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style!.fontSize!;

  group('guest state', () {
    testWidgets('renders translated Khmer copy, not raw keys', (tester) async {
      // The regression this pins: the guest branch read the `notification.*`
      // (singular) namespace, which existed only in en.json — so in Khmer every
      // string here rendered as its own key. `translate()` returns the key on a
      // miss, so nothing failed loudly.
      await LocalizationService.instance.load('km');
      addTearDown(() => LocalizationService.instance.load('en'));

      await openSheet(tester, size: phone, isGuest: true);

      expect(find.text('notifications.welcome_title'), findsNothing);
      expect(find.text('notifications.welcome_body'), findsNothing);
      expect(find.text('notifications.login'), findsNothing);
      expect(find.text('សូមស្វាគមន៍!'), findsOneWidget);
    });

    testWidgets('type is larger on a tablet than on a phone', (tester) async {
      await LocalizationService.instance.load('en');

      await openSheet(tester, size: phone, isGuest: true);
      final phoneTitle = fontSizeOf(tester, 'Welcome!');

      await openSheet(tester, size: tablet, isGuest: true);
      expect(fontSizeOf(tester, 'Welcome!'), greaterThan(phoneTitle));
    });
  });

  group('list state', () {
    final items = [
      _item('1', NotificationKind.creditApproved),
      _item('2', NotificationKind.customerAssigned),
    ];

    testWidgets('title, filters and rows render without overflow',
        (tester) async {
      await LocalizationService.instance.load('en');
      await openSheet(tester, size: phone, isGuest: false, items: items);

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Credit approved'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('row type scales up on a tablet', (tester) async {
      await LocalizationService.instance.load('en');

      await openSheet(tester, size: phone, isGuest: false, items: items);
      final phoneSheetTitle = fontSizeOf(tester, 'Notifications');
      final phoneRowTitle =
          tester.widgetList<Text>(find.text('Credit approved')).first.style!.fontSize!;

      await openSheet(tester, size: tablet, isGuest: false, items: items);
      final tabletRowTitle =
          tester.widgetList<Text>(find.text('Credit approved')).first.style!.fontSize!;

      expect(fontSizeOf(tester, 'Notifications'),
          greaterThan(phoneSheetTitle));
      expect(tabletRowTitle, greaterThan(phoneRowTitle));
    });

    testWidgets('an empty filter result shows translated copy', (tester) async {
      await LocalizationService.instance.load('en');
      await openSheet(
        tester,
        size: phone,
        isGuest: false,
        items: [_item('1', NotificationKind.creditApproved)],
      );

      await tester.tap(find.text('Pending'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No notifications match this filter.'), findsOneWidget);
      expect(find.text('notifications.filter.no_results'), findsNothing);
    });
  });
}
