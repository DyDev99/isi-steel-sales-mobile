import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/material_availability.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/filter_flow_transition.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/product_result_card.dart';

/// The resolved product list — the last stage of the flow, and the only one
/// that touches product data.
///
/// A thin arranger over [ProductResultCard]: it owns the stagger and the
/// spacing, nothing else. Everything a card needs is resolved by the caller
/// through the builders, which is what keeps this reusable outside the guided
/// flow (favourites, search results, a future re-order screen).
class ProductResultGrid extends StatelessWidget {
  const ProductResultGrid({
    super.key,
    required this.products,
    required this.favoriteIds,
    required this.quantityFor,
    required this.onQuantityChanged,
    required this.onToggleFavorite,
    this.onTap,
    this.onCustomize,
    this.specLineBuilder,
    this.lineTotalBuilder,
    this.availabilityFor,
  });

  final List<Product> products;
  final Set<String> favoriteIds;

  /// Current cart quantity for a product — the card renders it, never stores
  /// it.
  final int Function(Product product) quantityFor;

  final void Function(Product product, int quantity) onQuantityChanged;
  final ValueChanged<Product> onToggleFavorite;
  final ValueChanged<Product>? onTap;

  /// Shows the per-card "customize" action when provided.
  final ValueChanged<Product>? onCustomize;

  final String Function(Product product)? specLineBuilder;
  final String Function(Product product, int quantity)? lineTotalBuilder;

  /// SAP's sellability verdict for a product, or null when it was never asked.
  ///
  /// A builder rather than a map so this grid stays reusable outside the guided
  /// flow: a screen with no availability data simply does not pass one, and no
  /// card renders a badge.
  final MaterialAvailability? Function(Product product)? availabilityFor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < products.length; i++)
          FilterFlowStaggeredItem(
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Builder(builder: (context) {
                final product = products[i];
                final quantity = quantityFor(product);
                return ProductResultCard(
                  product: product,
                  isFavorite: favoriteIds.contains(product.id),
                  quantity: quantity,
                  specLine: specLineBuilder?.call(product),
                  lineTotalLabel: lineTotalBuilder?.call(product, quantity),
                  onQuantityChanged: (value) =>
                      onQuantityChanged(product, value),
                  onToggleFavorite: () => onToggleFavorite(product),
                  onTap: onTap == null ? null : () => onTap!(product),
                  onCustomize:
                      onCustomize == null ? null : () => onCustomize!(product),
                  availability: availabilityFor?.call(product),
                );
              }),
            ),
          ),
      ],
    );
  }
}
