import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart'; // Added for context.appColors
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/catalog_filter_store.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/cart_item.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/category.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/credit_summary.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/off_visit_reason.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product_filter.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/image_search_service.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/voice_search_service.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/fetch_categories.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/fetch_favorites.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_credit_summary.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/toggle_favorite.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_state.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/catalog_bloc.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/catalog_event.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/catalog_state.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/quotation/customized_product_form_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/quotation/quotation_detail_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/quotation/quotation_preview_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/catalog_filter_sheet.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/catalog_search_bar.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/product_lists_section.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/sync_status_banner.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter/active_filter_chips_bar.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter/filter_category_selector.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter/filter_dropdown.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter/product_filter_facets.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter/quantity_stepper.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter/unit_selector.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/cart_preview_section.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/credit_summary_card.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/discount_section.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/quotation_bottom_bar.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/quotation_preview_section.dart';

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
  final CatalogFilterStore _store = sl<CatalogFilterStore>();

  late Future<List<Category>> _categoriesFuture;
  Future<CreditSummary?>? _summaryFuture;

  Set<String> _favoriteIds = {};
  String? _expandedProductId;
  int _selectedDiscount = 0;

  String _selectedUnit = 'Pc';
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = sl<FetchCategories>()(const NoParams()).then(
      (result) =>
          result.when(success: (c) => c, failure: (_) => const <Category>[]),
    );

    final snapshot = _store.load();
    _searchController.text = snapshot.query;
    _selectedUnit = snapshot.unit;
    _quantity = snapshot.quantity;

    context.read<SyncCubit>().syncIfNeeded();
    context.read<CatalogBloc>().add(
          CatalogRestoreRequested(
            query: snapshot.query,
            filter: snapshot.filter,
          ),
        );
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

  ProductFilter get _currentFilter {
    final state = context.read<CatalogBloc>().state;
    return state is CatalogLoaded ? state.filter : const ProductFilter();
  }

  void _persist({ProductFilter? filter, String? query}) {
    _store.save(CatalogFilterSnapshot(
      filter: filter ?? _currentFilter,
      query: query ?? _searchController.text,
      unit: _selectedUnit,
      quantity: _quantity,
    ));
  }

  void _applyFilter(ProductFilter next) {
    context.read<CatalogBloc>().add(CatalogFilterChanged(next));
    _persist(filter: next);
  }

  void _onSearchChanged(String query) {
    setState(() {});
    context.read<CatalogBloc>().add(CatalogSearchChanged(query));
    _persist(query: query);
  }

  void _selectUnit(String unit) {
    setState(() => _selectedUnit = unit);
    _persist();
  }

  void _selectQuantity(int quantity) {
    setState(() => _quantity = quantity);
    _persist();
  }

  void _selectCategory(String? categoryId) => _applyFilter(
      _currentFilter.copyWith(categoryId: () => categoryId).clearAttributes());

  void _onFacetChanged(FilterFacet facet, String? value) =>
      _applyFilter(ProductFilterFacets.apply(facet, value, _currentFilter));

  void _clearAllFilters() => _applyFilter(const ProductFilter());

  void _autoRevealSingleMatch(CatalogState state) {
    if (state is! CatalogLoaded) return;
    if (!state.filter.hasActiveAttributes) return;
    if (state.items.length != 1) return;

    final onlyMatch = state.items.first;
    if (_expandedProductId != onlyMatch.id) {
      setState(() => _expandedProductId = onlyMatch.id);
    }
  }

  Future<void> _loadFavorites() async {
    final result = await sl<FetchFavorites>()(const NoParams());
    if (!mounted) return;
    result.when(
      success: (products) =>
          setState(() => _favoriteIds = products.map((p) => p.id).toSet()),
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
    setState(() => _expandedProductId =
        _expandedProductId == productId ? null : productId);
  }

  void _selectDiscount(int percent) {
    setState(() => _selectedDiscount = percent);
  }

  /// Opens the category-aware customization form, carrying the live [CartCubit]
  /// so the customized line lands in this same cart.
  void _openCustomize(Product product) {
    final cartCubit = context.read<CartCubit>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cartCubit,
          child: CustomizedProductFormScreen(
            baseProduct: product,
            leadId: widget.leadId,
            customerId: widget.customer?.id,
          ),
        ),
      ),
    );
  }

  Future<void> _voiceSearch() async {
    final query = await sl<VoiceSearchService>().listen();
    if (query == null || query.trim().isEmpty || !mounted) return;
    setState(() => _searchController.text = query);
    context.read<CatalogBloc>().add(CatalogVoiceSearchRequested(query));
    _persist(query: query);
  }

  Future<void> _imageSearch() async {
    final query =
        await sl<ImageSearchService>().matchQuery(ImageSearchSource.gallery);
    if (query == null || query.isEmpty || !mounted) return;
    setState(() => _searchController.text = query);
    context.read<CatalogBloc>().add(CatalogImageSearchRequested(query));
    _persist(query: query);
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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('orders.quotation_extra.save_failed'.tr)));
      return;
    }

    Navigator.of(context).pushReplacement(MaterialPageRoute(
      settings: const RouteSettings(name: QuotationDetailScreen.routeName),
      builder: (_) => QuotationDetailScreen(quotation: quotation),
    ));
  }

  String? _categoryName(List<Category> categories, String? id) {
    if (id == null) return null;
    for (final category in categories) {
      if (category.id == id) return category.name;
    }
    return null;
  }

  Widget _buildFacetDropdowns({
    required ProductFilter filter,
    required String? categoryName,
    required List<Product> items,
    required bool loading,
  }) {
    final facets = ProductFilterFacets.facetsFor(categoryName);
    if (facets.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final facet in facets) ...[
          FilterDropdown(
            label: facet.label,
            icon: _facetIcon(facet),
            value: ProductFilterFacets.selectedValue(facet, filter),
            options: ProductFilterFacets.optionsFor(facet, items),
            onChanged: (value) => _onFacetChanged(facet, value),
            loading: loading && items.isEmpty,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildUnitAndQuantity() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel('orders.quotation_extra.unit'.tr),
              const SizedBox(height: 8),
              UnitSelector.standard(
                selected: _selectedUnit,
                onChanged: _selectUnit,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel('orders.quotation_extra.quantity'.tr),
            const SizedBox(height: 8),
            QuantityStepper(
              value: _quantity,
              onChanged: _selectQuantity,
            ),
          ],
        ),
      ],
    );
  }

  List<FilterChipData> _buildChips(
      ProductFilter filter, List<Category> categories) {
    final chips = <FilterChipData>[];
    if (filter.categoryId != null) {
      final name = _categoryName(categories, filter.categoryId);
      chips.add(FilterChipData(
        label: 'orders.filter.category'
            .trParams({'name': name ?? filter.categoryId}),
        onClear: () => _selectCategory(null),
      ));
    }
    for (final facet in FilterFacet.values) {
      final label = ProductFilterFacets.chipLabel(facet, filter);
      if (label != null) {
        chips.add(FilterChipData(
          label: label,
          onClear: () => _onFacetChanged(facet, null),
        ));
      }
    }
    return chips;
  }

  IconData _facetIcon(FilterFacet facet) => switch (facet) {
        FilterFacet.size => Icons.straighten_rounded,
        FilterFacet.length => Icons.height_rounded,
        FilterFacet.meshSize => Icons.grid_on_rounded,
        FilterFacet.quality => Icons.verified_rounded,
        FilterFacet.diameter => Icons.circle_outlined,
        FilterFacet.thickness => Icons.layers_rounded,
        FilterFacet.material => Icons.category_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        leading: BackButton(color: colorScheme.primary),
        title: Text(
          widget.customer?.shopName ??
              widget.leadDisplayName ??
              'orders.quotation.builder_title'.tr,
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
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

                return BlocConsumer<CatalogBloc, CatalogState>(
                  listener: (context, state) => _autoRevealSingleMatch(state),
                  builder: (context, catalogState) {
                    final filter = catalogState is CatalogLoaded
                        ? catalogState.filter
                        : const ProductFilter();
                    final brands = catalogState is CatalogLoaded
                        ? catalogState.brands
                        : const <String>[];
                    final items = catalogState is CatalogLoaded
                        ? catalogState.items
                        : const <Product>[];
                    final loading = catalogState is CatalogLoading;
                    final categoryName =
                        _categoryName(categories, filter.categoryId);

                    return ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
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
                          onSearchChanged: _onSearchChanged,
                          onFilterTap: () => showCatalogFilterSheet(
                            context: context,
                            filter: filter,
                            brands: brands,
                            onApply: _applyFilter,
                          ),
                          hasActiveFilters: !filter.isEmpty,
                          onVoiceTap: _voiceSearch,
                          onImageTap: _imageSearch,
                        ),
                        const SizedBox(height: 16),
                        _SectionLabel('orders.quotation_extra.category'.tr),
                        const SizedBox(height: 8),
                        FilterCategorySelector(
                          categories: categories,
                          selectedCategoryId: filter.categoryId,
                          onSelect: _selectCategory,
                        ),
                        const SizedBox(height: 16),
                        _buildFacetDropdowns(
                          filter: filter,
                          categoryName: categoryName,
                          items: items,
                          loading: loading,
                        ),
                        const SizedBox(height: 6),
                        _buildUnitAndQuantity(),
                        const SizedBox(height: 16),
                        ActiveFilterChipsBar(
                          chips: _buildChips(filter, categories),
                          onClearAll: _clearAllFilters,
                        ),
                        const SizedBox(height: 12),
                        _SectionLabel('orders.quotation_extra.results'.tr),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 320,
                          child: ProductListSection(
                            state: catalogState,
                            favoriteIds: _favoriteIds,
                            expandedProductId: _expandedProductId,
                            leadId: widget.leadId,
                            customerId: widget.customer?.id,
                            onToggleFavorite: _toggleFavorite,
                            onToggleExpanded: _toggleExpanded,
                            onCustomize: _openCustomize,
                            height: 280,
                            hasActiveAttributeFilter:
                                filter.hasActiveAttributes,
                            quantity: _quantity.toDouble(),
                            unit: _selectedUnit,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DiscountSection(
                          selectedDiscount: _selectedDiscount,
                          onDiscountSelected: _selectDiscount,
                        ),
                        const SizedBox(height: 16),
                        const CartPreviewSection(),
                        BlocBuilder<CartCubit, CartState>(
                          builder: (context, cartState) {
                            final List<CartItem> cartItems =
                                cartState is CartLoaded
                                    ? cartState.items
                                    : const <CartItem>[];
                            final double subtotal = cartState is CartLoaded
                                ? cartState.subtotal
                                : 0.0;
                            final int totalItemsCount = cartItems.length;

                            final double discountAmount =
                                subtotal * (_selectedDiscount / 100.0);
                            final double taxAmount =
                                (subtotal - discountAmount) * 0.10;
                            final double finalTotal =
                                (subtotal - discountAmount) + taxAmount;

                            final String displayShopName =
                                widget.customer?.shopName ??
                                    widget.leadDisplayName ??
                                    'orders.quotation_extra.walk_in'.tr;

                            return QuotationPreviewSection(
                              shopName: displayShopName,
                              items: cartItems,
                              subtotal: subtotal,
                              discount: discountAmount,
                              tax: taxAmount,
                              total: finalTotal,
                              onEnlargeTap: totalItemsCount == 0
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => QuotationScreen(
                                            shopName: displayShopName,
                                            subtotal: subtotal,
                                            discount: discountAmount,
                                            tax: taxAmount,
                                            total: finalTotal,
                                            items: cartItems,
                                            quotationNumber:
                                                widget.editingQuotation?.id,
                                            customerPhone:
                                                widget.customer?.phone,
                                            customerAddress:
                                                widget.customer?.address,
                                          ),
                                        ),
                                      );
                                    },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          QuotationBottomBar(
              onSave: _saveQuotation, discount: _selectedDiscount),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          color: context.appColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      );
}
