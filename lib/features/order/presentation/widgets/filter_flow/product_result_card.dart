import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_text_context.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/promotion/promotion_evaluation.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/cart_quantity_stepper.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/promotion/promotion_inline_block.dart';
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
/// ## No stock, no price
///
/// This card identifies a material and nothing more. Material selection is
/// independent of stock and pricing: a rep may put any catalogue material on a
/// quotation, and HQ prices it afterwards.
///
/// Showing either here was worse than useless. The materials API supplies no
/// on-hand quantity and no price, so a band read "No stock" and an amount read
/// `$0.00` for materials that were perfectly orderable — and both then gated
/// the `+`. A rep declined sales over data the server had never sent.
///
/// Stock and price are still fetched and still shown further down the flow,
/// where they inform rather than block.
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
    this.promotion,
    this.onPromotionTap,
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

  /// What this customer earns on this material at the current quantity.
  ///
  /// Null is the common case and renders nothing — an empty promotion strip on
  /// every unpromoted product would be permanent noise on the busiest screen
  /// in the app.
  ///
  /// Resolved upstream by `PromotionCubit`; the card never works out
  /// eligibility for itself, so it cannot disagree with the rule that will be
  /// applied to the order.
  final PromotionEvaluation? promotion;

  final VoidCallback? onPromotionTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final inCart = quantity > 0;

    // What the material *is*: the group it belongs to and the unit it sells
    // by. Both come with the row; neither needs a stock or price read.
    final identity = [
      if (product.familyName.isNotEmpty) product.familyName,
      if (product.unit.isNotEmpty) product.unit,
    ].join(' · ');

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
                // Between "what is it" and "how many" — the promotion is an
                // input to the quantity decision, so it has to be read before
                // the stepper, not after it.
                if (promotion != null) ...[
                  SizedBox(height: context.rh(8)),
                  PromotionInlineBlock(
                    evaluation: promotion,
                    onTap: onPromotionTap,
                  ),
                ],
                SizedBox(height: context.rh(10)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Identification only — no band, no amount.
                          // Category and unit say what the material *is*;
                          // stock and price are neither known here nor needed
                          // to add it to the cart.
                          if (identity.isNotEmpty)
                            Text(
                              identity,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: context.rsp(11.5),
                                fontWeight: FontWeight.w600,
                              ),
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
                    // Ungated. Any catalogue material may be added; stock and
                    // price are settled later in the flow, not here.
                    CartQuantityStepper(
                      quantity: quantity,
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
