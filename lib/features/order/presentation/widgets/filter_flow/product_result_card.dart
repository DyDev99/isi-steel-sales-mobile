import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_text_context.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/material_availability.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/stock_availability_badge.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/cart_quantity_stepper.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

/// One matched SKU, and the only place a product enters the quotation.
///
/// ## Why the SKU line exists
///
/// A `products` row is a sellable SKU: its id is `{code}-{warehouseCode}`, so
/// the same material stocked at three warehouses is three rows. They share a
/// name, a material code and a spec — everything this card used to show — and
/// differed only in an id the rep never saw. Three identical-looking cards, and
/// picking the wrong one meant a quotation that shipped from the wrong plant.
///
/// [Product.sku] and [Product.warehouseCode] are therefore rendered as the
/// card's identity line. It is not decoration; it is the whole difference
/// between the rows.
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
    this.availability,
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

  /// SAP's live sellability verdict, once asked for.
  ///
  /// Asked exactly once per flow, when the rep answers the SKU step — that is
  /// the moment they name a material rather than narrow towards one, and the
  /// only moment worth a live ERP round trip. Null everywhere else, and null
  /// renders no badge at all.
  ///
  /// Takes precedence over the local quantity band below it when both exist:
  /// the ERP's verdict is current, and a synced quantity is as old as the last
  /// sync.
  final MaterialAvailability? availability;

  /// Maps the available quantity onto a status band. The quantity itself is
  /// never rendered — it only decides which band applies.
  ///
  /// Returns null when there is no quantity to band. **The materials API has
  /// no on-hand stock endpoint at all** — no level in units, no warehouse
  /// balance, no ATP — so a material read from it carries
  /// `stockKnown: false`. Banding that as "out of stock" would turn a gap in
  /// the data into a claim about the yard, and a rep would decline a sale on
  /// it. No badge is the honest render.
  _StockStatus? _resolveStockStatus(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    // SAP's own block flag is a verdict rather than a quantity, so it is worth
    // showing even where nothing else about stock is known — it is the one
    // thing that definitely stops an order line.
    if (product.isBlocked) {
      return _StockStatus(
        label: 'products.status.blocked'.tr,
        color: scheme.error,
      );
    }

    if (!product.stockKnown) return null;

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
                              fontSize: context.rsp(14),
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          SizedBox(height: context.rh(3)),
                          // SKU code · stock location. The material code alone
                          // is shared by every warehouse row of this material,
                          // so on its own it cannot tell two result cards
                          // apart — see the class doc.
                          _SkuIdentityLine(product: product),
                          if (specLine != null && specLine!.isNotEmpty) ...[
                            SizedBox(height: context.rh(4)),
                            Text(
                              specLine!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: scheme.primary,
                                fontSize: context.rsp(11.5),
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
                        size: context.rr(18),
                        color: isFavorite ? scheme.error : colors.iconMuted,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.rh(10)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SAP's live verdict wins where it exists; the
                          // banded local quantity is the fallback for the
                          // offline catalog, whose rows do carry a figure.
                          if (availability != null) ...[
                            StockAvailabilityBadge(availability: availability),
                            SizedBox(height: context.rh(4)),
                          ] else if (stockStatus != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    stockStatus.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                stockStatus.label,
                                style: TextStyle(
                                  color: stockStatus.color,
                                  fontSize: context.rsp(10.5),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            SizedBox(height: context.rh(4)),
                          ],
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              // Shown only when an amount was actually
                              // received. The materials API returns no price
                              // of any kind — no list, no condition, no
                              // currency — and `\$0.00` would read as free
                              // rather than as missing.
                              if (product.pricing.isPriced) ...[
                                Text(
                                  '\$${product.effectivePrice.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: context.rsp(16),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(width: context.rw(4)),
                              ] else ...[
                                Text(
                                  'products.price_unavailable'.tr,
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: context.rsp(11.5),
                                    fontWeight: FontWeight.w700,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                SizedBox(width: context.rw(4)),
                              ],
                              if (product.unit.isNotEmpty)
                                Text(
                                  '/ ${product.unit}',
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: context.rsp(11),
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
                      SizedBox(width: context.rw(8)),
                    ],
                    CartQuantityStepper(
                      quantity: quantity,
                      enabled: available,
                      // Capped at what this SKU's own warehouse can back, so
                      // the `+` stops rather than the rep discovering the
                      // limit only after tapping. A made-to-order SKU is
                      // produced against the order, so stock is not its
                      // constraint and it stays unbounded.
                      max: product.isMto
                          ? null
                          : product.availableQuantity.floor(),
                      onChanged: onQuantityChanged,
                    ),
                    SizedBox(width: context.rw(4)),
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
                                size: context.rr(14),
                                color: scheme.primary,
                              ),
                              SizedBox(width: context.rw(6)),
                              Text(
                                lineTotalLabel!,
                                style: TextStyle(
                                  color: scheme.primary,
                                  fontSize: context.rsp(12),
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

/// The SKU code and the warehouse holding it — the two facts that separate one
/// result card from its siblings for the same material.
///
/// The warehouse is a chip rather than more grey text because "which location"
/// is a decision the rep makes, not a reference number they read. Falls back to
/// the material code when SAP publishes no distinct SKU string, so the line is
/// never blank.
class _SkuIdentityLine extends StatelessWidget {
  const _SkuIdentityLine({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final skuLabel =
        product.sku.trim().isNotEmpty ? product.sku : product.materialCode;

    return Row(
      children: [
        Flexible(
          child: Text(
            skuLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: context.rsp(11),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (product.warehouseCode.trim().isNotEmpty) ...[
          SizedBox(width: context.rw(6)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warehouse_rounded,
                  size: context.rr(11),
                  color: scheme.primary,
                ),
                SizedBox(width: context.rw(3)),
                Text(
                  product.warehouseCode,
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: context.rsp(10.5),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
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
            child: Icon(icon, size: context.rr(17), color: foreground),
          ),
        ),
      );
}
