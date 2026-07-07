import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';

class CartItem extends Equatable {
  const CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unit,
    required this.discountPercent,
    this.leadId,
    this.customerId,
  });

  final String id;
  final Product product;
  final double quantity;
  final String unit;
  final double discountPercent;
  final String? leadId;
  final String? customerId;

  double get unitPrice => product.effectivePrice;
  double get lineSubtotal => unitPrice * quantity;
  double get lineDiscount => lineSubtotal * (discountPercent / 100);
  double get lineTotal => lineSubtotal - lineDiscount;

  CartItem copyWith({double? quantity, String? unit, double? discountPercent}) {
    return CartItem(
      id: id,
      product: product,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      discountPercent: discountPercent ?? this.discountPercent,
      leadId: leadId,
      customerId: customerId,
    );
  }

  @override
  List<Object?> get props => [id, product, quantity, unit, discountPercent, leadId, customerId];
}
