import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart_state.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/cart_item_tile.dart';

/// Selectable fulfillment channels a cart can be routed to. The default,
/// Mekong Hardware, produces an indicative quotation only — not a firm SAP
/// order — so a rep can price against alternative storefronts before
/// committing.
enum _Shop {
  mekongHardware('mekong_hardware', 'Shop Mekong Hardware (Quotation Only)'),
  alternativeHub('alternative_hub', 'Alternative Fulfillment Hub');

  const _Shop(this.id, this.label);
  final String id;
  final String label;
}

/// Cart + offline checkout. Shares the [CartCubit] pushed alongside
/// [CatalogScreen] — checking out here writes a `pending_orders` row
/// (works fully offline) and, if [leadId] is set, tags it to that
/// opportunity.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key, this.leadId});
  final String? leadId;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  _Shop _selectedShop = _Shop.mekongHardware;

  Future<void> _checkout(BuildContext context) async {
    final order = await context.read<CartCubit>().checkout(leadId: widget.leadId);
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
        title: const Text('Quotation saved', style: TextStyle(color: Vibe.text)),
        content: Text(
          'Quotation ${order.id} for \$${order.total.toStringAsFixed(2)}, routed to '
          '${_selectedShop.label}, has been saved and will sync once you\'re back online.',
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Additional Shop Selection',
                          style: TextStyle(color: Vibe.text, fontSize: 13, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      _ShopSelector(
                        selected: _selectedShop,
                        onChanged: (shop) => setState(() => _selectedShop = shop),
                      ),
                      const Divider(color: Vibe.divider, height: 24),
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

/// Routes the quotation to a storefront/fulfillment channel. Rendered as an
/// explicit tile with a dropdown so the choice is obvious before checkout.
class _ShopSelector extends StatelessWidget {
  const _ShopSelector({required this.selected, required this.onChanged});
  final _Shop selected;
  final ValueChanged<_Shop> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Vibe.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Vibe.stroke),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront_rounded, color: Vibe.violet, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<_Shop>(
                value: selected,
                isExpanded: true,
                dropdownColor: Vibe.bgSoft,
                borderRadius: BorderRadius.circular(12),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Vibe.muted),
                style: const TextStyle(color: Vibe.text, fontSize: 13, fontWeight: FontWeight.w600),
                items: [
                  for (final shop in _Shop.values)
                    DropdownMenuItem(
                      value: shop,
                      child: Text(shop.label, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (shop) {
                  if (shop != null) onChanged(shop);
                },
              ),
            ),
          ),
        ],
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
