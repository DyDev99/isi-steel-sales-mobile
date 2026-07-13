import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_filter.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/browse_customers.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/customer_params.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/credit_summary.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_credit_summary.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/shop/shop_order_entry_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/order_skeletons.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/shop/shop_tile.dart';

class ShopListScreen extends StatefulWidget {
  const ShopListScreen({
    super.key,
    required this.territory,
    this.skipOffVisitCheck = false,
    this.seedSearchTerm,
  });

  static const routeName = 'order-shop-list';

  final String territory;
  final bool skipOffVisitCheck;
  final String? seedSearchTerm;

  @override
  State<ShopListScreen> createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
  late Future<List<Customer>> _shopsFuture;

  @override
  void initState() {
    super.initState();
    _shopsFuture = _loadShops();
  }

  Future<List<Customer>> _loadShops() async {
    final result = await sl<BrowseCustomers>()(
      BrowseCustomersParams(
          page: 0,
          pageSize: 500,
          filter: CustomerFilter(territory: widget.territory)),
    );
    return result.when(
        success: (paged) => paged.items, failure: (_) => const []);
  }

  void _openOrderEntry(Customer customer) {
    Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: ShopOrderEntryScreen.routeName),
      builder: (_) => ShopOrderEntryScreen(
        customer: customer,
        skipOffVisitCheck: widget.skipOffVisitCheck,
        seedSearchTerm: widget.seedSearchTerm,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text(widget.territory,
            style: TextStyle(
                color: colors.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: FutureBuilder<List<Customer>>(
        future: _shopsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                OrderTileSkeleton(),
                OrderTileSkeleton(),
                OrderTileSkeleton()
              ],
            );
          }
          final shops = snapshot.data!;
          if (shops.isEmpty) {
            return Center(
                child: Text('orders.catalog.no_products'.tr,
                    style: TextStyle(color: colors.textSecondary)));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              for (final shop in shops)
                _ShopTileWithCredit(
                    customer: shop, onTap: () => _openOrderEntry(shop))
            ],
          );
        },
      ),
    );
  }
}

class _ShopTileWithCredit extends StatefulWidget {
  const _ShopTileWithCredit({required this.customer, required this.onTap});
  final Customer customer;
  final VoidCallback onTap;

  @override
  State<_ShopTileWithCredit> createState() => _ShopTileWithCreditState();
}

class _ShopTileWithCreditState extends State<_ShopTileWithCredit> {
  late Future<CreditSummary?> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture =
        sl<GetCreditSummary>()(GetCreditSummaryParams(widget.customer.id)).then(
      (result) => result.when(success: (s) => s, failure: (_) => null),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CreditSummary?>(
      future: _summaryFuture,
      builder: (context, snapshot) => ShopTile(
          customer: widget.customer,
          onTap: widget.onTap,
          creditSummary: snapshot.data),
    );
  }
}