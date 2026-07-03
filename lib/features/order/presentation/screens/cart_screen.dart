import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart_state.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/cart_item_tile.dart';

/// Cart + offline checkout. Shares the [CartCubit] pushed alongside
/// [CatalogScreen] — checking out here writes a `pending_orders` row
/// (works fully offline) and, if [leadId] is set, tags it to that
/// opportunity.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key, this.leadId});
  final String? leadId;

  Future<void> _checkout(BuildContext context) async {
    final order = await context.read<CartCubit>().checkout(leadId: leadId);
    if (!context.mounted) return;
    if (order == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add items to your cart before checking out.')),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Vibe.bgSoft,
        title: const Text('Order placed', style: TextStyle(color: Vibe.text)),
        content: Text(
          'Order ${order.id} for \$${order.total.toStringAsFixed(2)} has been saved and will sync '
          'once you\'re back online.',
          style: const TextStyle(color: Vibe.muted),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vibe.bg,
      appBar: AppBar(
        backgroundColor: Vibe.bg,
        iconTheme: const IconThemeData(color: Vibe.text),
        title: const Text('Cart', style: TextStyle(color: Vibe.text, fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state is! CartLoaded || state.items.isEmpty) {
            return const Center(
              child: Text('Your cart is empty', style: TextStyle(color: Vibe.muted)),
            );
          }

          final cubit = context.read<CartCubit>();
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  children: [
                    for (final item in state.items)
                      CartItemTile(
                        item: item,
                        onQuantityChanged: (q) => cubit.updateQuantity(item.id, q),
                        onRemove: () => cubit.removeItem(item.id),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: const BoxDecoration(color: Vibe.bg, border: Border(top: BorderSide(color: Vibe.stroke))),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      _SummaryRow('Subtotal', state.subtotal),
                      if (state.discount > 0) _SummaryRow('Discount', -state.discount),
                      _SummaryRow('Tax (${(cartTaxRate * 100).toStringAsFixed(0)}%)', state.tax),
                      const Divider(color: Vibe.divider, height: 20),
                      _SummaryRow('Total', state.total, emphasize: true),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _checkout(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Vibe.violet,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.emphasize = false});
  final String label;
  final double value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                  color: emphasize ? Vibe.text : Vibe.muted,
                  fontSize: emphasize ? 15 : 13,
                  fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
                )),
          ),
          Text('\$${value.toStringAsFixed(2)}',
              style: TextStyle(
                color: emphasize ? Vibe.violet : Vibe.text,
                fontSize: emphasize ? 16 : 13,
                fontWeight: emphasize ? FontWeight.w900 : FontWeight.w600,
              )),
        ],
      ),
    );
  }
}
