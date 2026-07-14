import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart'; // Added for context.appColors
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/customer_params.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/get_customer_by_id.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/catalog_bloc.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/quotation/quotation_builder_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/sales_order/sales_order_screen.dart';

class QuotationDetailScreen extends StatelessWidget {
  const QuotationDetailScreen({super.key, required this.quotation});

  static const routeName = 'order-quotation-detail';

  final Quotation quotation;

  Future<void> _editQuotation(BuildContext context) async {
    Customer? customer;
    if (quotation.customerId != null) {
      final result =
          await sl<GetCustomerById>()(CustomerIdParams(quotation.customerId!));
      customer = result.when(success: (c) => c, failure: (_) => null);
    }
    if (!context.mounted) return;

    Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: QuotationBuilderScreen.routeName),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => sl<CatalogBloc>()),
          BlocProvider(
              create: (_) => sl<CartCubit>()..loadFromQuotation(quotation)),
          BlocProvider(create: (_) => sl<SyncCubit>()),
        ],
        child: LocalizedBuilder(
          builder: (_) => QuotationBuilderScreen(
            customer: customer,
            leadId: quotation.leadId,
            leadDisplayName: quotation.leadDisplayName,
            offVisitReason: quotation.offVisitReason,
            gpsLat: quotation.gpsLatitude,
            gpsLng: quotation.gpsLongitude,
            editingQuotation: quotation,
          ),
        ),
      ),
    ));
  }

  void _convertToSalesOrder(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: SalesOrderScreen.routeName),
      builder: (_) => BlocProvider(
        create: (_) => sl<CartCubit>()..loadFromQuotation(quotation),
        child: SalesOrderScreen(quotation: quotation),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) => LocalizedBuilder(builder: _build);

  Widget _build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final canConvert = !quotation.isLeadScoped;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text('orders.quotation.details_title'.tr,
            style: TextStyle(
                color: colors.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(quotation.id,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(quotation.sapDraftStatus,
                    style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(quotation.shopName ?? quotation.leadDisplayName ?? '',
              style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            '${'orders.quotation.valid_until'.tr}: ${_formatDate(quotation.validUntil)}',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border)),
            child: Column(
              children: [
                for (final line in quotation.lines)
                  _LineRow(
                      name: line.product.name,
                      qty: line.quantity,
                      total: line.lineTotal),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _TotalsCard(quotation: quotation),
          const SizedBox(height: 24),
          if (!canConvert)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('orders.quotation.convert_disabled_lead'.tr,
                  style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic)),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  canConvert ? () => _convertToSalesOrder(context) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                disabledBackgroundColor: colors.border,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('orders.quotation.convert_to_sales_order'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _editQuotation(context),
              child: Text('orders.quotation.edit_quotation'.tr),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.name, required this.qty, required this.total});
  final String name;
  final double qty;
  final double total;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ),
          Text('x${qty.toStringAsFixed(0)}',
              style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(width: 12),
          Text('\$${total.toStringAsFixed(2)}',
              style: TextStyle(
                  color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.quotation});
  final Quotation quotation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.appColors.border)),
      child: Column(
        children: [
          _Row('Subtotal', quotation.subtotal),
          if (quotation.discount > 0) _Row('Discount', -quotation.discount),
          _Row('Tax', quotation.tax),
          Divider(color: context.appColors.divider, height: 20),
          _Row('Total', quotation.total, emphasize: true),
        ],
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
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: emphasize ? colors.textPrimary : colors.textSecondary,
                    fontSize: emphasize ? 15 : 13,
                    fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500)),
          ),
          Text('\$${value.toStringAsFixed(2)}',
              style: TextStyle(
                  color: emphasize ? Theme.of(context).colorScheme.primary : colors.textPrimary,
                  fontSize: emphasize ? 16 : 13,
                  fontWeight: emphasize ? FontWeight.w900 : FontWeight.w600)),
        ],
      ),
    );
  }
}