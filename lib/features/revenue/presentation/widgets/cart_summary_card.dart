import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/mapper/revenue_view_model_mapper.dart';

class CartSummaryCard extends StatelessWidget {
  const CartSummaryCard(
      {super.key, required this.itemCount, required this.subtotal});

  final int itemCount;
  final double subtotal;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(Icons.shopping_cart_outlined,
              color: colors.accentPurple, size: 18), // Replaced Vibe.violet
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'revenue.cart.items_count'.tr.replaceAll('{count}', '$itemCount'),
              style: TextStyle(
                  color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700), // Replaced Vibe.text
            ),
          ),
          Text(
            RevenueViewModelMapper.formatCurrency(subtotal),
            style: TextStyle(
                color: colors.accentPurple, fontSize: 15, fontWeight: FontWeight.w800), // Replaced Vibe.violet
          ),
        ],
      ),
    );
  }
}