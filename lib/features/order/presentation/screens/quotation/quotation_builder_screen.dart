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
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_credit_summary.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_product_by_barcode.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/catalog_bloc.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/catalog_event.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/catalog_state.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/quotation/quotation_detail_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/catalog_filter_sheet.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/catalog_search_bar.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/category_sidebar.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/catalog_skeletons.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/product_card.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/product_detail_inline_section.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/sync_status_banner.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/cart_preview_section.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/credit_summary_card.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/quotation_bottom_bar.dart';

/// Merges the old separate Catalog and Cart screens into one: browse/search
/// on top, cart shown inline as a section below the product grid (no
/// modal sheet, no standalone Cart route), with Save pinned in a fixed
/// bottom bar. Either shop-scoped ([customer] set) or lead-scoped
/// ([leadId] set), or [editingQuotation] to re-open a saved quotation for
/// editing.
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
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  late Future<List<Category>> _categoriesFuture;
  Future<CreditSummary?>? _summaryFuture;
  String? _selectedProductId;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = sl<FetchCategories>()(const NoParams()).then(
      (result) => result.when(success: (c) => c, failure: (_) => const <Category>[]),
    );
    context.read<SyncCubit>().syncIfNeeded();
    _scrollController.addListener(_onScroll);
    final customer = widget.customer;
    if (customer != null) {
      _summaryFuture = sl<GetCreditSummary>()(GetCreditSummaryParams(customer.id)).then(
        (result) => result.when(success: (s) => s, failure: (_) => null),
      );
    }
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

  Future<void> _voiceSearch() async {
    final query = await sl<VoiceSearchService>().listen();
    if (query == null || query.trim().isEmpty || !mounted) return;
    _searchController.text = query;
    context.read<CatalogBloc>().add(CatalogVoiceSearchRequested(query));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('orders.catalog.voice_search'.tr.replaceAll('{query}', query)), duration: const Duration(seconds: 1)),
    );
  }

  Future<void> _imageSearch() async {
    final source = await _pickImageSource();
    if (source == null || !mounted) return;
    final query = await sl<ImageSearchService>().matchQuery(source);
    if (query == null || query.isEmpty || !mounted) return;
    _searchController.text = query;
    context.read<CatalogBloc>().add(CatalogImageSearchRequested(query));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('orders.catalog.matched_photo'.tr.replaceAll('{query}', query)), duration: const Duration(seconds: 1)),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('orders.catalog.search_by_photo'.tr,
                    style: const TextStyle(color: Vibe.text, fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded, color: Vibe.violet),
              title: Text('orders.catalog.take_photo'.tr, style: const TextStyle(color: Vibe.text)),
              onTap: () => Navigator.pop(ctx, ImageSearchSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Vibe.violet),
              title: Text('orders.catalog.upload_gallery'.tr, style: const TextStyle(color: Vibe.text)),
              onTap: () => Navigator.pop(ctx, ImageSearchSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, String productId) {
    setState(() => _selectedProductId = productId);
  }

  void _closeDetail() {
    setState(() => _selectedProductId = null);
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
        leadingWidth: 96,
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'orders.catalog.back'.tr,
            ),
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.inventory_2_rounded),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: 'orders.catalog.menu'.tr,
              ),
            ),
          ],
        ),
        title: Text(
          widget.customer?.shopName ?? widget.leadDisplayName ?? 'orders.quotation.builder_title'.tr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Vibe.text, fontSize: 16, fontWeight: FontWeight.w800),
        ),
        iconTheme: const IconThemeData(color: Vibe.text),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;
          return FutureBuilder<List<Category>>(
            future: _categoriesFuture,
            builder: (context, snapshot) {
              final categories = snapshot.data ?? const [];
              final content = _BuilderBody(
                customer: widget.customer,
                summaryFuture: _summaryFuture,
                scrollController: _scrollController,
                searchController: _searchController,
                onScan: _scan,
                onVoice: _voiceSearch,
                onImage: _imageSearch,
                onOpenDetail: (id) => _openDetail(context, id),
                selectedProductId: _selectedProductId,
                onCloseDetail: _closeDetail,
                leadId: widget.leadId,
              );

              if (!isWide) return content;
              return Row(
                children: [
                  SizedBox(
                    width: 220.w,
                    child: Container(
                      decoration: const BoxDecoration(border: Border(right: BorderSide(color: Vibe.stroke))),
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
      bottomNavigationBar: QuotationBottomBar(onSave: _saveQuotation),
    );
  }

  void _selectCategory(BuildContext context, String? categoryId) {
    final bloc = context.read<CatalogBloc>();
    final current = bloc.state;
    final filter = current is CatalogLoaded ? current.filter : const ProductFilter();
    bloc.add(CatalogFilterChanged(filter.copyWith(categoryId: () => categoryId)));
  }
}

class _BuilderBody extends StatelessWidget {
  const _BuilderBody({
    required this.customer,
    required this.summaryFuture,
    required this.scrollController,
    required this.searchController,
    required this.onScan,
    required this.onVoice,
    required this.onImage,
    required this.onOpenDetail,
    required this.selectedProductId,
    required this.onCloseDetail,
    this.leadId,
  });
  final Customer? customer;
  final Future<CreditSummary?>? summaryFuture;
  final ScrollController scrollController;
  final TextEditingController searchController;
  final VoidCallback onScan;
  final VoidCallback onVoice;
  final VoidCallback onImage;
  final ValueChanged<String> onOpenDetail;
  final String? selectedProductId;
  final VoidCallback onCloseDetail;
  final String? leadId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogBloc, CatalogState>(
      builder: (context, state) {
        final loaded = state is CatalogLoaded ? state : null;
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SyncStatusBanner(),
                  if (customer != null && summaryFuture != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FutureBuilder<CreditSummary?>(
                        future: summaryFuture,
                        builder: (context, snapshot) => snapshot.data == null
                            ? const SizedBox.shrink()
                            : CreditSummaryCard(creditLimit: customer!.creditLimit, summary: snapshot.data!),
                      ),
                    ),
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
                CatalogLoading() => const CatalogGridSkeleton(),
                CatalogError(:final message) => Center(child: Text(message, style: const TextStyle(color: Vibe.muted))),
                CatalogLoaded() => _Loaded(
                    state: state,
                    scrollController: scrollController,
                    onOpenDetail: onOpenDetail,
                    selectedProductId: selectedProductId,
                    onCloseDetail: onCloseDetail,
                    leadId: leadId,
                  ),
              },
            ),
          ],
        );
      },
    );
  }
}

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
            Text('orders.catalog.idle_hint'.tr,
                textAlign: TextAlign.center, style: TextStyle(color: Vibe.muted, fontSize: 13.5, height: 1.4)),
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
    required this.selectedProductId,
    required this.onCloseDetail,
    this.leadId,
  });
  final CatalogLoaded state;
  final ScrollController scrollController;
  final ValueChanged<String> onOpenDetail;
  final String? selectedProductId;
  final VoidCallback onCloseDetail;
  final String? leadId;

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
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('orders.catalog.no_products'.tr, style: const TextStyle(color: Vibe.muted))),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
              sliver: SliverList.separated(
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  final product = state.items[index];
                  return ProductCard(
                    product: product,
                    isFavorite: false,
                    onTap: () => onOpenDetail(product.id),
                    onFavoriteToggle: () {},
                    onAddToCart: () {
                      context.read<CartCubit>().addProduct(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('orders.catalog.added_to_cart'.tr.replaceAll('{name}', product.name)), duration: const Duration(seconds: 1)),
                      );
                    },
                  );
                },
              ),
            ),
          if (state.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(color: Vibe.violet))),
            ),
          if (selectedProductId != null)
            SliverToBoxAdapter(
              child: ProductDetailInlineSection(
                key: ValueKey(selectedProductId),
                productId: selectedProductId!,
                leadId: leadId,
                onClose: onCloseDetail,
              ),
            ),
          const SliverToBoxAdapter(child: CartPreviewSection()),
        ],
      ),
    );
  }
}
