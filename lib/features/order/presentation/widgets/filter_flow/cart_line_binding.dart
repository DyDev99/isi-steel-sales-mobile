import 'package:isi_steel_sales_mobile/features/order/domain/entities/cart_item.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_state.dart';

/// Translates "the stepper on this card now reads N" into the right
/// [CartCubit] call.
///
/// Extracted because both hosts of the product finder need exactly this and
/// getting it subtly different in two places is how a cart starts duplicating
/// lines. It adds no quotation logic of its own — it only picks between the
/// cubit's existing add / update / remove, which remain the sole writers.
///
/// Customized lines are deliberately invisible here: they never merge with a
/// plain line, so a stepper must not pick one up and start editing it.
class CartLineBinding {
  const CartLineBinding({
    required this.cart,
    this.leadId,
    this.customerId,
  });

  final CartCubit cart;
  final String? leadId;
  final String? customerId;

  List<CartItem> get _items {
    final state = cart.state;
    return state is CartLoaded ? state.items : const [];
  }

  /// The plain line for [product] in this lead/customer context, if any.
  /// Matches `CartCubit.addProduct`'s own merge rule so the two agree on what
  /// counts as "the same line".
  CartItem? lineFor(Product product) {
    for (final item in _items) {
      if (item.isCustomized) continue;
      if (item.product.id == product.id &&
          item.unit == product.unit &&
          item.leadId == leadId &&
          item.customerId == customerId) {
        return item;
      }
    }
    return null;
  }

  int quantityFor(Product product) => lineFor(product)?.quantity.round() ?? 0;

  /// The single write path from the product list into the quotation.
  ///
  /// Zero removes the line — which is why the stepper needs no separate delete
  /// affordance, and why "add" and "change quantity" are the same gesture.
  Future<void> setQuantity(Product product, int quantity) {
    final existing = lineFor(product);

    if (existing == null) {
      if (quantity <= 0) return Future<void>.value();
      return cart.addProduct(
        product,
        quantity: quantity.toDouble(),
        unit: product.unit,
        leadId: leadId,
        customerId: customerId,
      );
    }
    // updateQuantity already routes <= 0 to removal.
    return cart.updateQuantity(existing.id, quantity.toDouble());
  }

  /// "3 × $11.59 = $34.77" for the in-cart confirmation line.
  String lineTotalLabel(Product product, int quantity) {
    final unitPrice = product.effectivePrice;
    final total = unitPrice * quantity;
    return '$quantity × \$${unitPrice.toStringAsFixed(2)}'
        ' = \$${total.toStringAsFixed(2)}';
  }
}
