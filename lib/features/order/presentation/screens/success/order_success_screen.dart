import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/sales_order.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/off_visit_reason_sheet.dart';

/// Final step of the order flow. [onNewOrder] is null for the Lead/Route
/// Stock Count entry points (which don't re-enter Territory picking), which
/// simply hides the "New Order" action.
class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen(
      {super.key, required this.salesOrder, this.onDone, this.onNewOrder});

  static const routeName = 'order-success';

  final SalesOrder salesOrder;
  final VoidCallback? onDone;
  final VoidCallback? onNewOrder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vibe.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Center(
                      child: Container(
                        width: 84,
                        height: 84,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: Vibe.success.withValues(alpha: 0.14),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded,
                            color: Vibe.success, size: 44),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(salesOrder.id,
                          style: const TextStyle(
                              color: Vibe.text,
                              fontSize: 22,
                              fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                          salesOrder.shopName ??
                              salesOrder.leadDisplayName ??
                              '',
                          style:
                              const TextStyle(color: Vibe.muted, fontSize: 13)),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Vibe.stroke)),
                      child: Column(
                        children: [
                          _Row('orders.sales_order.title'.tr,
                              '\$${salesOrder.total.toStringAsFixed(2)}',
                              emphasize: true),
                          if (salesOrder.offVisitReason != null)
                            _Row('orders.shop.off_visit_warning'.tr,
                                salesOrder.offVisitReason!.localizedLabel),
                          _Row('orders.quotation.builder_title'.tr,
                              salesOrder.quotationId),
                          _Row('orders.sales_order.sap_status'.tr,
                              salesOrder.sapStatus),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('orders.success.sap_message'.tr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Vibe.muted, fontSize: 12.5, height: 1.4)),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onDone ??
                      () => Navigator.of(context).popUntil((r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Vibe.violet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('orders.success.done'.tr,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              if (onNewOrder != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                      onPressed: onNewOrder,
                      child: Text('orders.success.new_order'.tr)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.emphasize = false});
  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(color: Vibe.muted, fontSize: 12.5))),
          Text(value,
              style: TextStyle(
                color: emphasize ? Vibe.violet : Vibe.text,
                fontSize: emphasize ? 16 : 13,
                fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
              )),
        ],
      ),
    );
  }
}
