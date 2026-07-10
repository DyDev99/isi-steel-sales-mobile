import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/cart_item.dart';

class CartItemTile extends StatelessWidget {
  const CartItemTile({
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                item.product.imageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 56,
                  height: 56,
                  color: Vibe.bgSoft,
                  alignment: Alignment.center,
                  child: const Icon(Icons.inventory_2_outlined,
                      color: Vibe.muted, size: 22),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Vibe.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                      '${item.product.code} · \$${item.unitPrice.toStringAsFixed(2)}/${item.unit}',
                      style: const TextStyle(color: Vibe.muted, fontSize: 11)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _QtyButton(
                          icon: Icons.remove_rounded,
                          onTap: () => onQuantityChanged(item.quantity - 1)),
                      SizedBox(
                        width: 36,
                        child: Text(item.quantity.toStringAsFixed(0),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Vibe.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ),
                      _QtyButton(
                          icon: Icons.add_rounded,
                          onTap: () => onQuantityChanged(item.quantity + 1)),
                      const Spacer(),
                      Text('\$${item.lineTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Vibe.violet,
                              fontSize: 14,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Vibe.danger, size: 20),
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Vibe.bgSoft,
          border: Border.all(color: Vibe.stroke),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 13, color: Vibe.text),
      ),
    );
  }
}
