import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/cart_quantity_stepper.dart';

/// One matched SKU, and the only place a product enters the quotation.
///
/// There is no "Add" button: the stepper *is* the commit. Quantity above zero
/// means this line is in the quotation, and the card says so — the border and
/// the running line total change — so the rep never has to look elsewhere to
/// confirm the tap landed.
class ProductResultCard extends StatelessWidget {
  const ProductResultCard({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onToggleFavorite,
    this.specLine,
    this.stockLabel,
    this.outOfStockLabel,
    this.lineTotalLabel,
    this.onTap,
    this.onCustomize,
  });

  final Product product;
  final bool isFavorite;

  /// How many of this SKU are currently in the cart. Comes from `CartCubit`,
  /// so the card has no quantity state of its own to drift out of sync.
  final int quantity;

  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onToggleFavorite;

  /// "0.30 mm · 3.90 m" — the answered specs, echoed back.
  final String? specLine;
  final String? stockLabel;
  final String? outOfStockLabel;

  /// Pre-formatted "3 × $11.59 = $34.77", shown only once in the cart.
  final String? lineTotalLabel;

  final VoidCallback? onTap;
  final VoidCallback? onCustomize;

  static const _imageSize = 56.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final available = product.isAvailable;
    final inCart = quantity > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: inCart ? scheme.primary : colors.border,
          width: inCart ? 1.4 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProductThumbnail(url: product.imageUrl),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            product.materialCode,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (specLine != null && specLine!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              specLine!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: scheme.primary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onToggleFavorite,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 18,
                        color: isFavorite ? scheme.error : colors.iconMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            available
                                ? (stockLabel ?? '')
                                : (outOfStockLabel ?? ''),
                            style: TextStyle(
                              color:
                                  available ? colors.success : colors.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '\$${product.effectivePrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '/ ${product.unit}',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (onCustomize != null) ...[
                      _SquareAction(
                        icon: Icons.tune_rounded,
                        background: scheme.primary.withValues(alpha: 0.12),
                        foreground: scheme.primary,
                        onTap: onCustomize!,
                      ),
                      const SizedBox(width: 8),
                    ],
                    CartQuantityStepper(
                      quantity: quantity,
                      enabled: available,
                      onChanged: onQuantityChanged,
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
                // Only shown once the line exists, so an untouched card stays
                // as short as it was.
                AnimatedSize(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: inCart && lineTotalLabel != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 14, color: scheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                lineTotalLabel!,
                                style: TextStyle(
                                  color: scheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    Widget placeholder() => Container(
          width: ProductResultCard._imageSize,
          height: ProductResultCard._imageSize,
          color: colors.surfaceSoft,
          alignment: Alignment.center,
          child: Icon(Icons.inventory_2_outlined,
              color: colors.textHint, size: 22),
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: url.isEmpty
          ? placeholder()
          : Image.network(
              url,
              width: ProductResultCard._imageSize,
              height: ProductResultCard._imageSize,
              fit: BoxFit.cover,
              // A steel catalog photo is never worth blocking the row on, so a
              // failed or slow fetch degrades to the placeholder silently.
              errorBuilder: (_, __, ___) => placeholder(),
              frameBuilder: (_, child, frame, wasSync) =>
                  wasSync || frame != null ? child : placeholder(),
            ),
    );
  }
}

class _SquareAction extends StatelessWidget {
  const _SquareAction({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: background,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Icon(icon, size: 17, color: foreground),
          ),
        ),
      );
}
