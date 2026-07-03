import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/price_tier.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product_filter.dart';

class ProductIdParams extends Equatable {
  const ProductIdParams(this.productId);
  final String productId;
  @override
  List<Object?> get props => [productId];
}

class BarcodeParams extends Equatable {
  const BarcodeParams(this.barcode);
  final String barcode;
  @override
  List<Object?> get props => [barcode];
}

class BrowseProductsParams extends Equatable {
  const BrowseProductsParams({
    required this.page,
    required this.pageSize,
    this.query = '',
    this.filter = const ProductFilter(),
  });

  final int page;
  final int pageSize;
  final String query;
  final ProductFilter filter;

  @override
  List<Object?> get props => [page, pageSize, query, filter];
}

class CategoryPageParams extends Equatable {
  const CategoryPageParams({required this.categoryId, required this.page, required this.pageSize});
  final String categoryId;
  final int page;
  final int pageSize;
  @override
  List<Object?> get props => [categoryId, page, pageSize];
}

class FamilyIdParams extends Equatable {
  const FamilyIdParams(this.familyId);
  final String familyId;
  @override
  List<Object?> get props => [familyId];
}

class ProductCodeParams extends Equatable {
  const ProductCodeParams(this.code);
  final String code;
  @override
  List<Object?> get props => [code];
}

class PricingParams extends Equatable {
  const PricingParams({required this.productId, required this.tier});
  final String productId;
  final PriceTier tier;
  @override
  List<Object?> get props => [productId, tier];
}

class CartItemIdParams extends Equatable {
  const CartItemIdParams(this.cartItemId);
  final String cartItemId;
  @override
  List<Object?> get props => [cartItemId];
}

class CheckoutParams extends Equatable {
  const CheckoutParams({this.leadId});
  final String? leadId;
  @override
  List<Object?> get props => [leadId];
}
