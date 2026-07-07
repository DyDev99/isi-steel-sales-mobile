import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/customer_credit.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/discount_option.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/product_category.dart';

enum RevenueStatus { initial, loading, loaded, error }

class RevenueState extends Equatable {
  const RevenueState({
    this.status = RevenueStatus.initial,
    this.products = const [],
    this.categories = const [],
    this.discountOptions = const [],
    this.customerCredit,
    this.searchQuery = '',
    this.selectedCategoryId,
    this.selectedDiscountId,
    this.cartQuantities = const {},
    this.errorMessage,
  });

  final RevenueStatus status;
  final List<Product> products;
  final List<ProductCategory> categories;
  final List<DiscountOption> discountOptions;
  final CustomerCredit? customerCredit;
  final String searchQuery;
  final String? selectedCategoryId;
  final String? selectedDiscountId;

  /// productId -> quantity in cart.
  final Map<String, int> cartQuantities;
  final String? errorMessage;

  List<Product> get filteredProducts {
    final query = searchQuery.trim().toLowerCase();
    return products.where((product) {
      final matchesCategory = selectedCategoryId == null || product.categoryId == selectedCategoryId;
      final matchesQuery = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.sku.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  DiscountOption? get selectedDiscount {
    if (selectedDiscountId == null) return null;
    for (final option in discountOptions) {
      if (option.id == selectedDiscountId) return option;
    }
    return null;
  }

  int get cartItemCount => cartQuantities.values.fold(0, (sum, qty) => sum + qty);

  double get cartSubtotal {
    var subtotal = 0.0;
    for (final product in products) {
      final quantity = cartQuantities[product.id] ?? 0;
      if (quantity > 0) subtotal += product.unitPrice * quantity;
    }
    return subtotal;
  }

  double get discountAmount => cartSubtotal * ((selectedDiscount?.percentage ?? 0) / 100);

  double get cartTotal => cartSubtotal - discountAmount;

  bool get isEmpty => status == RevenueStatus.loaded && filteredProducts.isEmpty;

  RevenueState copyWith({
    RevenueStatus? status,
    List<Product>? products,
    List<ProductCategory>? categories,
    List<DiscountOption>? discountOptions,
    CustomerCredit? customerCredit,
    String? searchQuery,
    String? Function()? selectedCategoryId,
    String? selectedDiscountId,
    Map<String, int>? cartQuantities,
    String? errorMessage,
  }) {
    return RevenueState(
      status: status ?? this.status,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      discountOptions: discountOptions ?? this.discountOptions,
      customerCredit: customerCredit ?? this.customerCredit,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: selectedCategoryId != null ? selectedCategoryId() : this.selectedCategoryId,
      selectedDiscountId: selectedDiscountId ?? this.selectedDiscountId,
      cartQuantities: cartQuantities ?? this.cartQuantities,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        products,
        categories,
        discountOptions,
        customerCredit,
        searchQuery,
        selectedCategoryId,
        selectedDiscountId,
        cartQuantities,
        errorMessage,
      ];
}
