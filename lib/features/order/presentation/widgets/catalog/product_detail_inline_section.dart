import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/product_detail_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/product_detail_state.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/promotion_badge.dart';

/// Compact product-detail section shown inline directly below the product
/// list when a product is tapped, instead of navigating to a separate
/// screen. Trimmed to the essentials (image, price, stock, Add to Cart) —
/// full specifications/warehouse breakdown stay off this quick-order path.
class ProductDetailInlineSection extends StatefulWidget {
  const ProductDetailInlineSection({
    super.key,
    required this.productId,
    this.leadId,
    required this.onClose,
  });

  final String productId;
  final String? leadId;
  final VoidCallback onClose;

  @override
  State<ProductDetailInlineSection> createState() => _ProductDetailInlineSectionState();
}

class _ProductDetailInlineSectionState extends State<ProductDetailInlineSection> {
  double _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProductDetailCubit>()..load(widget.productId),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Vibe.bgSoft,
          border: Border(top: BorderSide(color: Vibe.stroke)),
        ),
        child: BlocBuilder<ProductDetailCubit, ProductDetailState>(
          builder: (context, state) => switch (state) {
            ProductDetailLoaded() => _Loaded(
                state: state,
                quantity: _quantity,
                onQuantityChanged: (q) => setState(() => _quantity = q),
                leadId: widget.leadId,
                onClose: widget.onClose,
              ),
            ProductDetailError(:final message) => Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: Text(message, style: const TextStyle(color: Vibe.muted))),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: widget.onClose),
                  ],
                ),
              ),
            _ => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(color: Vibe.violet)),
              ),
          },
        ),
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.state,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onClose,
    this.leadId,
  });

  final ProductDetailLoaded state;
  final double quantity;
  final ValueChanged<double> onQuantityChanged;
  final VoidCallback onClose;
  final String? leadId;

  @override
  Widget build(BuildContext context) {
    final product = state.product;
    final cubit = context.read<ProductDetailCubit>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Vibe.text, fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: cubit.toggleFavorite,
                icon: Icon(
                  state.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 20,
                  color: state.isFavorite ? Vibe.danger : Vibe.muted,
                ),
              ),
              IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded, size: 20, color: Vibe.muted)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Vibe.surface,
                      alignment: Alignment.center,
                      child: const Icon(Icons.inventory_2_outlined, color: Vibe.muted, size: 28),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Chip(label: product.code, color: Vibe.muted),
                        if (product.hasPromotion) PromotionBadge(label: product.pricing.promotionLabel ?? 'Sale'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('\$${product.effectivePrice.toStringAsFixed(2)}',
                            style: const TextStyle(color: Vibe.violet, fontSize: 16, fontWeight: FontWeight.w800)),
                        if (product.hasPromotion) ...[
                          const SizedBox(width: 6),
                          Text(
                            '\$${product.pricing.standardPrice.toStringAsFixed(2)}',
                            style: const TextStyle(color: Vibe.disabledText, fontSize: 12, decoration: TextDecoration.lineThrough),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          product.isAvailable ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded,
                          size: 13,
                          color: product.isAvailable ? Vibe.success : Vibe.danger,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product.isAvailable ? '${product.availableQuantity.toStringAsFixed(0)} ${product.unit} available' : 'Out of stock',
                            style: const TextStyle(color: Vibe.muted, fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Row(
            children: [
              _QtyButton(icon: Icons.remove_rounded, onTap: () => onQuantityChanged((quantity - 1).clamp(1, 999999))),
              SizedBox(
                width: 40,
                child: Text(quantity.toStringAsFixed(0),
                    textAlign: TextAlign.center, style: const TextStyle(color: Vibe.text, fontSize: 14, fontWeight: FontWeight.w800)),
              ),
              _QtyButton(icon: Icons.add_rounded, onTap: () => onQuantityChanged(quantity + 1)),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: product.isAvailable
                      ? () {
                          context.read<CartCubit>().addProduct(product, quantity: quantity, leadId: leadId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${product.name} added to cart'), duration: const Duration(seconds: 1)),
                          );
                          onClose();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Vibe.violet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(product.isAvailable ? 'Add to Cart · \$${(product.effectivePrice * quantity).toStringAsFixed(2)}' : 'Out of Stock'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Vibe.surface,
          border: Border.all(color: Vibe.stroke),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: Vibe.text),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
    );
  }
}
