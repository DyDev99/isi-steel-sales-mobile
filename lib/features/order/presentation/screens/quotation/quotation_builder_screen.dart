import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/category.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/credit_summary.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/off_visit_reason.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product_filter.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/barcode_scanner_service.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/image_search_service.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/voice_search_service.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/fetch_categories.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/fetch_favorites.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_credit_summary.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_product_by_barcode.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/toggle_favorite.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/catalog_bloc.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/catalog_event.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/catalog_state.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/quotation/quotation_detail_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/catalog_filter_sheet.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/catalog_search_bar.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/catalog_skeletons.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/product_card.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/product_detail_inline_section.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/sync_status_banner.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/categories/category_quick_filter_row.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/cart_preview_section.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/credit_summary_card.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/quotation_bottom_bar.dart';

/// Product search/browse + cart-building screen — the core of the order
/// flow. Composes already-built, previously-orphaned pieces (product grid,
/// category quick filter, inline product detail, cart preview, fixed
/// totals/save footer) instead of duplicating their markup here.
class QuotationBuilderScreen extends StatefulWidget {
  const QuotationBuilderScreen({
    super.key,
    this.customer,
    this.leadId,
    this.leadDisplayName,
    this.offVisitReason,
    this.gpsLat,
    this.gpsLng,
    this.editingQuotation,
  });

  static const routeName = 'order-quotation-builder';

  final Customer? customer;
  final String? leadId;
  final String? leadDisplayName;
  final OffVisitReason? offVisitReason;
  final double? gpsLat;
  final double? gpsLng;
  final Quotation? editingQuotation;

  @override
  State<QuotationBuilderScreen> createState() => _QuotationBuilderScreenState();
}

class _QuotationBuilderScreenState extends State<QuotationBuilderScreen> {
  final _searchController = TextEditingController();
  late Future<List<Category>> _categoriesFuture;
  Future<CreditSummary?>? _summaryFuture;

  Set<String> _favoriteIds = {};
  String? _expandedProductId;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = sl<FetchCategories>()(const NoParams()).then(
      (result) => result.when(success: (c) => c, failure: (_) => const <Category>[]),
    );
    context.read<SyncCubit>().syncIfNeeded();
    context.read<CatalogBloc>().add(const CatalogLoadRequested());
    _loadFavorites();

    final customer = widget.customer;
    if (customer != null) {
      _summaryFuture = sl<GetCreditSummary>()(GetCreditSummaryParams(customer.id)).then(
        (result) => result.when(success: (s) => s, failure: (_) => null),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final result = await sl<FetchFavorites>()(const NoParams());
    if (!mounted) return;
    result.when(
      success: (products) => setState(() => _favoriteIds = products.map((p) => p.id).toSet()),
      failure: (_) => null,
    );
  }

  Future<void> _toggleFavorite(String productId) async {
    setState(() {
      if (!_favoriteIds.add(productId)) _favoriteIds.remove(productId);
    });
    await sl<ToggleFavorite>()(ProductIdParams(productId));
  }

  void _toggleExpanded(String productId) {
    setState(() => _expandedProductId = _expandedProductId == productId ? null : productId);
  }

  // --- Search & Scan Integrations ---
  Future<void> _scan() async {
    final code = await sl<BarcodeScannerService>().scan();
    if (code == null || !mounted) return;
    final result = await sl<GetProductByBarcode>()(BarcodeParams(code));
    if (!mounted) return;
    result.when(
      success: (product) => context.read<CartCubit>().addProduct(product, leadId: widget.leadId, customerId: widget.customer?.id),
      failure: (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))),
    );
  }

  Future<void> _voiceSearch() async {
    final query = await sl<VoiceSearchService>().listen();
    if (query == null || query.trim().isEmpty || !mounted) return;
    _searchController.text = query;
    context.read<CatalogBloc>().add(CatalogVoiceSearchRequested(query));
  }

  Future<void> _imageSearch() async {
    // Simplified for UI integration - assumes gallery source for brevity in layout focus
    final query = await sl<ImageSearchService>().matchQuery(ImageSearchSource.gallery);
    if (query == null || query.isEmpty || !mounted) return;
    _searchController.text = query;
    context.read<CatalogBloc>().add(CatalogImageSearchRequested(query));
  }

  Future<void> _saveQuotation() async {
    final cubit = context.read<CartCubit>();
    final quotation = await cubit.saveQuotation(
      customerId: widget.customer?.id,
      shopName: widget.customer?.shopName,
      leadId: widget.leadId,
      leadDisplayName: widget.leadDisplayName,
      offVisitReason: widget.offVisitReason,
      gpsLat: widget.gpsLat,
      gpsLng: widget.gpsLng,
      editing: widget.editingQuotation,
    );
    if (!mounted) return;
    if (quotation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('orders.quotation.builder_title'.tr)),
      );
      return;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      settings: const RouteSettings(name: QuotationDetailScreen.routeName),
      builder: (_) => QuotationDetailScreen(quotation: quotation),
    ));
  }

  void _selectCategory(String? categoryId) {
    final bloc = context.read<CatalogBloc>();
    final current = bloc.state;
    final filter = current is CatalogLoaded ? current.filter : const ProductFilter();
    bloc.add(CatalogFilterChanged(filter.copyWith(categoryId: () => categoryId)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vibe.bg,
      appBar: AppBar(
        backgroundColor: Vibe.bg,
        iconTheme: const IconThemeData(color: Vibe.text),
        title: Text(
          widget.customer?.shopName ?? widget.leadDisplayName ?? 'orders.quotation.builder_title'.tr,
          style: const TextStyle(color: Vibe.text, fontSize: 17, fontWeight: FontWeight.w800),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Category>>(
              future: _categoriesFuture,
              builder: (context, categorySnapshot) {
                final categories = categorySnapshot.data ?? const <Category>[];
                return BlocBuilder<CatalogBloc, CatalogState>(
                  builder: (context, catalogState) {
                    final filter = catalogState is CatalogLoaded ? catalogState.filter : const ProductFilter();
                    final brands = catalogState is CatalogLoaded ? catalogState.brands : const <String>[];

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      children: [
                        const SyncStatusBanner(),
                        if (widget.customer != null && _summaryFuture != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: FutureBuilder<CreditSummary?>(
                              future: _summaryFuture,
                              builder: (context, snapshot) => snapshot.data == null
                                  ? const SizedBox.shrink()
                                  : CreditSummaryCard(creditLimit: widget.customer!.creditLimit, summary: snapshot.data!),
                            ),
                          ),
                        CatalogSearchBar(
                          controller: _searchController,
                          onSearchChanged: (q) => context.read<CatalogBloc>().add(CatalogSearchChanged(q)),
                          onFilterTap: () => showCatalogFilterSheet(
                            context: context,
                            filter: filter,
                            brands: brands,
                            onApply: (f) => context.read<CatalogBloc>().add(CatalogFilterChanged(f)),
                          ),
                          hasActiveFilters: !filter.isEmpty,
                          onScanTap: _scan,
                          onVoiceTap: _voiceSearch,
                          onImageTap: _imageSearch,
                        ),
                        const SizedBox(height: 12),
                        CategoryQuickFilterRow(
                          categories: categories,
                          selectedCategoryId: filter.categoryId,
                          onSelect: _selectCategory,
                        ),
                        const SizedBox(height: 16),
                        _ProductListSection(
                          state: catalogState,
                          favoriteIds: _favoriteIds,
                          expandedProductId: _expandedProductId,
                          leadId: widget.leadId,
                          customerId: widget.customer?.id,
                          onToggleFavorite: _toggleFavorite,
                          onToggleExpanded: _toggleExpanded,
                        ),
                        const SizedBox(height: 16),
                        const CartPreviewSection(),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          QuotationBottomBar(onSave: _saveQuotation),
        ],
      ),
    );
  }
}

/// Renders the catalog grid for every [CatalogState] — loading skeleton,
/// error, empty, or the loaded list with an inline detail section under
/// whichever card is currently expanded, plus a "load more" tail for
/// pagination.
class _ProductListSection extends StatelessWidget {
  const _ProductListSection({
    required this.state,
    required this.favoriteIds,
    required this.expandedProductId,
    required this.leadId,
    required this.customerId,
    required this.onToggleFavorite,
    required this.onToggleExpanded,
  });

  final CatalogState state;
  final Set<String> favoriteIds;
  final String? expandedProductId;
  final String? leadId;
  final String? customerId;
  final ValueChanged<String> onToggleFavorite;
  final ValueChanged<String> onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      CatalogIdle() || CatalogLoading() => const CatalogGridSkeleton(),
      CatalogError(:final message) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text(message, style: const TextStyle(color: Vibe.muted))),
        ),
      CatalogLoaded(:final items, :final hasMore, :final isLoadingMore) => SizedBox(
          height: 180.h, // 40% of screen height (requires flutter_screenutil)
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(), // smooth iOS-style scrolling
            child: Column(
              children: [
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                        child: Text('orders.catalog.no_products'.tr,
                            style: const TextStyle(color: Vibe.muted))),
                  )
                else
                  for (final product in items) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ProductCard(
                        product: product,
                        isFavorite: favoriteIds.contains(product.id),
                        onFavoriteToggle: () => onToggleFavorite(product.id),
                        onTap: () => onToggleExpanded(product.id),
                        onAddToCart: () => context
                            .read<CartCubit>()
                            .addProduct(product, leadId: leadId, customerId: customerId),
                      ),
                    ),
                    if (expandedProductId == product.id)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ProductDetailInlineSection(
                          productId: product.id,
                          leadId: leadId,
                          onClose: () => onToggleExpanded(product.id),
                        ),
                      ),
                  ],
                if (hasMore)
                  Center(
                    child: isLoadingMore
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(color: Vibe.violet))
                        : TextButton(
                            onPressed: () => context
                                .read<CatalogBloc>()
                                .add(const CatalogLoadMoreRequested()),
                            child: Text('orders.catalog.load_more'.tr),
                          ),
                  ),
                // Extra padding at the bottom for comfortable scrolling
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
    };
  }
}