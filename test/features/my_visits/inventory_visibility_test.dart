import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/inventory_visible/inventory_visible_screen.dart';

/// The point of this screen is that a stock check records what a rep actually
/// observed. Items therefore start with **no** level chosen and submit stays
/// disabled until every one has been judged — otherwise a rep can submit a
/// full audit without looking at anything, and the record is worthless while
/// appearing complete.
///
/// That rule is one boolean away from being lost (`_complete`), and losing it
/// would not break any screen or fail any other test, so it is pinned here.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await LocalizationService.instance.load('en');
  });

  /// A real phone surface. Without this the harness runs at its 800x600
  /// default while ScreenUtil scales from a 390x844 design, and the list's
  /// `Expanded` collapses to nothing — the rows never build, and every finder
  /// reports "0 widgets" as though the labels were missing.
  void useDeviceSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<int> pumpScreen(WidgetTester tester) async {
    var submits = 0;
    useDeviceSurface(tester);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, _) => MaterialApp(
          home: InventoryVisibilityScreen(
            depotName: 'Phnom Penh Depot',
            onSubmit: () => submits++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return submits;
  }

  ElevatedButton submitButton(WidgetTester tester) =>
      tester.widget<ElevatedButton>(find.byType(ElevatedButton));

  testWidgets('offers three levels for every item, none preselected',
      (tester) async {
    await pumpScreen(tester);

    // Four mock items x three levels.
    expect(find.text('High stock'), findsNWidgets(4));
    expect(find.text('Medium stock'), findsNWidgets(4));
    expect(find.text('Low stock'), findsNWidgets(4));

    expect(find.text('0 of 4 assessed'), findsOneWidget,
        reason: 'items must start unjudged');
  });

  testWidgets('submit stays disabled until every item is judged',
      (tester) async {
    await pumpScreen(tester);
    expect(submitButton(tester).onPressed, isNull);

    // Judge three *different* items — `.at(i)` walks the cards in order.
    // Using `.first` three times would tap the same card and leave one item
    // assessed, which is a different scenario entirely.
    for (var i = 0; i < 3; i++) {
      final option = find.text('High stock').at(i);
      await tester.ensureVisible(option);
      await tester.pumpAndSettle();
      await tester.tap(option);
      await tester.pumpAndSettle();
    }
    expect(find.text('3 of 4 assessed'), findsOneWidget);
    expect(submitButton(tester).onPressed, isNull,
        reason: 'three of four judged is still an incomplete audit');
  });

  testWidgets('submit fires once the audit is complete', (tester) async {
    var submits = 0;
    useDeviceSurface(tester);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, _) => MaterialApp(
          home: InventoryVisibilityScreen(
            depotName: 'Phnom Penh Depot',
            onSubmit: () => submits++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // One level per item. The last card sits below the fold on a 390x844
    // surface, so each is scrolled into view before it is tapped.
    for (var i = 0; i < 4; i++) {
      final option = find.text('High stock').at(i);
      await tester.ensureVisible(option);
      await tester.pumpAndSettle();
      await tester.tap(option);
      await tester.pumpAndSettle();
    }
    expect(find.text('4 of 4 assessed'), findsOneWidget);

    final button = submitButton(tester);
    expect(button.onPressed, isNotNull);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(submits, 1);
  });

  testWidgets('choosing a different level replaces the previous one',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('High stock').first);
    await tester.pumpAndSettle();
    expect(find.text('1 of 4 assessed'), findsOneWidget);

    // Re-judging the same item must not count as a second assessment.
    await tester.tap(find.text('Low stock').first);
    await tester.pumpAndSettle();
    expect(find.text('1 of 4 assessed'), findsOneWidget);
  });
}
