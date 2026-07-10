import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/catalog_bloc.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/catalog_event.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/catalog_state.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/catalog_skeletons.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/product_card.dart';

class ProductListSection extends StatelessWidget {
  const ProductListSection({
    super.key,
    required this.state,
    required this.favoriteIds,
    required this.expandedProductId,
    required this.leadId,
    required this.customerId,
    required this.onToggleFavorite,
    required this.onToggleExpanded,
    this.height,
    this.hasActiveAttributeFilter = false,
    this.quantity = 1,
    this.unit,
  });

  final CatalogState state;
  final Set<String> favoriteIds;
  final String? expandedProductId;
  final String? leadId;
  final String? customerId;
  final ValueChanged<String> onToggleFavorite;
  final ValueChanged<String> onToggleExpanded;
  final double? height;
  final bool hasActiveAttributeFilter;

  /// Default quantity applied by the product card's quick-add button.
  final double quantity;

  /// Default sales unit applied by quick-add; falls back to each product's own
  /// unit when null (preserves the original behaviour for callers that don't
  /// expose a unit selector).
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      CatalogIdle() || CatalogLoading() => const CatalogGridSkeleton(),
      CatalogError(:final message) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
              child: Text(message, style: const TextStyle(color: Vibe.muted))),
        ),
      CatalogLoaded(:final items, :final hasMore, :final isLoadingMore) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Products',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E293B)),
                ),
                if (hasActiveAttributeFilter) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2C7F).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${items.length} match${items.length == 1 ? '' : 'es'}',
                      style: const TextStyle(
                          color: Color(0xFF0F2C7F),
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: height ?? 200.h,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          if (items.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Text(
                                  hasActiveAttributeFilter
                                      ? 'No products match this size/length/mesh size/quality combination'
                                      : 'orders.catalog.no_products'.tr,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Vibe.muted),
                                ),
                              ),
                            )
                          else
                            ...items.map((product) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: ProductCard(
                                    product: product,
                                    isFavorite:
                                        favoriteIds.contains(product.id),
                                    onFavoriteToggle: () =>
                                        onToggleFavorite(product.id),
                                    onTap: () => onToggleExpanded(product.id),
                                    onAddToCart: () =>
                                        context.read<CartCubit>().addProduct(
                                              product,
                                              quantity: quantity,
                                              unit: unit,
                                              leadId: leadId,
                                              customerId: customerId,
                                            ),
                                  ),
                                )),
                          if (hasMore)
                            Center(
                              child: isLoadingMore
                                  ? const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(
                                          color: Color(0xFF0F2C7F)),
                                    )
                                  : TextButton(
                                      onPressed: () => context
                                          .read<CatalogBloc>()
                                          .add(
                                              const CatalogLoadMoreRequested()),
                                      child:
                                          Text('orders.catalog.load_more'.tr),
                                    ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    };
  }
}
