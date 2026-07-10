import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/customer_credit.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/discount_option.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/product_category.dart';

/// Display-ready product — pre-formats currency/stock text so widgets
/// never format numbers themselves.
class ProductViewModel {
  const ProductViewModel({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.formattedPrice,
    required this.stockLabel,
    required this.inStock,
    required this.maxQuantity,
    required this.quantityInCart,
  });

  final String id;
  final String name;
  final String subtitle;
  final String formattedPrice;
  final String stockLabel;
  final bool inStock;
  final int maxQuantity;
  final int quantityInCart;
}

class CategoryChipViewModel {
  const CategoryChipViewModel(
      {required this.id, required this.label, required this.selected});

  /// `null` id represents the "All" chip.
  final String? id;
  final String label;
  final bool selected;
}

class DiscountChipViewModel {
  const DiscountChipViewModel(
      {required this.id, required this.label, required this.selected});

  final String id;
  final String label;
  final bool selected;
}

class CreditSummaryViewModel {
  const CreditSummaryViewModel({
    required this.customerName,
    required this.formattedAvailableCredit,
    required this.formattedCreditLimit,
    required this.formattedUsedCredit,
    required this.formattedOutstandingBalance,
    required this.usageRatio,
    required this.isOverLimit,
  });

  final String customerName;
  final String formattedAvailableCredit;
  final String formattedCreditLimit;
  final String formattedUsedCredit;
  final String formattedOutstandingBalance;
  final double usageRatio;
  final bool isOverLimit;
}

/// Entity → ViewModel conversions for the Revenue presentation layer.
class RevenueViewModelMapper {
  RevenueViewModelMapper._();

  static String formatCurrency(double value) => '\$${value.toStringAsFixed(2)}';

  static ProductViewModel toProductViewModel(Product product,
      {required int quantityInCart}) {
    return ProductViewModel(
      id: product.id,
      name: product.name,
      subtitle: '${product.sku} · ${product.unit}',
      formattedPrice: formatCurrency(product.unitPrice),
      stockLabel: product.isInStock
          ? '${product.availableStock.toStringAsFixed(0)} in stock'
          : 'Out of stock',
      inStock: product.isInStock,
      maxQuantity: product.availableStock.floor(),
      quantityInCart: quantityInCart,
    );
  }

  static List<CategoryChipViewModel> toCategoryChips(
    List<ProductCategory> categories, {
    required String? selectedId,
  }) {
    return [
      CategoryChipViewModel(
          id: null, label: 'All', selected: selectedId == null),
      for (final category in categories)
        CategoryChipViewModel(
            id: category.id,
            label: category.name,
            selected: category.id == selectedId),
    ];
  }

  static List<DiscountChipViewModel> toDiscountChips(
    List<DiscountOption> options, {
    required String? selectedId,
  }) {
    return [
      for (final option in options)
        DiscountChipViewModel(
            id: option.id,
            label: option.label,
            selected: option.id == selectedId),
    ];
  }

  static CreditSummaryViewModel toCreditSummaryViewModel(
      CustomerCredit credit) {
    return CreditSummaryViewModel(
      customerName: credit.customerName,
      formattedAvailableCredit: formatCurrency(credit.availableCredit),
      formattedCreditLimit: formatCurrency(credit.creditLimit),
      formattedUsedCredit: formatCurrency(credit.usedCredit),
      formattedOutstandingBalance: formatCurrency(credit.outstandingBalance),
      usageRatio: credit.usageRatio,
      isOverLimit: credit.usedCredit > credit.creditLimit,
    );
  }
}
