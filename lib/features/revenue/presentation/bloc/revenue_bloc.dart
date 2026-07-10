import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/customer_credit.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/discount_option.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/product_category.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/usecases/get_categories.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/usecases/get_customer_credit.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/usecases/get_discount_options.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/usecases/get_products.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/bloc/revenue_event.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/bloc/revenue_state.dart';

class RevenueBloc extends Bloc<RevenueEvent, RevenueState> {
  RevenueBloc({
    required GetProducts getProducts,
    required GetCategories getCategories,
    required GetDiscountOptions getDiscountOptions,
    required GetCustomerCredit getCustomerCredit,
  })  : _getProducts = getProducts,
        _getCategories = getCategories,
        _getDiscountOptions = getDiscountOptions,
        _getCustomerCredit = getCustomerCredit,
        super(const RevenueState()) {
    on<RevenueStarted>(_onStarted);
    on<RevenueRetryRequested>(_onStarted);
    on<RevenueSearchChanged>(_onSearchChanged);
    on<RevenueCategorySelected>(_onCategorySelected);
    on<RevenueDiscountSelected>(_onDiscountSelected);
    on<RevenueCartQuantityChanged>(_onCartQuantityChanged);
  }

  final GetProducts _getProducts;
  final GetCategories _getCategories;
  final GetDiscountOptions _getDiscountOptions;
  final GetCustomerCredit _getCustomerCredit;

  Future<void> _onStarted(
      RevenueEvent event, Emitter<RevenueState> emit) async {
    emit(state.copyWith(status: RevenueStatus.loading));

    final results = await (
      _getProducts(const NoParams()),
      _getCategories(const NoParams()),
      _getDiscountOptions(const NoParams()),
      _getCustomerCredit(const NoParams()),
    ).wait;

    final productsResult = results.$1;
    final categoriesResult = results.$2;
    final discountsResult = results.$3;
    final creditResult = results.$4;

    String? errorMessage;
    List<Product> products = const [];
    List<ProductCategory> categories = const [];
    List<DiscountOption> discountOptions = const [];
    CustomerCredit? customerCredit;

    productsResult.when(
        success: (data) => products = data,
        failure: (f) => errorMessage = f.message);
    categoriesResult.when(
        success: (data) => categories = data,
        failure: (f) => errorMessage ??= f.message);
    discountsResult.when(
        success: (data) => discountOptions = data,
        failure: (f) => errorMessage ??= f.message);
    creditResult.when(
        success: (data) => customerCredit = data,
        failure: (f) => errorMessage ??= f.message);

    if (errorMessage != null) {
      emit(state.copyWith(
          status: RevenueStatus.error, errorMessage: errorMessage));
      return;
    }

    final defaultDiscount =
        _firstWhereOrNull(discountOptions, (d) => d.isDefault) ??
            (discountOptions.isEmpty ? null : discountOptions.first);

    emit(state.copyWith(
      status: RevenueStatus.loaded,
      products: products,
      categories: categories,
      discountOptions: discountOptions,
      customerCredit: customerCredit,
      selectedDiscountId: defaultDiscount?.id,
    ));
  }

  void _onSearchChanged(
      RevenueSearchChanged event, Emitter<RevenueState> emit) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onCategorySelected(
      RevenueCategorySelected event, Emitter<RevenueState> emit) {
    emit(state.copyWith(selectedCategoryId: () => event.categoryId));
  }

  void _onDiscountSelected(
      RevenueDiscountSelected event, Emitter<RevenueState> emit) {
    emit(state.copyWith(selectedDiscountId: event.discountId));
  }

  void _onCartQuantityChanged(
      RevenueCartQuantityChanged event, Emitter<RevenueState> emit) {
    final product =
        _firstWhereOrNull(state.products, (p) => p.id == event.productId);
    if (product == null) return;

    final currentQuantity = state.cartQuantities[event.productId] ?? 0;
    final maxQuantity = product.availableStock.floor();
    final nextQuantity = (currentQuantity + event.delta)
        .clamp(0, maxQuantity < 0 ? 0 : maxQuantity);

    final nextCart = Map<String, int>.from(state.cartQuantities);
    if (nextQuantity == 0) {
      nextCart.remove(event.productId);
    } else {
      nextCart[event.productId] = nextQuantity;
    }

    emit(state.copyWith(cartQuantities: nextCart));
  }
}

T? _firstWhereOrNull<T>(List<T> items, bool Function(T) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}
