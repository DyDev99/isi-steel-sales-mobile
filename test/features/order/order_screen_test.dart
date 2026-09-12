import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/app_theme.dart';
import 'package:isi_steel_sales_mobile/core/theme/app_typography.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation_status.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/sales_order.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/sales_order_status.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/watch_quotations.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/watch_sales_orders.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/order_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockWatchQuotations extends Mock implements WatchQuotations {}
class _MockWatchSalesOrders extends Mock implements WatchSalesOrders {}

void main() {
  late _MockWatchQuotations watchQuotations;
  late _MockWatchSalesOrders watchSalesOrders;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting();
    await LocalizationService.instance.load('en');
    registerFallbackValue(const NoParams());
  });

  setUp(() async {
    watchQuotations = _MockWatchQuotations();
    watchSalesOrders = _MockWatchSalesOrders();
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<WatchQuotations>(watchQuotations);
    GetIt.instance.registerSingleton<WatchSalesOrders>(watchSalesOrders);
    GetIt.instance.registerSingleton<ShellTabController>(ShellTabController());
  });

  tearDown(() async => GetIt.instance.reset());

  testWidgets('OrderScreen renders order cards with total and label', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    when(() => watchQuotations(any())).thenAnswer(
      (_) => Stream.value([
        Quotation(
          id: 'QT-001',
          lines: const [],
          subtotal: 150.0,
          discount: 0.0,
          tax: 0.0,
          total: 150.0,
          status: QuotationStatus.draft,
          sapDraftStatus: 'DRAFT',
          validUntil: DateTime(2026, 9, 30),
          createdAt: DateTime(2026, 9, 1),
          updatedAt: DateTime(2026, 9, 1),
        ),
      ]),
    );
    when(() => watchSalesOrders(any())).thenAnswer(
      (_) => Stream.value([
        SalesOrder(
          id: 'SO-001',
          quotationId: 'QT-001',
          lines: const [],
          subtotal: 250.0,
          discount: 0.0,
          tax: 0.0,
          total: 250.0,
          status: SalesOrderStatus.confirmed,
          sapStatus: 'CONFIRMED',
          createdAt: DateTime(2026, 9, 2),
        ),
      ]),
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, _) => MaterialApp(
          theme: AppTheme.light(AppTypography.latinFontFamily),
          home: const OrderScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Total'), findsNWidgets(2));
    expect(find.text('\$150.00'), findsOneWidget);
    expect(find.text('\$250.00'), findsOneWidget);
  });

  testWidgets('OrderScreen does not overflow with 1.3 text scale factor', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    when(() => watchQuotations(any())).thenAnswer(
      (_) => Stream.value([
        Quotation(
          id: 'QT-001',
          lines: const [],
          subtotal: 150.0,
          discount: 0.0,
          tax: 0.0,
          total: 150.0,
          status: QuotationStatus.draft,
          sapDraftStatus: 'DRAFT',
          validUntil: DateTime(2026, 9, 30),
          createdAt: DateTime(2026, 9, 1),
          updatedAt: DateTime(2026, 9, 1),
        ),
      ]),
    );
    when(() => watchSalesOrders(any())).thenAnswer(
      (_) => Stream.value([
        SalesOrder(
          id: 'SO-001',
          quotationId: 'QT-001',
          lines: const [],
          subtotal: 250.0,
          discount: 0.0,
          tax: 0.0,
          total: 250.0,
          status: SalesOrderStatus.confirmed,
          sapStatus: 'CONFIRMED',
          createdAt: DateTime(2026, 9, 2),
        ),
      ]),
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, _) => MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: MaterialApp(
            theme: AppTheme.light(AppTypography.latinFontFamily),
            home: const OrderScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Total'), findsNWidgets(2));
    expect(find.text('\$150.00'), findsOneWidget);
    expect(find.text('\$250.00'), findsOneWidget);
  });
}
