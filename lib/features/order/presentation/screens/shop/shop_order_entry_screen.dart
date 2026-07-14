import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/credit_summary.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/off_visit_reason.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/capture_location_once.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_credit_summary.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/catalog_bloc.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/catalog_event.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/quotation/quotation_builder_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/credit_summary_card.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/off_visit_reason_sheet.dart';

class ShopOrderEntryScreen extends StatefulWidget {
  const ShopOrderEntryScreen(
      {super.key,
      required this.customer,
      this.skipOffVisitCheck = false,
      this.seedSearchTerm});

  static const routeName = 'order-shop-entry';

  final Customer customer;
  final bool skipOffVisitCheck;
  final String? seedSearchTerm;

  @override
  State<ShopOrderEntryScreen> createState() => _ShopOrderEntryScreenState();
}

class _ShopOrderEntryScreenState extends State<ShopOrderEntryScreen> {
  late Future<CreditSummary?> _summaryFuture;
  OffVisitReason? _reason;
  ({double lat, double lng})? _gps;
  bool _capturingGps = true;

  @override
  void initState() {
    super.initState();
    _summaryFuture =
        sl<GetCreditSummary>()(GetCreditSummaryParams(widget.customer.id)).then(
      (result) => result.when(success: (s) => s, failure: (_) => null),
    );
    _captureGps();
  }

  Future<void> _captureGps() async {
    final position = await sl<CaptureLocationOnce>()();
    if (!mounted) return;
    setState(() {
      _gps = position;
      _capturingGps = false;
    });
  }

  Future<void> _startQuotation() async {
    if (!widget.skipOffVisitCheck && _reason == null) {
      final picked = await showOffVisitReasonSheet(context: context);
      if (picked == null || !mounted) return;
      setState(() => _reason = picked);
    }
    if (!mounted) return;

    Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: QuotationBuilderScreen.routeName),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) {
            final bloc = sl<CatalogBloc>();
            if (widget.seedSearchTerm != null) {
              bloc.add(CatalogSearchChanged(widget.seedSearchTerm!));
            }
            return bloc;
          }),
          BlocProvider(create: (_) => sl<CartCubit>()..load()),
          BlocProvider(create: (_) => sl<SyncCubit>()),
        ],
        child: LocalizedBuilder(
          builder: (_) => QuotationBuilderScreen(
            customer: widget.customer,
            offVisitReason: widget.skipOffVisitCheck ? null : _reason,
            gpsLat: _gps?.lat,
            gpsLng: _gps?.lng,
          ),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) => LocalizedBuilder(builder: _build);

  Widget _build(BuildContext context) {
    final customer = widget.customer;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text(customer.shopName,
            style: TextStyle(
                color: colors.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        children: [
          Text(customer.address,
              style: TextStyle(color: colors.textPrimary, fontSize: 13)),
          Text('${customer.district}, ${customer.province}',
              style: TextStyle(color: colors.textSecondary, fontSize: 12)),
          const SizedBox(height: 14),
          FutureBuilder<CreditSummary?>(
            future: _summaryFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Center(
                    child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: colors.accentPurple)));
              }
              final summary = snapshot.data;
              if (summary == null) {
                return const SizedBox.shrink();
              }
              return CreditSummaryCard(
                  creditLimit: customer.creditLimit, summary: summary);
            },
          ),
          if (!widget.skipOffVisitCheck) ...[
            const SizedBox(height: 14),
            _OffVisitBanner(
                reason: _reason,
                onPick: () async {
                  final picked = await showOffVisitReasonSheet(
                      context: context, initial: _reason);
                  if (picked != null) setState(() => _reason = picked);
                }),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.gps_fixed_rounded, size: 15, color: colors.textSecondary),
              const SizedBox(width: 6),
              Text(
                _capturingGps
                    ? 'orders.shop.capture_gps'.tr
                    : _gps == null
                        ? 'orders.shop.capture_gps'.tr
                        : '${_gps!.lat.toStringAsFixed(5)}, ${_gps!.lng.toStringAsFixed(5)}',
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startQuotation,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('orders.shop.start_quotation'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('orders.shop.pick_another_shop'.tr),
            ),
          ),
        ],
      ),
    );
  }
}

class _OffVisitBanner extends StatelessWidget {
  const _OffVisitBanner({required this.reason, required this.onPick});
  final OffVisitReason? reason;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: colors.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('orders.shop.off_visit_warning'.tr,
                    style: TextStyle(
                        color: colors.warning,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.35)),
                if (reason != null) ...[
                  const SizedBox(height: 6),
                  Text(reason!.localizedLabel,
                      style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ],
              ],
            ),
          ),
          TextButton(
              onPressed: onPick,
              child: Text(reason == null
                  ? 'orders.shop.start_quotation'.tr
                  : 'orders.quotation.edit_quotation'.tr)),
        ],
      ),
    );
  }
}