import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_text_context.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/cart_quantity_stepper.dart';

/// One matched SKU, and the only place a product enters the quotation.
///
/// The stock badge is *categorical*, never a raw number: the quantity is the
/// condition, the label is a status. A rep deciding whether to quote needs
/// "can I sell this", not an inventory readout — and an exact count on a card
/// is a number they will read as a promise the moment it goes stale.
///
/// [Product.availableQuantity] selects the band:
/// - `'products.status.out_of_stock'.tr` — nothing sellable
/// - `'products.status.low_stock'.tr` — <= [lowStockThreshold]
/// - `'products.status.in_stock'.tr` — up to [mediumStockThreshold]
/// - `'products.status.high_stock'.tr` — above it
class ProductResultCard extends StatelessWidget {
  const ProductResultCard({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onToggleFavorite,
    this.specLine,
    this.lineTotalLabel,
    this.onTap,
    this.onCustomize,
    this.lowStockThreshold = 10,
    this.mediumStockThreshold = 50,
  });

  final Product product;
  final bool isFavorite;

  /// How many of this SKU are currently in the cart.
  final int quantity;

  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onToggleFavorite;

  /// Optional override spec line (e.g. "0.30 mm · 3.90 m").
  final String? specLine;

  /// Pre-formatted line total label (e.g. "3 × $11.59 = $34.77").
  final String? lineTotalLabel;

  final VoidCallback? onTap;
  final VoidCallback? onCustomize;

  /// Custom threshold boundaries for stock categories
  final int lowStockThreshold;
  final int mediumStockThreshold;

  /// Maps the available quantity onto a status band. The quantity itself is
  /// never rendered — it only decides which band applies.
  _StockStatus _resolveStockStatus(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    // `availableQuantity`, not `stockQuantity`: reserved units are already
    // spoken for and cannot be quoted, so counting them would badge a SKU as
    // "high stock" that a rep cannot actually sell. `isAvailable` is derived
    // from the same figure, which keeps the badge and the stepper's enabled
    // state agreeing with each other.
    final available = product.availableQuantity;

    if (!product.isAvailable) {
      return _StockStatus(
        label: 'products.status.out_of_stock'.tr,
        color: scheme.error,
      );
    }

    if (available <= lowStockThreshold) {
      return _StockStatus(
        label: 'products.status.low_stock'.tr,
        color: colors.warning,
      );
    } else if (available <= mediumStockThreshold) {
      return _StockStatus(
        label: 'products.status.in_stock'.tr,
        color: scheme.primary,
      );
    } else {
      return _StockStatus(
        label: 'products.status.high_stock'.tr,
        color: colors.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final available = product.isAvailable;
    final inCart = quantity > 0;
    final stockStatus = _resolveStockStatus(context);

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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.localized(product.displayName),
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
                          // Stock status badge using products.status keys
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: stockStatus.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              stockStatus.label,
                              style: TextStyle(
                                color: stockStatus.color,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
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
                AnimatedSize(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: inCart && lineTotalLabel != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: scheme.primary,
                              ),
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

class _StockStatus {
  const _StockStatus({required this.label, required this.color});
  final String label;
  final Color color;
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
