import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/browse_customers.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/customer_params.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/shop/shop_list_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/order_skeletons.dart';

/// First step of the order flow — pick a territory, grouping the same
/// `BrowseCustomers` data the Customers feature already browses. No new
/// query logic: territory+status filtering is already fully supported
/// end-to-end by `CustomerFilter`.
class TerritoryScreen extends StatefulWidget {
  const TerritoryScreen({super.key});

  static const routeName = 'order-territory';

  @override
  State<TerritoryScreen> createState() => _TerritoryScreenState();
}

class _TerritoryScreenState extends State<TerritoryScreen> {
  late Future<Map<String, int>> _territoriesFuture;

  @override
  void initState() {
    super.initState();
    _territoriesFuture = _loadTerritories();
  }

  Future<Map<String, int>> _loadTerritories() async {
    // The customer directory only syncs when its own tab is opened
    // (`CustomerSyncCubit.syncIfNeeded`) — trigger it here too, so entering
    // the order flow before ever visiting the Customers tab still works.
    await sl<CustomerSyncCubit>().syncIfNeeded();
    final result = await sl<BrowseCustomers>()(
        const BrowseCustomersParams(page: 0, pageSize: 5000));
    return result.when(
      success: (paged) {
        final counts = <String, int>{};
        for (final Customer c in paged.items) {
          counts[c.territory] = (counts[c.territory] ?? 0) + 1;
        }
        return counts;
      },
      failure: (_) => const {},
    );
  }

  void _openShopList(String territory) {
    Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: ShopListScreen.routeName),
      builder: (_) => ShopListScreen(territory: territory),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vibe.bg,
      appBar: AppBar(
        backgroundColor: Vibe.bg,
        iconTheme: const IconThemeData(color: Vibe.text),
        title: Text('orders.territory.title'.tr,
            style: const TextStyle(
                color: Vibe.text, fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _territoriesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const _TerritorySkeleton();
          }
          final territories = snapshot.data!.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));
          if (territories.isEmpty) {
            return Center(
                child: Text('orders.territory.pick_territory'.tr,
                    style: const TextStyle(color: Vibe.muted)));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              for (final entry in territories)
                _TerritoryTile(
                    name: entry.key,
                    shopCount: entry.value,
                    onTap: () => _openShopList(entry.key)),
            ],
          );
        },
      ),
    );
  }
}

class _TerritoryTile extends StatelessWidget {
  const _TerritoryTile(
      {required this.name, required this.shopCount, required this.onTap});
  final String name;
  final int shopCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Vibe.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Vibe.stroke)),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: Vibe.primaryLight,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.map_rounded, color: Vibe.violet),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: Vibe.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                          'orders.territory.shop_count'
                              .tr
                              .replaceAll('{count}', '$shopCount'),
                          style:
                              const TextStyle(color: Vibe.muted, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Vibe.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TerritorySkeleton extends StatelessWidget {
  const _TerritorySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        OrderTileSkeleton(),
        OrderTileSkeleton(),
        OrderTileSkeleton(),
        OrderTileSkeleton()
      ],
    );
  }
}
