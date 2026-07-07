import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_state.dart';

class QuotationBottomBar extends StatelessWidget {
  const QuotationBottomBar({
    super.key,
    required this.onSave,
    required this.discount,
  });

  final VoidCallback onSave;
  final int discount;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final items = state is CartLoaded ? state.items : const [];
        final subtotal = state is CartLoaded ? state.subtotal : 0.0;
        final discountAmount = state is CartLoaded ? state.discount : 0.0;
        final tax = state is CartLoaded ? state.tax : 0.0;
        final total = state is CartLoaded ? state.total : 0.0;

        // Safe discount percentage calculation
        final discountPercent = subtotal > 0 
            ? (discountAmount / subtotal * 100).round() 
            : 0;

        return DecoratedBox(
          decoration: const BoxDecoration(
            color: Vibe.surface,
            border: Border(top: BorderSide(color: Vibe.stroke)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryRow('Subtotal', subtotal),

                  // Discount Row
                  if (discountAmount > 0)
                    _SummaryRow(
                      'Discount ($discountPercent%)',
                      -discountAmount,
                      isDiscount: true,
                    ),

                  _SummaryRow('Tax', tax),
                  const Divider(color: Vibe.divider, height: 16),
                  _SummaryRow('Total', total, emphasize: true),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: items.isEmpty ? null : onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Vibe.violet,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'orders.quotation.save_to_sap'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(
    this.label,
    this.value, {
    this.emphasize = false,
    this.isDiscount = false,
  });

  final String label;
  final double value;
  final bool emphasize;
  final bool isDiscount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: emphasize ? Vibe.text : (isDiscount ? Vibe.danger : Vibe.muted),
                fontSize: emphasize ? 15 : 13,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value < 0 ? '-\$${(-value).toStringAsFixed(2)}' : '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              color: emphasize
                  ? Vibe.violet
                  : (isDiscount ? Vibe.danger : Vibe.text),
              fontSize: emphasize ? 16 : 13,
              fontWeight: emphasize ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}