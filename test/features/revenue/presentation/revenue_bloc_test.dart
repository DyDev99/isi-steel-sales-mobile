import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/customer_credit.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/discount_option.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/product_category.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/usecases/get_categories.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/usecases/get_customer_credit.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/usecases/get_discount_options.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/usecases/get_products.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/bloc/revenue_bloc.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/bloc/revenue_event.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/bloc/revenue_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetProducts extends Mock implements GetProducts {}

class _MockGetCategories extends Mock implements GetCategories {}

class _MockGetDiscountOptions extends Mock implements GetDiscountOptions {}

class _MockGetCustomerCredit extends Mock implements GetCustomerCredit {}

void main() {
  late _MockGetProducts getProducts;
  late _MockGetCategories getCategories;
  late _MockGetDiscountOptions getDiscountOptions;
  late _MockGetCustomerCredit getCustomerCredit;

  const products = [
    Product(id: 'p1', name: 'Rebar 12mm', sku: 'RB-12', categoryId: 'cat-rebar', unit: 'Ton', unitPrice: 100, availableStock: 2),
    Product(id: 'p2', name: 'Steel Pipe', sku: 'PP-02', categoryId: 'cat-pipe', unit: 'Pcs', unitPrice: 50, availableStock: 4),
  ];
  const categories = [ProductCategory(id: 'cat-rebar', name: 'Rebar'), ProductCategory(id: 'cat-pipe', name: 'Pipe')];
  const discounts = [
    DiscountOption(id: 'd0', label: '0%', percentage: 0, isDefault: true),
    DiscountOption(id: 'd10', label: '10%', percentage: 10),
  ];
  const credit = CustomerCredit(
    customerId: 'c1',
    customerName: 'Acme',
    creditLimit: 1000,
    usedCredit: 400,
    outstandingBalance: 100,
  );

  final loadedState = const RevenueState(
    status: RevenueStatus.loaded,
    products: products,
    categories: categories,
    discountOptions: discounts,
    customerCredit: credit,
    selectedDiscountId: 'd0',
  );

  setUpAll(() => registerFallbackValue(const NoParams()));

  setUp(() {
    getProducts = _MockGetProducts();
    getCategories = _MockGetCategories();
    getDiscountOptions = _MockGetDiscountOptions();
    getCustomerCredit = _MockGetCustomerCredit();
  });

  RevenueBloc build() => RevenueBloc(
        getProducts: getProducts,
        getCategories: getCategories,
        getDiscountOptions: getDiscountOptions,
        getCustomerCredit: getCustomerCredit,
      );

  void stubAllSuccess() {
    when(() => getProducts(any())).thenAnswer((_) async => const Success(products));
    when(() => getCategories(any())).thenAnswer((_) async => const Success(categories));
    when(() => getDiscountOptions(any())).thenAnswer((_) async => const Success(discounts));
    when(() => getCustomerCredit(any())).thenAnswer((_) async => const Success(credit));
  }

  group('RevenueStarted', () {
    blocTest<RevenueBloc, RevenueState>(
      'emits [loading, loaded] and selects the default discount',
      setUp: stubAllSuccess,
      build: build,
      act: (bloc) => bloc.add(const RevenueStarted()),
      expect: () => [
        isA<RevenueState>().having((s) => s.status, 'status', RevenueStatus.loading),
        isA<RevenueState>()
            .having((s) => s.status, 'status', RevenueStatus.loaded)
            .having((s) => s.products, 'products', products)
            .having((s) => s.categories, 'categories', categories)
            .having((s) => s.customerCredit, 'credit', credit)
            .having((s) => s.selectedDiscountId, 'default discount', 'd0'),
      ],
    );

    blocTest<RevenueBloc, RevenueState>(
      'emits [loading, error] when any source fails',
      setUp: () {
        stubAllSuccess();
        when(() => getProducts(any())).thenAnswer((_) async => const Failed(CacheFailure(message: 'no data')));
      },
      build: build,
      act: (bloc) => bloc.add(const RevenueStarted()),
      expect: () => [
        isA<RevenueState>().having((s) => s.status, 'status', RevenueStatus.loading),
        isA<RevenueState>()
            .having((s) => s.status, 'status', RevenueStatus.error)
            .having((s) => s.errorMessage, 'message', 'no data'),
      ],
    );
  });

  group('interaction events (seeded loaded)', () {
    blocTest<RevenueBloc, RevenueState>(
      'RevenueSearchChanged updates the query',
      build: build,
      seed: () => loadedState,
      act: (bloc) => bloc.add(const RevenueSearchChanged('pipe')),
      expect: () => [isA<RevenueState>().having((s) => s.searchQuery, 'query', 'pipe')],
    );

    blocTest<RevenueBloc, RevenueState>(
      'RevenueCategorySelected updates the selected category',
      build: build,
      seed: () => loadedState,
      act: (bloc) => bloc.add(const RevenueCategorySelected('cat-pipe')),
      expect: () => [isA<RevenueState>().having((s) => s.selectedCategoryId, 'category', 'cat-pipe')],
    );

    blocTest<RevenueBloc, RevenueState>(
      'RevenueDiscountSelected updates the selected discount',
      build: build,
      seed: () => loadedState,
      act: (bloc) => bloc.add(const RevenueDiscountSelected('d10')),
      expect: () => [isA<RevenueState>().having((s) => s.selectedDiscountId, 'discount', 'd10')],
    );

    blocTest<RevenueBloc, RevenueState>(
      'RevenueCartQuantityChanged +1 adds the item to the cart',
      build: build,
      seed: () => loadedState,
      act: (bloc) => bloc.add(const RevenueCartQuantityChanged(productId: 'p1', delta: 1)),
      expect: () => [isA<RevenueState>().having((s) => s.cartQuantities, 'cart', {'p1': 1})],
    );

    blocTest<RevenueBloc, RevenueState>(
      'RevenueCartQuantityChanged clamps to available stock',
      build: build,
      // p1 stock is 2; from 1, a +5 bump must clamp to the stock ceiling.
      seed: () => loadedState.copyWith(cartQuantities: const {'p1': 1}),
      act: (bloc) => bloc.add(const RevenueCartQuantityChanged(productId: 'p1', delta: 5)),
      expect: () => [isA<RevenueState>().having((s) => s.cartQuantities['p1'], 'clamped qty', 2)],
    );

    blocTest<RevenueBloc, RevenueState>(
      'RevenueCartQuantityChanged -1 to zero removes the line',
      build: build,
      seed: () => loadedState.copyWith(cartQuantities: const {'p1': 1}),
      act: (bloc) => bloc.add(const RevenueCartQuantityChanged(productId: 'p1', delta: -1)),
      expect: () => [isA<RevenueState>().having((s) => s.cartQuantities.containsKey('p1'), 'removed', isFalse)],
    );
  });
}
