import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/depot_stock_count_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/depot_stock_count_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/stock_level_selector.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/order_skeletons.dart';

/// Depot stock-status screen. Receives only the [shopId] (per the routing
/// convention — no large objects), then loads the shop + inventory through
/// [DepotStockCountCubit]. Each SKU takes exactly one Low / Medium / High
/// status; finishing persists every selection offline-first (Drift +
/// pending sync). A missing/invalid id renders an error state rather than
/// crashing.
class DepotStockCountScreen extends StatelessWidget {
  const DepotStockCountScreen({super.key, required this.shopId});

  static const routeName = 'depot-stock-count';

  final String? shopId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DepotStockCountCubit>()..load(shopId),
      child: _DepotStockCountView(shopId: shopId),
    );
  }
}

class _DepotStockCountView extends StatelessWidget {
  const _DepotStockCountView({required this.shopId});

  final String? shopId;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text('my_visits.depot.stock_title'.tr,
            style: TextStyle(
                color: colors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800)),
      ),
      body: BlocConsumer<DepotStockCountCubit, DepotStockCountState>(
        listenWhen: (a, b) => a.status != b.status || a.message != b.message,
        listener: (context, state) {
          if (state.status == DepotStockCountStatus.saved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(
                  'my_visits.depot.recorded'.trParams({
                    'count': state.lines.length,
                    'shop':
                        state.shopName != null ? ' · ${state.shopName}' : '',
                  }),
                ),
              ),
            );
            Navigator.of(context).popUntil((r) => r.isFirst);
          } else if (state.status == DepotStockCountStatus.loaded &&
              state.message != null) {
            // A submit that failed to persist locally — surface, keep edits.
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          return switch (state.status) {
            DepotStockCountStatus.initial ||
            DepotStockCountStatus.loading =>
              const _LoadingList(),
            DepotStockCountStatus.syncing =>
              _LoadingList(caption: 'my_visits.depot.syncing_catalog'.tr),
            DepotStockCountStatus.error => _ErrorState(
                message: state.message ?? 'common.something_went_wrong'.tr,
                onRetry: () =>
                    context.read<DepotStockCountCubit>().load(shopId),
              ),
            DepotStockCountStatus.empty => _EmptyState(
                message: state.message,
                onRetry: () =>
                    context.read<DepotStockCountCubit>().load(shopId),
              ),
            DepotStockCountStatus.loaded ||
            DepotStockCountStatus.saving ||
            DepotStockCountStatus.saved =>
              _LoadedList(state: state),
          };
        },
      ),
      bottomNavigationBar:
          BlocBuilder<DepotStockCountCubit, DepotStockCountState>(
        buildWhen: (a, b) => a.status != b.status || a.setCount != b.setCount,
        builder: (context, state) {
          final visible = state.status == DepotStockCountStatus.loaded ||
              state.status == DepotStockCountStatus.saving;
          if (!visible) return const SizedBox.shrink();
          return _DoneBar(
            setCount: state.setCount,
            totalCount: state.lines.length,
            saving: state.status == DepotStockCountStatus.saving,
            onDone: () {
              final id = shopId;
              if (id != null) {
                context.read<DepotStockCountCubit>().submit(id);
              }
            },
          );
        },
      ),
    );
  }
}

class _LoadedList extends StatelessWidget {
  const _LoadedList({required this.state});
  final DepotStockCountState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        if (state.shopName != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(state.shopName!,
                style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900)),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text('my_visits.depot.count_hint'.tr,
              style: TextStyle(color: colors.textSecondary, fontSize: 12.5)),
        ),
        for (final line in state.lines)
          StockLevelRow(
            key: ValueKey(line.productId),
            name: line.name,
            subtitle: line.subtitle,
            imageUrl: line.imageUrl,
            size: line.size,
            level: line.level,
            showMissingHighlight: state.showValidation,
            onLevelSelected: (level) => context
                .read<DepotStockCountCubit>()
                .selectStockLevel(line.productId, level),
          ),
      ],
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList({this.caption});

  /// Optional line shown above the skeletons (e.g. "Downloading catalog…"
  /// while a first-open sync fills an empty local catalog).
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        if (caption != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(caption!,
                      style: TextStyle(
                          color: colors.textSecondary, fontSize: 12.5)),
                ),
              ],
            ),
          ),
        const OrderTileSkeleton(),
        const OrderTileSkeleton(),
        const OrderTileSkeleton(),
        const OrderTileSkeleton(),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.message, required this.onRetry});

  /// Optional actionable reason (e.g. offline → "connect to download").
  /// Null means a genuinely empty catalog after a successful pull.
  final String? message;
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
            Icon(Icons.inventory_2_outlined,
                size: 44, color: colors.textSecondary),
            const SizedBox(height: 12),
            Text('my_visits.depot.no_inventory'.tr,
                style: TextStyle(
                    color: colors.textPrimary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(message ?? 'my_visits.depot.no_products'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 12.5)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('common.retry'.tr),
            ),
          ],
        ),
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
              label: Text('common.retry'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoneBar extends StatelessWidget {
  const _DoneBar({
    required this.setCount,
    required this.totalCount,
    required this.saving,
    required this.onDone,
  });

  final int setCount;
  final int totalCount;
  final bool saving;
  final VoidCallback onDone;

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
        child: Row(
          children: [
            Expanded(
              child: Text(
                'my_visits.depot.set_progress'
                    .trParams({'done': setCount, 'total': totalCount}),
                style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ),
            ElevatedButton.icon(
              onPressed: saving ? null : onDone,
              icon: saving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: scheme.onPrimary))
                  : const Icon(Icons.check_rounded, size: 20),
              label: Text('common.done'.tr,
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
