import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/app_theme.dart';
import 'package:isi_steel_sales_mobile/core/theme/app_typography.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation_sync_status.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/l10n/quotation_sync_status_l10n.dart';

/// The sync sheet rendered every queue row's status through a `label` that
/// returned English literals from the domain enum — and called it as
/// `label(context)`, which did not compile, so the sheet could not build at
/// all. `orders.sync_status.*` was already translated in both language files
/// with no caller; these tests hold that wiring in place.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await LocalizationService.instance.load('en');
  });

  /// `.tr` reads the service directly, so a bare pump is enough — but the
  /// widget tree still needs ScreenUtil for the responsive helpers.
  Future<void> pumpLabels(WidgetTester tester) => tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, _) => MaterialApp(
            theme: AppTheme.light(AppTypography.latinFontFamily),
            home: Scaffold(
              body: Column(
                children: [
                  for (final s in QuotationSyncStatus.values)
                    Text(s.localizedLabel),
                ],
              ),
            ),
          ),
        ),
      );

  testWidgets('every status resolves to English copy', (tester) async {
    await pumpLabels(tester);

    expect(find.text('Pending sync'), findsOneWidget);
    expect(find.text('SAP accepted'), findsOneWidget);
    expect(find.text('Sync failed'), findsOneWidget);
    expect(find.text('Conflict'), findsOneWidget);
  });

  testWidgets('no status leaks its translation key', (tester) async {
    await pumpLabels(tester);

    // An unresolved key renders as the raw dotted path. Nine states, nine
    // real labels.
    final rendered = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .toList();

    expect(rendered, hasLength(QuotationSyncStatus.values.length));
    expect(
      rendered.where((s) => s.startsWith('orders.')),
      isEmpty,
      reason: 'a status fell through to its key',
    );
  });

  group('in Khmer', () {
    setUp(() => LocalizationService.instance.load('km'));
    tearDown(() => LocalizationService.instance.load('en'));

    testWidgets('every status resolves to Khmer copy', (tester) async {
      await pumpLabels(tester);

      // The regression this file exists for: these chips used to render
      // English regardless of language, because the labels were literals on
      // the domain enum.
      expect(find.text('រង់ចាំសមកាលកម្ម'), findsOneWidget); // Pending sync
      expect(find.text('SAP បានទទួលយក'), findsOneWidget); // SAP accepted
      expect(find.text('សមកាលកម្មបរាជ័យ'), findsOneWidget); // Sync failed

      expect(find.text('Pending sync'), findsNothing);
      expect(find.text('Sync failed'), findsNothing);
    });

    testWidgets('no status leaks its translation key in Khmer', (tester) async {
      await pumpLabels(tester);

      final rendered = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .toList();

      expect(rendered.where((s) => s.startsWith('orders.')), isEmpty);
    });
  });

  group('the SAP document line', () {
    test('reads both forms from the language files', () async {
      await LocalizationService.instance.load('en');

      final untimed = 'sync.sap_document'.trParams({'id': 'DOC-42'});
      final timed =
          'sync.sap_document_timed'.trParams({'id': 'DOC-42', 'ms': 812});

      // FS-LOC-3: assert the parameters actually substitute. Shipping copy in
      // this app has rendered `{minutes}` literally before.
      expect(untimed, 'SAP DOC-42');
      expect(untimed, isNot(contains('{')));
      expect(timed, contains('DOC-42'));
      expect(timed, contains('812'));
      expect(timed, isNot(contains('{')));
    });

    test('substitutes in Khmer too', () async {
      await LocalizationService.instance.load('km');
      addTearDown(() => LocalizationService.instance.load('en'));

      final timed =
          'sync.sap_document_timed'.trParams({'id': 'DOC-42', 'ms': 812});

      expect(timed, contains('DOC-42'));
      expect(timed, contains('812'));
      expect(timed, isNot(contains('{')));
    });
  });
}
