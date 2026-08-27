import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_text_context.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/material_availability.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/promotion_badge.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/stock_availability_badge.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.onTap,
    required this.isFavorite,
    required this.product,
    required this.onFavoriteToggle,
    required this.onAddToCart,
    this.onCustomize,
    this.stock,
  });

  final Product product;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onAddToCart;

  /// When set, shows a "customize" action that opens the category-aware
  /// customization form instead of adding the plain product.
  final VoidCallback? onCustomize;

  /// SAP's stock read for **this** material, once it has been asked for.
  ///
  /// There is one stock field on this card, not two. It used to carry a
  /// required verdict alongside a nullable one, and the required one was
  /// handed the same object for every row in the list — so one material's band
  /// and base unit were painted onto products nobody had checked.
  ///
  /// Null means the question was never put — the check is a live ERP round
  /// trip spent when a rep commits to a material, not on every card that
  /// scrolls past. Null renders nothing rather than "No stock": declining a
  /// sale because the handset had not asked yet is worse than showing no badge.
  final MaterialAvailability? stock;

  static const _imageSize = 58.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final appColors = context.appColors;

    // Only ever shown next to a verdict. The base unit is read per material
    // (`KG` for coil, `M` for profile) and arrives with the stock read, so
    // before the check there is no unit to state.
    final baseUnit = stock?.baseUnit ?? '';

    return GlassCard(
      padding: EdgeInsets.all(context.rr(8)),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: _imageSize,
                  height: _imageSize,
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: appColors.surfaceSoft,
                      child: Icon(Icons.inventory_2_outlined,
                          color: scheme.onSurface.withValues(alpha: 0.4),
                          size: context.rr(24)),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: InkWell(
                  onTap: onFavoriteToggle,
                  child: Container(
                    padding: EdgeInsets.all(context.rr(3)),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: context.rr(14),
                      color: isFavorite
                          ? scheme.error
                          : scheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
              if (product.hasPromotion)
                const Positioned(
                    top: 2, left: 2, child: PromotionBadge(label: 'Sale')),
            ],
          ),
          SizedBox(width: context.rw(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (product.code.isNotEmpty)
                  Text(
                    product.code,
                    style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.5),
                        fontSize: context.rsp(10),
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  context.localized(product.displayName),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: context.rsp(12.5),
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),

                // The stock row. Absent entirely until the check has been
                // made, which is what keeps an unchecked card honest — the
                // old code printed `band.name.tr` here, and `band.name` is the
                // raw enum name (`"high"`), not a key in the ARB, so it
                // rendered the literal. The band belongs to the badge, which
                // maps it to a real key and a colour.
                if (stock != null) ...[
                  SizedBox(height: context.rh(5)),
                  Row(
                    children: [
                      Flexible(child: StockAvailabilityBadge(availability: stock)),
                      if (baseUnit.isNotEmpty) ...[
                        SizedBox(width: context.rw(5)),
                        Text(
                          baseUnit,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.5),
                            fontSize: context.rsp(10.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],

                SizedBox(height: context.rh(6)),
                Row(
                  children: [
                    Expanded(
                      child: product.pricing.isPriced
                          ? Text(
                              '\$${product.effectivePrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: scheme.primary,
                                fontSize: context.rsp(13.5),
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          // No price was received, so none is shown. The
                          // materials API returns no amount of any kind, and
                          // `\$0.00` would read as free rather than as absent.
                          : Text(
                              'products.price_unavailable'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: scheme.onSurface.withValues(alpha: 0.55),
                                fontSize: context.rsp(11),
                                fontWeight: FontWeight.w700,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                    ),
                    if (onCustomize != null) ...[
                      InkWell(
                        onTap: onCustomize,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.tune_rounded,
                              size: context.rr(16), color: scheme.primary),
                        ),
                      ),
                      SizedBox(width: context.rw(6)),
                    ],
                    _AddButton(
                      // `canOrder` is true while unchecked and while checking —
                      // a rep is not blocked on a question that has not been
                      // answered. It goes false only on a verdict of
                      // `unavailable`, which is SAP actually refusing the line.
                      enabled: stock?.canOrder ?? true,
                      busy: stock?.status == MaterialStockStatus.checking,
                      onTap: onAddToCart,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The `+` action, dimmed rather than hidden when SAP refuses the line.
///
/// Hidden would leave a rep wondering where the button went; dimmed with the
/// refusal sitting next to it in the badge says what happened. It stays
/// tappable, so the snack bar can explain rather than the tap simply dying —
/// "the plus button does nothing" is the symptom worth never shipping again.
class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.enabled,
    required this.busy,
    required this.onTap,
  });

  final bool enabled;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background =
        enabled ? scheme.primary : scheme.onSurface.withValues(alpha: 0.18);

    return InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: busy
            ? SizedBox(
                width: context.rr(16),
                height: context.rr(16),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(scheme.onPrimary),
                ),
              )
            : Icon(Icons.add_shopping_cart_rounded,
                size: context.rr(16), color: scheme.onPrimary),
      ),
    );
  }
}