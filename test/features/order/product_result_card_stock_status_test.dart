import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/app_theme.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product_pricing.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product_status.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/product_result_card.dart';

/// Only the stock figures and status vary across these cases; everything else
/// is inert scaffolding the entity happens to require.
Product _product({
  required double stockQuantity,
  double reservedQuantity = 0,
  ProductStatus status = ProductStatus.active,
}) =>
    Product(
      id: 'p1',
      familyId: 'f1',
      familyName: 'Roofing',
      code: 'C1',
      sku: 'SKU1',
      materialCode: 'MAT-1',
      barcode: '000',
      name: 'Colour Coated Coil',
      description: '',
      color: 'Blue',
      specification: '',
      categoryId: 'cat1',
      subCategory: 'sub',
      brand: 'ISI',
      grade: 'G1',
      material: 'Steel',
      size: '1219mm',
      diameter: 0,
      thickness: 0.3,
      length: 3.9,
      width: 1.219,
      height: 0,
      weight: 10,
      unit: 'sheet',
      warehouseCode: 'WH1',
      territory: 'T1',
      businessUnit: 'BU1',
      imageUrl: '',
      isMto: false,
      status: status,
      updatedAt: DateTime(2026, 1, 1),
      pricing: const ProductPricing(
        costPrice: 8,
        standardPrice: 11.59,
        wholesalePrice: 11,
        dealerPrice: 10.5,
        vipPrice: 10,
        creditPrice: 12,
        cashPrice: 11,
        currency: 'USD',
      ),
      stockQuantity: stockQuantity,
      reservedQuantity: reservedQuantity,
      minStock: 0,
      maxStock: 1000,
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await LocalizationService.instance.load('en');
  });

  // Mirrors `app.dart`: the whole app runs inside ScreenUtilInit, so any widget
  // using the responsive helpers (`context.rsp` and friends) needs it here too.
  // Without it ScreenUtil's fields are unset and the card throws
  // LateInitializationError before it can render.
  Future<void> pump(WidgetTester tester, Product product) => tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, _) => MaterialApp(
            theme: AppTheme.light('Inter'),
            home: Scaffold(
              body: ProductResultCard(
                product: product,
                isFavorite: false,
                quantity: 0,
                onQuantityChanged: (_) {},
                onToggleFavorite: () {},
              ),
            ),
          ),
        ),
      );

  testWidgets('nothing sellable shows the out-of-stock status', (tester) async {
    await pump(tester, _product(stockQuantity: 0));
    expect(find.text('Out of stock'), findsOneWidget);
  });

  testWidgets('an inactive product shows out of stock even with stock on hand',
      (tester) async {
    await pump(
      tester,
      _product(stockQuantity: 500, status: ProductStatus.discontinued),
    );
    expect(find.text('Out of stock'), findsOneWidget);
  });

  testWidgets('at or below the low threshold shows low stock', (tester) async {
    await pump(tester, _product(stockQuantity: 10));
    expect(find.text('Low stock'), findsOneWidget);
  });

  testWidgets('between the thresholds shows in stock', (tester) async {
    await pump(tester, _product(stockQuantity: 50));
    expect(find.text('In stock'), findsOneWidget);
  });

  testWidgets('above the medium threshold shows high stock', (tester) async {
    await pump(tester, _product(stockQuantity: 51));
    expect(find.text('High stock'), findsOneWidget);
  });

  testWidgets('reserved units do not count towards the band', (tester) async {
    // 60 on hand but 55 already committed leaves 5 sellable. Banding on gross
    // stock badged this "High stock" — green, and wrong for a rep deciding
    // whether they can quote it.
    await pump(tester, _product(stockQuantity: 60, reservedQuantity: 55));
    expect(find.text('Low stock'), findsOneWidget);
    expect(find.text('High stock'), findsNothing);
  });

  testWidgets('the badge is a status, never a quantity', (tester) async {
    await pump(tester, _product(stockQuantity: 42));

    // The regression: the badge used to render "42 in stock" (and, before the
    // stub `.tr` was removed, the raw key "products.status.in_stock").
    expect(find.text('In stock'), findsOneWidget);
    expect(find.textContaining('42'), findsNothing);
    expect(find.textContaining('products.status'), findsNothing);
  });

  group('in Khmer', () {
    // Loaded from `setUp`, not the test body: `LocalizationService.load` goes
    // through `rootBundle`, and real I/O awaited inside `testWidgets` never
    // completes because that body runs against a fake clock.
    setUp(() => LocalizationService.instance.load('km'));
    tearDown(() => LocalizationService.instance.load('en'));

    testWidgets('the label follows the active language', (tester) async {
      await pump(tester, _product(stockQuantity: 5));

      expect(find.text('ទំនិញនៅសល់តិច'), findsOneWidget);
      expect(find.text('Low stock'), findsNothing);
    });
  });
}
