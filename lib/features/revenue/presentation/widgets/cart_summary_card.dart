import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/mapper/revenue_view_model_mapper.dart';

/// Cart Summary — item count and running subtotal, shown inline above the
/// fixed bottom action bar.
class CartSummaryCard extends StatelessWidget {
  const CartSummaryCard(
      {super.key, required this.itemCount, required this.subtotal});

  final int itemCount;
  final double subtotal;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.shopping_cart_outlined,
              color: Vibe.violet, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'revenue.cart.items_count'.tr.replaceAll('{count}', '$itemCount'),
              style: const TextStyle(
                  color: Vibe.text, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            RevenueViewModelMapper.formatCurrency(subtotal),
            style: const TextStyle(
                color: Vibe.violet, fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
