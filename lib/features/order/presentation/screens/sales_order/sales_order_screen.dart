import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/cart_item.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/create_sales_order.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_state.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/success/order_success_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/quotation_line_tile.dart';

/// Fourth step — load the quotation's lines (already seeded into a fresh
/// `CartCubit` by the caller via `loadFromQuotation`), let the rep edit
/// quantities/remove lines, then "Create Sales Order in SAP" (mocked — no
/// numeric repricing, just freezes totals and marks confirmed).
class SalesOrderScreen extends StatefulWidget {
  const SalesOrderScreen({super.key, required this.quotation});

  static const routeName = 'order-sales-order';

  final Quotation quotation;

  @override
  State<SalesOrderScreen> createState() => _SalesOrderScreenState();
}

class _SalesOrderScreenState extends State<SalesOrderScreen> {
  bool _submitting = false;

  Future<void> _create(BuildContext context) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final cartState = context.read<CartCubit>().state;
    final items = cartState is CartLoaded ? cartState.items : const <CartItem>[];

    final result = await sl<CreateSalesOrder>()(CreateSalesOrderParams(quotation: widget.quotation, items: items));

    if (!mounted) return;
    setState(() => _submitting = false);

    result.when(
      success: (order) => Navigator.of(context).pushReplacement(MaterialPageRoute(
        settings: const RouteSettings(name: OrderSuccessScreen.routeName),
        builder: (_) => OrderSuccessScreen(salesOrder: order),
      )),
      failure: (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vibe.bg,
      appBar: AppBar(
        backgroundColor: Vibe.bg,
        iconTheme: const IconThemeData(color: Vibe.text),
        title: Text('orders.sales_order.title'.tr, style: const TextStyle(color: Vibe.text, fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          final items = state is CartLoaded ? state.items : const [];
          final subtotal = state is CartLoaded ? state.subtotal : 0.0;
          final discount = state is CartLoaded ? state.discount : 0.0;
          final tax = state is CartLoaded ? state.tax : 0.0;
          final total = state is CartLoaded ? state.total : 0.0;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  children: [
                    for (final item in items)
                      QuotationLineTile(
                        item: item,
                        showStockStatus: true,
                        onQuantityChanged: (q) => context.read<CartCubit>().updateQuantity(item.id, q),
                        onRemove: () => context.read<CartCubit>().removeItem(item.id),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Vibe.stroke))),
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Row('Subtotal', subtotal),
                      if (discount > 0) _Row('Discount', -discount),
                      _Row('Tax', tax),
                      const Divider(color: Vibe.divider, height: 20),
                      _Row('orders.sales_order.title'.tr, total, emphasize: true),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: (items.isEmpty || _submitting) ? null : () => _create(context),
                          icon: _submitting
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_circle_outline_rounded, size: 20),
                          label: Text('orders.sales_order.create_in_sap'.tr, style: const TextStyle(fontWeight: FontWeight.w800)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Vibe.violet,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
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

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.emphasize = false});
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
                style: TextStyle(color: emphasize ? Vibe.text : Vibe.muted, fontSize: emphasize ? 15 : 13, fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500)),
          ),
          Text('\$${value.toStringAsFixed(2)}',
              style: TextStyle(color: emphasize ? Vibe.violet : Vibe.text, fontSize: emphasize ? 16 : 13, fontWeight: emphasize ? FontWeight.w900 : FontWeight.w600)),
        ],
      ),
    );
  }
}
