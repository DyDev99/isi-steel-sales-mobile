import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/promotion_badge.dart';

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

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.3,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox.expand(
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Vibe.bgSoft,
                        alignment: Alignment.center,
                        child: const Icon(Icons.inventory_2_outlined, color: Vibe.muted, size: 28),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: InkWell(
                    onTap: onFavoriteToggle,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
                      child: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 15,
                        color: isFavorite ? Vibe.danger : Vibe.muted,
                      ),
                    ),
                  ),
                ),
                if (product.hasPromotion)
                  Positioned(top: 4, left: 4, child: PromotionBadge(label: product.pricing.promotionLabel ?? 'Sale')),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(product.code, style: const TextStyle(color: Vibe.muted, fontSize: 10.5, fontWeight: FontWeight.w600)),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Vibe.text, fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            '${product.subCategory} · ${product.unit}',
            style: const TextStyle(color: Vibe.muted, fontSize: 11),
          ),
          const SizedBox(height: 4),
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
                      : 'Out of stock',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Vibe.muted, fontSize: 10.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: product.hasPromotion
                    ? Row(
                        children: [
                          Text(
                            '\$${product.effectivePrice.toStringAsFixed(2)}',
                            style: const TextStyle(color: Vibe.violet, fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '\$${product.pricing.standardPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Vibe.disabledText,
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
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
    );
  }
}
