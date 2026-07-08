import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/cart_item.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_state.dart';

/// Inline cart section shown directly below the product list — not a modal
/// sheet. Appears automatically once the cart has items and scrolls as
/// part of the page itself. Kept deliberately compact (name, qty, line
/// price, remove only) — discounts/credit detail live on the Quotation
/// Detail screen once saved; the Save action lives in the screen's fixed
/// bottom bar instead of here.
class CartPreviewSection extends StatelessWidget {
  const CartPreviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final items = state is CartLoaded ? state.items : const [];

        return AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: items.isEmpty
              ? const SizedBox(width: double.infinity)
              : Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Vibe.stroke.withOpacity(0.8)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Premium Section Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Vibe.violet.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.shopping_bag_outlined, size: 16, color: Vibe.violet),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'orders.quotation.cart_preview_title'.tr,
                              style: const TextStyle(
                                color: Vibe.text, 
                                fontSize: 14, 
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Roboto',
                              ),
                            ),
                            const Spacer(),
                            // Crisp Capsule Item Counter Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Vibe.bgSoft,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Vibe.stroke),
                              ),
                              child: Text(
                                'orders.items_count'.tr.replaceAll('{count}', '${items.length}'),
                                style: const TextStyle(
                                  color: Vibe.violet, 
                                  fontSize: 11, 
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Vibe.stroke, height: 1, thickness: 1),
                      // Scrollable Row Core Container
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            for (int i = 0; i < items.length; i++) ...[
                              _CartRow(
                                key: ValueKey(items[i].id),
                                item: items[i],
                                onQuantityChanged: (q) => context.read<CartCubit>().updateQuantity(items[i].id, q),
                                onRemove: () => context.read<CartCubit>().removeItem(items[i].id),
                              ),
                              if (i < items.length - 1)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Divider(color: Vibe.bgSoft, height: 1, thickness: 1),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

/// A single compact cart row: thumbnail, name, qty stepper, line price, remove
class _CartRow extends StatelessWidget {
  const _CartRow({
    super.key, 
    required this.item, 
    required this.onQuantityChanged, 
    required this.onRemove,
  });

  final CartItem item;
  final ValueChanged<double> onQuantityChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final bool isLastItem = item.quantity <= 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Product Thumbnail Frame with Micro-Border Bounds
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Vibe.stroke.withOpacity(0.5)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.network(
              item.product.imageUrl,
              width: 46,
              height: 46,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 46,
                height: 46,
                color: Vibe.bgSoft,
                alignment: Alignment.center,
                child: const Icon(Icons.inventory_2_outlined, color: Vibe.muted, size: 18),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Structured Detail Metadata Column Block
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Vibe.text, 
                  fontSize: 13, 
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '\$${item.lineTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Vibe.violet, 
                  fontSize: 13, 
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Integrated Quantity Selector Capsule Block
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Vibe.bgSoft,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Vibe.stroke),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QtyButton(
                icon: isLastItem ? Icons.delete_outline_rounded : Icons.remove_rounded,
                iconColor: isLastItem ? Vibe.danger : Vibe.text,
                onTap: () => onQuantityChanged(item.quantity - 1),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 28),
                alignment: Alignment.center,
                child: Text(
                  item.quantity.toStringAsFixed(0),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Vibe.text, 
                    fontSize: 12.5, 
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
              _QtyButton(
                icon: Icons.add_rounded,
                iconColor: Vibe.text,
                onTap: () => onQuantityChanged(item.quantity + 1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Instant Remove Component Hitbox Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.close_rounded, size: 16, color: Vibe.muted),
            ),
          ),
        ),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon, 
    required this.iconColor, 
    required this.onTap,
  });
  
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(icon, size: 14, color: iconColor),
        ),
      ),
    );
  }
}