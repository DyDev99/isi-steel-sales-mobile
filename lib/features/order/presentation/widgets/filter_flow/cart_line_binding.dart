import 'package:isi_steel_sales_mobile/features/order/domain/entities/cart_item.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/order_line_validation.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/validate_order_line.dart';
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
/// Customized lines are deliberately invisible to [lineFor], so a stepper never
/// picks one up and starts editing it. They *are* counted by
/// [committedQuantityFor], because a customized line still draws on the same
/// warehouse stock as a plain one.
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
  ///
  /// Compares on `product.id`, which is the SKU — material *and* warehouse.
  /// The same material held at two warehouses is two SKUs and therefore two
  /// lines, which is the behaviour the sales team needs: the pick list has to
  /// say which plant each line ships from.
  CartItem? lineFor(Product product) {
    for (final item in _items) {
      if (item.isCustomized) continue;
      if (item.product.id == product.id &&
          item.unit == product.unit &&
          item.leadId == leadId &&
          item.customerId == customerId &&
          item.fulfillment == null) {
        return item;
      }
    }
    return null;
  }

  int quantityFor(Product product) => lineFor(product)?.quantity.round() ?? 0;

  /// Everything already committed against this SKU across the whole cart —
  /// customized lines and key-in lines included.
  ///
  /// Two lines that each fit inside available stock can together exceed it, so
  /// the stock check has to see the cart, not just the line being edited.
  double committedQuantityFor(Product product, {String? excludingLineId}) {
    var total = 0.0;
    for (final item in _items) {
      if (item.product.id != product.id) continue;
      if (item.id == excludingLineId) continue;
      total += item.quantity;
    }
    return total;
  }

  /// Whether [quantity] of [product] may be committed, without writing
  /// anything. Synchronous by design: the product grid re-renders on every cart
  /// change, so this cannot cost a database read per card.
  ///
  /// Checks against the SKU the card is already holding, which came from the
  /// last catalog sync — [OrderLineValidation.isStockStale] says so rather than
  /// implying the app reserved anything in SAP.
  OrderLineValidation validate(Product product, int quantity) {
    final existing = lineFor(product);
    return validateAgainstSku(
      sku: product,
      quantity: quantity.toDouble(),
      alreadyInCart:
          committedQuantityFor(product, excludingLineId: existing?.id),
    );
  }

  /// The single write path from the product list into the quotation.
  ///
  /// Zero removes the line — which is why the stepper needs no separate delete
  /// affordance, and why "add" and "change quantity" are the same gesture.
  ///
  /// Returns the verdict so the caller can surface *why* nothing happened. A
  /// silent no-op would be the worse failure: the rep taps `+`, the number
  /// doesn't move, and there is nothing on screen explaining that the branch
  /// only has 45 left.
  Future<OrderLineValidation> setQuantity(Product product, int quantity) async {
    final existing = lineFor(product);

    // Removal is always allowed — it can only ever free stock up.
    if (quantity <= 0) {
      if (existing == null) {
        return OrderLineValidation.valid(
          requestedQuantity: 0,
          availableQuantity: product.availableQuantity,
          isStockStale: true,
        );
      }
      await cart.updateQuantity(existing.id, 0);
      return OrderLineValidation.valid(
        requestedQuantity: 0,
        availableQuantity: product.availableQuantity,
        isStockStale: true,
      );
    }

    final verdict = validate(product, quantity);
    if (!verdict.isValid) return verdict;

    if (existing == null) {
      await cart.addProduct(
        product,
        quantity: quantity.toDouble(),
        unit: product.unit,
        leadId: leadId,
        customerId: customerId,
        // Freeze what the card was showing when the rep tapped. Without this
        // the line silently re-prices on the next catalog sync — including on
        // a quotation the customer has already been shown.
        //
        // Null when there is nothing to freeze. `effectivePrice` answers `0.0`
        // for an unpriced material, and snapshotting that zero would make the
        // line look *priced* — `CartItem.pricingStatus` reads a non-null
        // override as authoritative — so the quotation would print `$0.00`
        // instead of "Waiting for HQ".
        unitPrice: product.pricing.isPriced ? product.effectivePrice : null,
      );
    } else {
      await cart.updateQuantity(existing.id, quantity.toDouble());
    }
    return verdict;
  }

  /// "3 × \$11.59 = \$34.77" for the in-cart confirmation line, or just the
  /// quantity while the material has no official price.
  ///
  /// Reads the committed line's own price when there is one, so the label keeps
  /// showing what was agreed rather than what the catalog currently lists.
  String lineTotalLabel(Product product, int quantity) {
    final line = lineFor(product);

    // A committed line answers for itself; an uncommitted one is pending
    // exactly when the catalogue has no price for the material. Either way the
    // quantity is still shown — the line is valid, only the amount is missing.
    // No amount to show, so none is shown — not a placeholder. The quantity
    // still confirms the line went in.
    final pending = line?.isPricePending ?? !product.pricing.isPriced;
    if (pending) return '$quantity × ${product.unit}';

    final unitPrice = line?.unitPrice ?? product.effectivePrice;
    final total = unitPrice * quantity;
    return '$quantity × \$${unitPrice.toStringAsFixed(2)}'
        ' = \$${total.toStringAsFixed(2)}';
  }
}
