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
import 'package:isi_steel_sales_mobile/features/order/domain/services/image_search_service.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/voice_search_service.dart';
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

/// The ERP-style product browser: multi-modal search (text/voice/scan/photo) +
/// category rail/drawer + filter/sort + paginated grid. [leadId], when set,
/// scopes any add-to-cart action to that lead's opportunity (pushed from
/// `LeadDetailScreen`'s "Add Products" CTA); left null when opened from the
/// Orders tab.
///
/// Entry is **lazy**: the [CatalogBloc] starts idle and fetches nothing until
/// the user runs an explicit query or picks a category — so opening this screen
/// never blocks on a network round-trip.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, this.leadId});
  final String? leadId;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
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

  /// Barcode scan → look up the exact SKU and open it straight away.
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

  /// Voice → on-device transcription → (vector) catalog search.
  Future<void> _voiceSearch() async {
    final query = await sl<VoiceSearchService>().listen();
    if (query == null || query.trim().isEmpty || !mounted) return;
    _searchController.text = query;
    context.read<CatalogBloc>().add(CatalogVoiceSearchRequested(query));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Voice search: "$query"'), duration: const Duration(seconds: 1)),
    );
  }

  /// Photo (camera or gallery) → visual match → catalog search.
  Future<void> _imageSearch() async {
    final source = await _pickImageSource();
    if (source == null || !mounted) return;
    final query = await sl<ImageSearchService>().matchQuery(source);
    if (query == null || query.isEmpty || !mounted) return;
    _searchController.text = query;
    context.read<CatalogBloc>().add(CatalogImageSearchRequested(query));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Matched by photo: $query'), duration: const Duration(seconds: 1)),
    );
  }

  Future<ImageSearchSource?> _pickImageSource() {
    return showModalBottomSheet<ImageSearchSource>(
      context: context,
      backgroundColor: Vibe.bgSoft,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Vibe.stroke, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Search by photo', style: TextStyle(color: Vibe.text, fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded, color: Vibe.violet),
              title: const Text('Take a photo', style: TextStyle(color: Vibe.text)),
              onTap: () => Navigator.pop(ctx, ImageSearchSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Vibe.violet),
              title: const Text('Upload from gallery', style: TextStyle(color: Vibe.text)),
              onTap: () => Navigator.pop(ctx, ImageSearchSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vibe.bg,
      appBar: AppBar(
        backgroundColor: Vibe.bg,
        // Widen the leading slot to fit both the back arrow and the menu icon.
        leadingWidth: 96,
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Back',
            ),
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
                searchController: _searchController,
                onScan: _scan,
                onVoice: _voiceSearch,
                onImage: _imageSearch,
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
  const _CatalogBody({
    required this.scrollController,
    required this.searchController,
    required this.onScan,
    required this.onVoice,
    required this.onImage,
    required this.onOpenDetail,
  });
  final ScrollController scrollController;
  final TextEditingController searchController;
  final VoidCallback onScan;
  final VoidCallback onVoice;
  final VoidCallback onImage;
  final ValueChanged<String> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogBloc, CatalogState>(
      builder: (context, state) {
        final loaded = state is CatalogLoaded ? state : null;
        return Column(
          children: [
            // Persistent search header — visible in idle so the user can start
            // a query, and stays fixed above the grid once results load.
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SyncStatusBanner(),
                  CatalogSearchBar(
                    controller: searchController,
                    onSearchChanged: (q) => context.read<CatalogBloc>().add(CatalogSearchChanged(q)),
                    onFilterTap: () => showCatalogFilterSheet(
                      context: context,
                      filter: loaded?.filter ?? const ProductFilter(),
                      brands: loaded?.brands ?? const [],
                      onApply: (f) => context.read<CatalogBloc>().add(CatalogFilterChanged(f)),
                    ),
                    hasActiveFilters: loaded != null && !loaded.filter.isEmpty,
                    onScanTap: onScan,
                    onVoiceTap: onVoice,
                    onImageTap: onImage,
                  ),
                ],
              ),
            ),
            Expanded(
              child: switch (state) {
                CatalogIdle() => const _IdleHint(),
                CatalogLoading() => const Center(child: CircularProgressIndicator(color: Vibe.violet)),
                CatalogError(:final message) => Center(child: Text(message, style: const TextStyle(color: Vibe.muted))),
                CatalogLoaded() => _Loaded(
                    state: state,
                    scrollController: scrollController,
                    onOpenDetail: onOpenDetail,
                  ),
              },
            ),
          ],
        );
      },
    );
  }
}

/// Deferred-fetch landing view: nothing has been requested yet.
class _IdleHint extends StatelessWidget {
  const _IdleHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.travel_explore_rounded, color: Vibe.muted, size: 44),
            const SizedBox(height: 14),
            Text(
              'Search via text, speak 🎤, scan 📷 or upload a photo to find items.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Vibe.muted, fontSize: 13.5, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.state,
    required this.scrollController,
    required this.onOpenDetail,
  });
  final CatalogLoaded state;
  final ScrollController scrollController;
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
          if (state.items.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No products found', style: TextStyle(color: Vibe.muted))),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
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
