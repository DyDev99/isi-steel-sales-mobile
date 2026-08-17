import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart'
    show ResultFuture;
import 'package:isi_steel_sales_mobile/features/order/domain/entities/order_line_validation.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/product_repository.dart';

class ValidateOrderLineParams extends Equatable {
  const ValidateOrderLineParams({
    required this.skuId,
    required this.quantity,
    this.alreadyInCart = 0,
  });

  /// `products.id` — the exact SKU, warehouse included.
  final String skuId;

  /// What the rep is asking for *in total* for this line, not the delta.
  final double quantity;

  /// Units of this same SKU already committed on other lines of the same cart
  /// (a customized line and a plain line draw on the same warehouse stock).
  /// Counted against availability so two lines cannot each pass on their own
  /// and together over-commit the warehouse.
  final double alreadyInCart;

  @override
  List<Object?> get props => [skuId, quantity, alreadyInCart];
}

/// Decides whether a requested SKU + quantity may enter the cart.
///
/// Re-reads the SKU from the repository rather than trusting the [Product] the
/// UI is holding: the card on screen may have been rendered before the last
/// catalog sync, and the whole point of this check is to catch exactly that.
///
/// The figure it checks against is the **last synced** local stock, never a
/// live SAP reservation — the order UI does not call SAP (ADR-002). That is
/// reported honestly through [OrderLineValidation.isStockStale] rather than
/// papered over, so the UI can say "as of last sync" instead of implying a
/// guarantee the app cannot make.
class ValidateOrderLine
    extends UseCase<OrderLineValidation, ValidateOrderLineParams> {
  const ValidateOrderLine(this._products);

  final ProductRepository _products;

  @override
  ResultFuture<OrderLineValidation> call(ValidateOrderLineParams params) async {
    if (params.quantity <= 0) {
      return Success(OrderLineValidation(
        issue: OrderLineIssue.nonPositiveQuantity,
        requestedQuantity: params.quantity,
        availableQuantity: 0,
        isStockStale: true,
      ));
    }

    final result = await _products.getProduct(params.skuId);
    return result.when(
      success: (product) => Success(_verdict(product, params)),
      // A SKU that no longer resolves is unavailable, not an error the rep
      // should see as a crash — it is the deleted/re-keyed material case.
      failure: (f) => f is CacheFailure
          ? Success(OrderLineValidation(
              issue: OrderLineIssue.skuUnavailable,
              requestedQuantity: params.quantity,
              availableQuantity: 0,
              isStockStale: true,
            ))
          : Failed(f),
    );
  }

  OrderLineValidation _verdict(Product sku, ValidateOrderLineParams params) {
    final available = sku.availableQuantity;

    if (!sku.isAvailable) {
      return OrderLineValidation(
        issue: OrderLineIssue.skuUnavailable,
        requestedQuantity: params.quantity,
        availableQuantity: available,
        isStockStale: true,
      );
    }

    // Made-to-order lines are produced against the order, so warehouse stock is
    // not the constraint and quoting more than is on the floor is normal.
    if (!sku.isMto && params.quantity + params.alreadyInCart > available) {
      return OrderLineValidation(
        issue: OrderLineIssue.exceedsAvailableStock,
        requestedQuantity: params.quantity,
        availableQuantity: available,
        isStockStale: true,
      );
    }

    return OrderLineValidation.valid(
      requestedQuantity: params.quantity,
      availableQuantity: available,
      isStockStale: true,
    );
  }
}

/// Convenience for callers that already hold a freshly-read [Product] and only
/// need the rule, not the round-trip — the product grid re-renders on every
/// cart change and must not fire a database read per card.
OrderLineValidation validateAgainstSku({
  required Product sku,
  required double quantity,
  double alreadyInCart = 0,
}) {
  if (quantity <= 0) {
    return OrderLineValidation(
      issue: OrderLineIssue.nonPositiveQuantity,
      requestedQuantity: quantity,
      availableQuantity: sku.availableQuantity,
      isStockStale: true,
    );
  }
  if (!sku.isAvailable) {
    return OrderLineValidation(
      issue: OrderLineIssue.skuUnavailable,
      requestedQuantity: quantity,
      availableQuantity: sku.availableQuantity,
      isStockStale: true,
    );
  }
  if (!sku.isMto && quantity + alreadyInCart > sku.availableQuantity) {
    return OrderLineValidation(
      issue: OrderLineIssue.exceedsAvailableStock,
      requestedQuantity: quantity,
      availableQuantity: sku.availableQuantity,
      isStockStale: true,
    );
  }
  return OrderLineValidation.valid(
    requestedQuantity: quantity,
    availableQuantity: sku.availableQuantity,
    isStockStale: true,
  );
}
