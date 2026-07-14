import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/cart_item.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_state.dart';

class CartPreviewSection extends StatelessWidget {
  const CartPreviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.card,
                    border: Border(
                      top: BorderSide(color: colors.border),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'orders.shop.cart_preview'.tr,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => Divider(
                          color: colors.divider,
                          height: 16,
                        ),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _CartPreviewRow(
                            item: item,
                            onQuantityChanged: (qty) => context
                                .read<CartCubit>()
                                .updateQuantity(item.product.id, qty),
                            onRemove: () => context
                                .read<CartCubit>()
                                .removeItem(item.product.id),
                          );
                        },
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _CartPreviewRow extends StatelessWidget {
  const _CartPreviewRow({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final CartItem item;
  final ValueChanged<double> onQuantityChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '\$${item.lineTotal.toStringAsFixed(2)}',
                style: TextStyle(
                  color: colors.accentPurple,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceSoft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              _QtyButton(
                icon: Icons.remove_rounded,
                iconColor: colors.textPrimary,
                onTap: () => onQuantityChanged(item.quantity - 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  item.quantity.toStringAsFixed(0),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _QtyButton(
                icon: Icons.add_rounded,
                iconColor: colors.textPrimary,
                onTap: () => onQuantityChanged(item.quantity + 1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: colors.textHint,
              ),
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
    final colors = Theme.of(context).extension<AppThemeColors>()!;

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
            color: colors.card,
            borderRadius: BorderRadius.circular(6),
            boxShadow: colors.cardShadow,
          ),
          child: Icon(icon, size: 14, color: iconColor),
        ),
      ),
    );
  }
}