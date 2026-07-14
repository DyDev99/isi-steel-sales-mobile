import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
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
  final double quantity;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return switch (state) {
      CatalogIdle() || CatalogLoading() => const CatalogGridSkeleton(),
      CatalogError(:final message) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text(message, style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.6)))),
        ),
      CatalogLoaded(:final items, :final hasMore, :final isLoadingMore) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Products',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: scheme.onSurface),
                ),
                if (hasActiveAttributeFilter) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${items.length} match${items.length == 1 ? '' : 'es'}',
                      style: TextStyle(color: scheme.primary, fontSize: 11, fontWeight: FontWeight.w700),
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
                                  style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.5)),
                                ),
                              ),
                            )
                          else
                            ...items.map((product) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: ProductCard(
                                    product: product,
                                    isFavorite: favoriteIds.contains(product.id),
                                    onFavoriteToggle: () => onToggleFavorite(product.id),
                                    onTap: () => onToggleExpanded(product.id),
                                    onAddToCart: () => context.read<CartCubit>().addProduct(
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
                                  ? Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: CircularProgressIndicator(color: scheme.primary),
                                    )
                                  : TextButton(
                                      onPressed: () => context.read<CatalogBloc>().add(const CatalogLoadMoreRequested()),
                                      child: Text('orders.catalog.load_more'.tr),
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