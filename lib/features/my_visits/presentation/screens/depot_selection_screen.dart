import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/depot_selection_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/depot_selection_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/depot_stock_count_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/order_skeletons.dart';

/// Depot/Shop selection — the first step of the Depot Stock quick action. Pick
/// a shop, then Continue to count its stock. Continue is disabled until a shop
/// is selected; the last selection is pre-highlighted (never forced).
class DepotSelectionScreen extends StatelessWidget {
  const DepotSelectionScreen({super.key});

  static const routeName = 'depot-selection';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DepotSelectionCubit>()..load(),
      child: const _DepotSelectionView(),
    );
  }
}

class _DepotSelectionView extends StatelessWidget {
  const _DepotSelectionView();

  void _continue(BuildContext context, String shopId) {
    Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: DepotStockCountScreen.routeName),
      builder: (_) => DepotStockCountScreen(shopId: shopId),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DepotSelectionCubit>();
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        title: Text('Select depot / shop',
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _SearchField(onChanged: cubit.search),
          ),
          Expanded(
            child: BlocBuilder<DepotSelectionCubit, DepotSelectionState>(
              builder: (context, state) {
                return switch (state.status) {
                  DepotSelectionStatus.initial ||
                  DepotSelectionStatus.loading =>
                    const _LoadingList(),
                  DepotSelectionStatus.error => _ErrorState(
                      message: state.message ?? 'Something went wrong.',
                      onRetry: cubit.load,
                    ),
                  DepotSelectionStatus.empty =>
                    _EmptyState(onRefresh: cubit.refresh),
                  DepotSelectionStatus.loaded => _ShopList(state: state),
                };
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          BlocSelector<DepotSelectionCubit, DepotSelectionState, String?>(
        selector: (state) => state.selectedId,
        builder: (context, selectedId) => _ContinueBar(
          enabled: selectedId != null,
          onContinue:
              selectedId == null ? null : () => _continue(context, selectedId),
        ),
      ),
    );
  }
}

class _ShopList extends StatelessWidget {
  const _ShopList({required this.state});
  final DepotSelectionState state;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: context.read<DepotSelectionCubit>().refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.shops.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final shop = state.shops[i];
          return _ShopTile(
            shop: shop,
            selected: shop.id == state.selectedId,
            onTap: () => context.read<DepotSelectionCubit>().select(shop.id),
          );
        },
      ),
    );
  }
}

class _ShopTile extends StatelessWidget {
  const _ShopTile({
    required this.shop,
    required this.selected,
    required this.onTap,
  });

  final Customer shop;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final subtitle = [shop.ownerName, shop.district, shop.territory]
        .where((s) => s.isNotEmpty)
        .join(' · ');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? colors.surfaceStrong : colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? scheme.primary : colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.storefront_rounded,
                  color: scheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shop.shopName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: colors.textSecondary, fontSize: 11.5)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? scheme.primary : colors.border,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: colors.textSecondary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: TextStyle(color: colors.textPrimary, fontSize: 13.5),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search depot or shop…',
                hintStyle:
                    TextStyle(color: colors.textSecondary, fontSize: 13.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        OrderTileSkeleton(),
        OrderTileSkeleton(),
        OrderTileSkeleton(),
        OrderTileSkeleton(),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storefront_outlined,
                    size: 44, color: colors.textSecondary),
                const SizedBox(height: 12),
                Text('No depots or shops found',
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Try a different search.',
                    style:
                        TextStyle(color: colors.textSecondary, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 44, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: colors.textPrimary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueBar extends StatelessWidget {
  const _ContinueBar({required this.enabled, required this.onContinue});
  final bool enabled;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              disabledBackgroundColor: scheme.primary.withValues(alpha: 0.4),
              disabledForegroundColor: scheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              enabled ? 'Continue' : 'Select a depot / shop',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}
