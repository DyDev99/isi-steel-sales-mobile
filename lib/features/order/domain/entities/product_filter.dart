import 'package:equatable/equatable.dart';

enum ProductSortBy { relevance, nameAsc, priceAsc, priceDesc, stockDesc }

class ProductFilter extends Equatable {
  const ProductFilter({
    this.categoryId,
    this.subCategory,
    this.brand,
    this.warehouseCode,
    this.availableOnly = false,
    this.sortBy = ProductSortBy.relevance,
  });

  final String? categoryId;
  final String? subCategory;
  final String? brand;
  final String? warehouseCode;
  final bool availableOnly;
  final ProductSortBy sortBy;

  bool get isEmpty =>
      categoryId == null &&
      subCategory == null &&
      brand == null &&
      warehouseCode == null &&
      !availableOnly;

  ProductFilter copyWith({
    String? Function()? categoryId,
    String? Function()? subCategory,
    String? Function()? brand,
    String? Function()? warehouseCode,
    bool? availableOnly,
    ProductSortBy? sortBy,
  }) {
    return ProductFilter(
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      subCategory: subCategory != null ? subCategory() : this.subCategory,
      brand: brand != null ? brand() : this.brand,
      warehouseCode: warehouseCode != null ? warehouseCode() : this.warehouseCode,
      availableOnly: availableOnly ?? this.availableOnly,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  List<Object?> get props =>
      [categoryId, subCategory, brand, warehouseCode, availableOnly, sortBy];
}
