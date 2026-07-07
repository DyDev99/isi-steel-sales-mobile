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
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: items.isEmpty
              ? const SizedBox(width: double.infinity)
              : DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Vibe.bgSoft,
                    border: Border(top: BorderSide(color: Vibe.stroke)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Row(
                          children: [
                            const Icon(Icons.shopping_cart_rounded, size: 16, color: Vibe.violet),
                            const SizedBox(width: 6),
                            Text(
                              'orders.quotation.cart_preview_title'.tr,
                              style: const TextStyle(color: Vibe.text, fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'orders.items_count'.tr.replaceAll('{count}', '${items.length}'),
                              style: const TextStyle(color: Vibe.muted, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Column(
                          children: [
                            for (final item in items)
                              _CartRow(
                                key: ValueKey(item.id),
                                item: item,
                                onQuantityChanged: (q) => context.read<CartCubit>().updateQuantity(item.id, q),
                                onRemove: () => context.read<CartCubit>().removeItem(item.id),
                              ),
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

/// A single compact cart row: thumbnail, name, qty stepper, line price,
/// remove — no SKU/unit line, no discount chips.
class _CartRow extends StatelessWidget {
  const _CartRow({super.key, required this.item, required this.onQuantityChanged, required this.onRemove});

  final CartItem item;
  final ValueChanged<double> onQuantityChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Vibe.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Vibe.stroke),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.product.imageUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 44,
                  height: 44,
                  color: Vibe.bgSoft,
                  alignment: Alignment.center,
                  child: const Icon(Icons.inventory_2_outlined, color: Vibe.muted, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Vibe.text, fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            _QtyButton(icon: Icons.remove_rounded, onTap: () => onQuantityChanged(item.quantity - 1)),
            SizedBox(
              width: 26,
              child: Text(item.quantity.toStringAsFixed(0),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Vibe.text, fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
            _QtyButton(icon: Icons.add_rounded, onTap: () => onQuantityChanged(item.quantity + 1)),
            const SizedBox(width: 8),
            SizedBox(
              width: 52,
              child: Text(
                '\$${item.lineTotal.toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                style: const TextStyle(color: Vibe.violet, fontSize: 12.5, fontWeight: FontWeight.w800),
              ),
            ),
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 16, color: Vibe.danger),
              ),
            ),
          ],
        ),
      ),
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
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Vibe.bgSoft,
          border: Border.all(color: Vibe.stroke),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 12, color: Vibe.text),
      ),
    );
  }
}
