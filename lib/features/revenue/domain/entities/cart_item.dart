import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/product.dart';

/// A product + quantity pair inside the Revenue cart.
class CartItem extends Equatable {
  const CartItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get lineTotal => product.unitPrice * quantity;

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);

  @override
  List<Object?> get props => [product, quantity];
}
