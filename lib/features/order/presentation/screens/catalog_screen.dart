import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/category.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product_filter.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/barcode_scanner_service.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/fetch_categories.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_product_by_barcode.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart_state.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog_bloc.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog_event.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog_state.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/cart_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/product_detail_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog_filter_sheet.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog_search_bar.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/category_sidebar.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/product_card.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/sync_status_banner.dart';

/// The ERP-style product browser: search + category rail/drawer + filter/sort
/// + paginated grid + barcode scan. [leadId], when set, scopes any add-to-cart
/// action to that lead's opportunity (pushed from `LeadDetailScreen`'s
/// "Add Products" CTA); left null when opened from the Orders tab.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, this.leadId});
  final String? leadId;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _scrollController = ScrollController();
  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = sl<FetchCategories>()(const NoParams()).then(
      (result) => result.when(success: (c) => c, failure: (_) => const <Category>[]),
    );
    context.read<SyncCubit>().syncIfNeeded();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      context.read<CatalogBloc>().add(const CatalogLoadMoreRequested());
    }
  }

  Future<void> _scan() async {
    final code = await sl<BarcodeScannerService>().scan();
    if (code == null || !mounted) return;
    final result = await sl<GetProductByBarcode>()(BarcodeParams(code));
    if (!mounted) return;
    result.when(
      success: (product) => _openDetail(context, product.id),
      failure: (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
    );
  }

  /// `ProductDetailScreen`/`CartScreen` are pushed as new routes, so they
  /// don't automatically inherit [CartCubit] from this screen's ancestry —
  /// forward it explicitly via `BlocProvider.value`, the same pattern
  /// `LeadCard._openDetail` uses to carry `PipelineBloc` into `LeadDetailScreen`.
  void _openDetail(BuildContext context, String productId) {
    final cartCubit = context.read<CartCubit>();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: cartCubit,
        child: ProductDetailScreen(productId: productId, leadId: widget.leadId),
      ),
    ));
  }

  void _openCart(BuildContext context) {
    final cartCubit = context.read<CartCubit>();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(value: cartCubit, child: CartScreen(leadId: widget.leadId)),
    ));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vibe.bg,
     appBar: AppBar(
        backgroundColor: Vibe.bg,
        // 1. Increase width to fit two icons (default is 56)
        leadingWidth: 96, 
        // 2. Use a Row to place the Back Arrow to the left of the Menu Icon
        leading: Row(
          children: [
            // Back Arrow
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Back',
            ),
            // Menu Icon (Wrapped in a Builder to get the correct Scaffold context)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.inventory_2_rounded),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: 'Menu',
              ),
            ),
          ],
        ),
        title: const Text('Product Catalog', style: TextStyle(color: Vibe.text, fontSize: 17, fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: Vibe.text),
        actions: [
          BlocBuilder<CartCubit, CartState>(
            builder: (context, cartState) {
              final count = cartState is CartLoaded ? cartState.itemCount : 0;
              return Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: badges.Badge(
                  showBadge: count > 0,
                  badgeContent: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10)),
                  badgeStyle: const badges.BadgeStyle(badgeColor: Vibe.danger),
                  position: badges.BadgePosition.topEnd(top: -6, end: -6),
                  child: IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () => _openCart(context),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;
          return FutureBuilder<List<Category>>(
            future: _categoriesFuture,
            builder: (context, snapshot) {
              final categories = snapshot.data ?? const [];
              final content = _CatalogBody(
                scrollController: _scrollController,
                onScan: _scan,
                onOpenDetail: (id) => _openDetail(context, id),
              );

              if (!isWide) {
                return content;
              }
              return Row(
                children: [
                  SizedBox(
                    width: 220.w,
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(right: BorderSide(color: Vibe.stroke)),
                      ),
                      child: BlocBuilder<CatalogBloc, CatalogState>(
                        builder: (context, state) {
                          final selected = state is CatalogLoaded ? state.filter.categoryId : null;
                          return CategorySidebar(
                            categories: categories,
                            selectedCategoryId: selected,
                            onSelect: (id) => _selectCategory(context, id),
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(child: content),
                ],
              );
            },
          );
        },
      ),
      drawer: LayoutBuilder(
        builder: (context, constraints) => FutureBuilder<List<Category>>(
          future: _categoriesFuture,
          builder: (context, snapshot) => Drawer(
            child: SafeArea(
              child: BlocBuilder<CatalogBloc, CatalogState>(
                builder: (context, state) {
                  final selected = state is CatalogLoaded ? state.filter.categoryId : null;
                  return CategorySidebar(
                    categories: snapshot.data ?? const [],
                    selectedCategoryId: selected,
                    onSelect: (id) {
                      Navigator.of(context).pop();
                      _selectCategory(context, id);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectCategory(BuildContext context, String? categoryId) {
    final bloc = context.read<CatalogBloc>();
    final current = bloc.state;
    final filter = current is CatalogLoaded ? current.filter : const ProductFilter();
    bloc.add(CatalogFilterChanged(filter.copyWith(categoryId: () => categoryId)));
  }
}

class _CatalogBody extends StatelessWidget {
  const _CatalogBody({required this.scrollController, required this.onScan, required this.onOpenDetail});
  final ScrollController scrollController;
  final VoidCallback onScan;
  final ValueChanged<String> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogBloc, CatalogState>(
      builder: (context, state) {
        return switch (state) {
          CatalogLoaded() => _Loaded(
              state: state,
              scrollController: scrollController,
              onScan: onScan,
              onOpenDetail: onOpenDetail,
            ),
          CatalogError(:final message) => Center(
              child: Text(message, style: const TextStyle(color: Vibe.muted)),
            ),
          _ => const Center(child: CircularProgressIndicator(color: Vibe.violet)),
        };
      },
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.state,
    required this.scrollController,
    required this.onScan,
    required this.onOpenDetail,
  });
  final CatalogLoaded state;
  final ScrollController scrollController;
  final VoidCallback onScan;
  final ValueChanged<String> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Vibe.violet,
      backgroundColor: Vibe.bgSoft,
      onRefresh: () async {
        await context.read<SyncCubit>().refresh();
        if (context.mounted) context.read<CatalogBloc>().add(const CatalogRefreshRequested());
      },
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SyncStatusBanner(),
                  CatalogSearchBar(
                    onSearchChanged: (q) => context.read<CatalogBloc>().add(CatalogSearchChanged(q)),
                    onFilterTap: () => showCatalogFilterSheet(
                      context: context,
                      filter: state.filter,
                      brands: state.brands,
                      onApply: (f) => context.read<CatalogBloc>().add(CatalogFilterChanged(f)),
                    ),
                    hasActiveFilters: !state.filter.isEmpty,
                    onScanTap: onScan,
                  ),
                ],
              ),
            ),
          ),
          if (state.items.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No products found', style: TextStyle(color: Vibe.muted))),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.62,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = state.items[index];
                    return ProductCard(
                      product: product,
                      isFavorite: false,
                      onTap: () => onOpenDetail(product.id),
                      onFavoriteToggle: () {},
                      onAddToCart: () {
                        context.read<CartCubit>().addProduct(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${product.name} added to cart'), duration: const Duration(seconds: 1)),
                        );
                      },
                    );
                  },
                  childCount: state.items.length,
                ),
              ),
            ),
          if (state.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(color: Vibe.violet)),
              ),
            ),
        ],
      ),
    );
  }
}
