import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

/// Fixed Bottom Action Bar — subtotal/discount/total breakdown and the
/// primary "Create Order" action.
class RevenueBottomActionBar extends StatelessWidget {
  const RevenueBottomActionBar({
    super.key,
    required this.subtotal,
    required this.discountAmount,
    required this.total,
    required this.enabled,
    required this.onCreateOrder,
  });

  final double subtotal;
  final double discountAmount;
  final double total;
  final bool enabled;
  final VoidCallback onCreateOrder;

  @override
  Widget build(BuildContext context) {
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
              _SummaryRow(label: 'revenue.cart.subtotal'.tr, value: subtotal),
              if (discountAmount > 0)
                _SummaryRow(
                    label: 'revenue.cart.discount'.tr,
                    value: -discountAmount,
                    isDiscount: true),
              const Divider(color: Vibe.divider, height: 16),
              _SummaryRow(
                  label: 'revenue.cart.total'.tr,
                  value: total,
                  emphasize: true),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: enabled ? onCreateOrder : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Vibe.violet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('revenue.cart.create_order'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(
      {required this.label,
      required this.value,
      this.emphasize = false,
      this.isDiscount = false});

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
                color: emphasize
                    ? Vibe.text
                    : (isDiscount ? Vibe.danger : Vibe.muted),
                fontSize: emphasize ? 15 : 13,
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value < 0
                ? '-\$${(-value).toStringAsFixed(2)}'
                : '\$${value.toStringAsFixed(2)}',
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
