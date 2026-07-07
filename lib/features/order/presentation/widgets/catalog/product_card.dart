import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/promotion_badge.dart';

/// Horizontal product tile: image fixed on the left, all product details
/// (SKU, name, unit, stock, price, Add to Cart) stacked on the right.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onAddToCart,
  });

  final Product product;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onAddToCart;

  static const _imageSize = 84.0;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(8),
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
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Vibe.bgSoft,
                      alignment: Alignment.center,
                      child: const Icon(Icons.inventory_2_outlined, color: Vibe.muted, size: 26),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: InkWell(
                  onTap: onFavoriteToggle,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
                    child: Icon(
                      isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 13,
                      color: isFavorite ? Vibe.danger : Vibe.muted,
                    ),
                  ),
                ),
              ),
              if (product.hasPromotion)
                Positioned(top: 2, left: 2, child: PromotionBadge(label: product.pricing.promotionLabel ?? 'Sale')),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: _imageSize,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.code.isNotEmpty)
                        Text(product.code, style: const TextStyle(color: Vibe.muted, fontSize: 10.5, fontWeight: FontWeight.w600)),
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Vibe.text, fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${product.subCategory} · ${product.unit}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Vibe.muted, fontSize: 11),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            product.isAvailable ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded,
                            size: 12,
                            color: product.isAvailable ? Vibe.success : Vibe.danger,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              product.isAvailable
                                  ? '${product.availableQuantity.toStringAsFixed(0)} ${product.unit} · ${product.warehouseCode}'
                                  : 'orders.catalog.out_of_stock'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Vibe.muted, fontSize: 10.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: product.hasPromotion
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '\$${product.effectivePrice.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Vibe.violet, fontSize: 14, fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      '\$${product.pricing.standardPrice.toStringAsFixed(2)}',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Vibe.disabledText,
                                        fontSize: 11,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                '\$${product.effectivePrice.toStringAsFixed(2)}',
                                style: const TextStyle(color: Vibe.violet, fontSize: 14, fontWeight: FontWeight.w800),
                              ),
                      ),
                      InkWell(
                        onTap: onAddToCart,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(gradient: Vibe.cta, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.add_shopping_cart_rounded, size: 15, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
