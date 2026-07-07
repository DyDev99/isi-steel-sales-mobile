import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/discount_option.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/bloc/revenue_state.dart';

void main() {
  const products = [
    Product(id: 'p1', name: 'Rebar 12mm', sku: 'RB-12', categoryId: 'cat-rebar', unit: 'Ton', unitPrice: 100, availableStock: 10),
    Product(id: 'p2', name: 'Steel Pipe', sku: 'PP-02', categoryId: 'cat-pipe', unit: 'Pcs', unitPrice: 50, availableStock: 4),
  ];
  const discounts = [
    DiscountOption(id: 'd0', label: '0%', percentage: 0, isDefault: true),
    DiscountOption(id: 'd10', label: '10%', percentage: 10),
  ];

  RevenueState baseState({
    Map<String, int> cart = const {},
    String? discountId,
    String? categoryId,
    String search = '',
  }) {
    return RevenueState(
      status: RevenueStatus.loaded,
      products: products,
      discountOptions: discounts,
      cartQuantities: cart,
      selectedDiscountId: discountId,
      selectedCategoryId: categoryId,
      searchQuery: search,
    );
  }

  group('cart math', () {
    test('cartItemCount sums quantities', () {
      expect(baseState(cart: {'p1': 2, 'p2': 3}).cartItemCount, 5);
    });

    test('cartSubtotal multiplies unit price by quantity', () {
      // 100*2 + 50*1 = 250
      expect(baseState(cart: {'p1': 2, 'p2': 1}).cartSubtotal, 250);
    });

    test('discountAmount applies the selected percentage', () {
      // subtotal 200, 10% => 20
      expect(baseState(cart: {'p1': 2}, discountId: 'd10').discountAmount, 20);
    });

    test('cartTotal is subtotal minus discount', () {
      expect(baseState(cart: {'p1': 2}, discountId: 'd10').cartTotal, 180);
    });

    test('no discount selected means zero discount', () {
      expect(baseState(cart: {'p1': 2}).discountAmount, 0);
      expect(baseState(cart: {'p1': 2}).cartTotal, 200);
    });
  });

  group('filtering', () {
    test('filters by category', () {
      final result = baseState(categoryId: 'cat-pipe').filteredProducts;
      expect(result.map((p) => p.id), ['p2']);
    });

    test('search matches name case-insensitively', () {
      final result = baseState(search: 'rebar').filteredProducts;
      expect(result.map((p) => p.id), ['p1']);
    });

    test('search matches sku', () {
      final result = baseState(search: 'pp-02').filteredProducts;
      expect(result.map((p) => p.id), ['p2']);
    });

    test('empty query and null category returns everything', () {
      expect(baseState().filteredProducts.length, 2);
    });

    test('isEmpty is true only when loaded with no matches', () {
      expect(baseState(search: 'nonexistent').isEmpty, isTrue);
      expect(baseState().isEmpty, isFalse);
    });
  });
}
