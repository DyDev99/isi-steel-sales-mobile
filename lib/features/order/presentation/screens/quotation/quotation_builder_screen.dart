import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/size_and_quality_section.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/discount_section.dart';

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
  int _selectedDiscount = 0;

  // Selected State Configuration for product attributes
  String _selectedSize = '0.40 mm';
  String _selectedQuality = 'Premium Zacs';
  String _selectedMeshSize = '100x100 mm';
  String _selectedLength = '2.4 m';

  @override
  void initState() {
    super.initState();
    _categoriesFuture = sl<FetchCategories>()(const NoParams()).then(
      (result) => result.when(success: (c) => c, failure: (_) => const <Category>[]),
    );

    context.read<SyncCubit>().syncIfNeeded();
    context.read<CatalogBloc>().add(const CatalogLoadRequested());
    _loadFavorites();

    if (widget.customer != null) {
      _summaryFuture = sl<GetCreditSummary>()(
        GetCreditSummaryParams(widget.customer!.id),
      ).then(
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
      failure: (_) {},
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

  void _selectDiscount(int percent) {
    setState(() => _selectedDiscount = percent);
  }


  Future<void> _voiceSearch() async {
    final query = await sl<VoiceSearchService>().listen();
    if (query == null || query.trim().isEmpty || !mounted) return;
    setState(() {
      _searchController.text = query;
    });
    context.read<CatalogBloc>().add(CatalogVoiceSearchRequested(query));
  }

  Future<void> _imageSearch() async {
    final query = await sl<ImageSearchService>().matchQuery(ImageSearchSource.gallery);
    if (query == null || query.isEmpty || !mounted) return;
    setState(() {
      _searchController.text = query;
    });
    context.read<CatalogBloc>().add(CatalogImageSearchRequested(query));
  }

  Future<void> _saveQuotation() async {
    final quotation = await context.read<CartCubit>().saveQuotation(
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save quotation')));
      return;
    }

    Navigator.of(context).pushReplacement(MaterialPageRoute(
      settings: const RouteSettings(name: QuotationDetailScreen.routeName),
      builder: (_) => QuotationDetailScreen(quotation: quotation),
    ));
  }

  void _selectCategory(String? categoryId) {
    final bloc = context.read<CatalogBloc>();
    final filter = bloc.state is CatalogLoaded ? (bloc.state as CatalogLoaded).filter : const ProductFilter();
    bloc.add(CatalogFilterChanged(filter.copyWith(categoryId: () => categoryId)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: const BackButton(color: Color(0xFF0F2C7F)),
        title: Text(
          widget.customer?.shopName ?? widget.leadDisplayName ?? 'orders.quotation.builder_title'.tr,
          style: const TextStyle(
            color: Color(0xFF0F2C7F), 
            fontSize: 17, 
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Category>>(
              future: _categoriesFuture,
              builder: (_, categorySnapshot) {
                final categories = categorySnapshot.data ?? const <Category>[];

                return BlocBuilder<CatalogBloc, CatalogState>(
                  builder: (context, catalogState) {
                    final filter = catalogState is CatalogLoaded ? catalogState.filter : const ProductFilter();
                    final brands = catalogState is CatalogLoaded ? catalogState.brands : const <String>[];
                    final isSearchingOrFiltered = _searchController.text.isNotEmpty || filter.categoryId != null;

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      children: [
                        const SyncStatusBanner(),
                        if (widget.customer != null && _summaryFuture != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: FutureBuilder<CreditSummary?>(
                              future: _summaryFuture,
                              builder: (_, snapshot) => snapshot.data == null
                                  ? const SizedBox.shrink()
                                  : CreditSummaryCard(
                                      creditLimit: widget.customer!.creditLimit,
                                      summary: snapshot.data!,
                                    ),
                            ),
                          ),
                        CatalogSearchBar(
                          controller: _searchController,
                          onSearchChanged: (q) {
                            setState(() {}); 
                            context.read<CatalogBloc>().add(CatalogSearchChanged(q));
                          },
                          onFilterTap: () => showCatalogFilterSheet(
                            context: context,
                            filter: filter,
                            brands: brands,
                            onApply: (f) => context.read<CatalogBloc>().add(CatalogFilterChanged(f)),
                          ),
                          hasActiveFilters: !filter.isEmpty,
                          onVoiceTap: _voiceSearch,
                          onImageTap: _imageSearch,
                        ),
                        const SizedBox(height: 16),
                        
                        CategoryQuickFilterRow(
                          categories: categories,
                          selectedCategoryId: filter.categoryId,
                          onSelect: (id) {
                            _selectCategory(id);
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 16),

                        if (isSearchingOrFiltered) ...[
                          SizeAndQualityContainerRow(
                            selectedSize: _selectedSize,
                            selectedQuality: _selectedQuality,
                            selectedMeshSize: _selectedMeshSize,
                            selectedLength: _selectedLength,
                            onSizeChanged: (val) => setState(() => _selectedSize = val),
                            onQualityChanged: (val) => setState(() => _selectedQuality = val),
                            onMeshSizeChanged: (val) => setState(() => _selectedMeshSize = val),
                            onLengthChanged: (val) => setState(() => _selectedLength = val),
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
                            height: 220.h,
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (_expandedProductId != null) ...[
                          ProductDetailInlineSection(
                            productId: _expandedProductId!,
                            leadId: widget.leadId,
                            onClose: () => _toggleExpanded(_expandedProductId!),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Clean grid alignments (Removed the horizontal padding wrapper bug)
                        DiscountSection(
                          selectedDiscount: _selectedDiscount,
                          onDiscountSelected: _selectDiscount,
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
          QuotationBottomBar(onSave: _saveQuotation, discount: _selectedDiscount),
        ],
      ),
    );
  }
}



class _QuotationSummarySection extends StatelessWidget {
  const _QuotationSummarySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quotation Notes', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B), fontFamily: 'Roboto'),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Text('Add quotation or notes...', style: TextStyle(color: Colors.black38, fontSize: 13)),
        ),
      ],
    );
  }
}

class _ProductListSection extends StatelessWidget {
  const _ProductListSection({
    required this.state,
    required this.favoriteIds,
    required this.expandedProductId,
    required this.leadId,
    required this.customerId,
    required this.onToggleFavorite,
    required this.onToggleExpanded,
    this.height,
  });

  final CatalogState state;
  final Set<String> favoriteIds;
  final String? expandedProductId;
  final String? leadId;
  final String? customerId;
  final ValueChanged<String> onToggleFavorite;
  final ValueChanged<String> onToggleExpanded;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      CatalogIdle() || CatalogLoading() => const CatalogGridSkeleton(),
      CatalogError(:final message) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text(message, style: const TextStyle(color: Vibe.muted))),
        ),
      CatalogLoaded(:final items, :final hasMore, :final isLoadingMore) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Products', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B), fontFamily: 'Roboto'),
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
                                child: Text('orders.catalog.no_products'.tr, style: const TextStyle(color: Vibe.muted)),
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
                                      child: CircularProgressIndicator(color: Color(0xFF0F2C7F)),
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