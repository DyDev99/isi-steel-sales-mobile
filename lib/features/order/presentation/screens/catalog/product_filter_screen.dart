import 'dart:async';

import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/catalog_filter_store.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/category.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product_filter.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/count_products.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/fetch_categories.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/toggle_favorite.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/catalog_bloc.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/catalog_event.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/catalog_state.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/product_lists_section.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter/active_filter_chips_bar.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter/filter_action_bar.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter/filter_category_selector.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter/filter_dropdown.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter/product_filter_facets.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter/quantity_stepper.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter/unit_selector.dart';

class ProductFilterScreen extends StatefulWidget {
  const ProductFilterScreen({super.key, this.leadId, this.customerId});

  static const routeName = 'order-product-filter';

  final String? leadId;
  final String? customerId;

  static Widget provider({String? leadId, String? customerId}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<CatalogBloc>()),
        BlocProvider(create: (_) => sl<CartCubit>()..load()),
      ],
      child: ProductFilterScreen(leadId: leadId, customerId: customerId),
    );
  }

  @override
  State<ProductFilterScreen> createState() => _ProductFilterScreenState();
}

class _ProductFilterScreenState extends State<ProductFilterScreen> {
  final CatalogFilterStore _store = sl<CatalogFilterStore>();
  final TextEditingController _searchController = TextEditingController();
  Timer? _countDebounce;

  List<Category> _categories = const [];
  ProductFilter _filter = const ProductFilter();
  String _query = '';
  String _unit = 'Pc';
  int _quantity = 1;
  int? _count;
  final Set<String> _favoriteIds = {};
  String? _expandedProductId;

  @override
  void initState() {
    super.initState();
    final snapshot = _store.load();
    _filter = snapshot.filter;
    _query = snapshot.query;
    _unit = snapshot.unit;
    _quantity = snapshot.quantity;
    _searchController.text = _query;

    context
        .read<CatalogBloc>()
        .add(CatalogRestoreRequested(query: _query, filter: _filter));
    _loadCategories();
    _refreshCount();
  }

  @override
  void dispose() {
    _countDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final result = await sl<FetchCategories>()(const NoParams());
    if (!mounted) return;
    setState(() => _categories =
        result.when(success: (c) => c, failure: (_) => const <Category>[])!);
  }

  String? get _selectedCategoryName {
    final id = _filter.categoryId;
    if (id == null) return null;
    for (final category in _categories) {
      if (category.id == id) return category.name;
    }
    return null;
  }

  bool get _canReset =>
      !_filter.isEmpty || _query.isNotEmpty || _unit != 'Pc' || _quantity != 1;

  void _persist() => _store.save(CatalogFilterSnapshot(
        filter: _filter,
        query: _query,
        unit: _unit,
        quantity: _quantity,
      ));

  void _refreshCount() {
    _countDebounce?.cancel();
    _countDebounce = Timer(const Duration(milliseconds: 220), () async {
      final result = await sl<CountProducts>()(
        BrowseProductsParams(
            page: 0, pageSize: 1, query: _query, filter: _filter),
      );
      if (!mounted) return;
      setState(() =>
          _count = result.when(success: (c) => c, failure: (_) => _count));
    });
  }

  void _applyFilter(ProductFilter next) {
    setState(() => _filter = next);
    context.read<CatalogBloc>().add(CatalogFilterChanged(next));
    _refreshCount();
    _persist();
  }

  void _onSearch(String query) {
    _query = query;
    context.read<CatalogBloc>().add(CatalogSearchChanged(query));
    _refreshCount();
    _persist();
  }

  void _selectCategory(String? id) =>
      _applyFilter(_filter.copyWith(categoryId: () => id).clearAttributes());

  void _onFacetChanged(FilterFacet facet, String? value) =>
      _applyFilter(ProductFilterFacets.apply(facet, value, _filter));

  void _clearAllFilters() => _applyFilter(const ProductFilter());

  void _resetEverything() {
    setState(() {
      _filter = const ProductFilter();
      _query = '';
      _unit = 'Pc';
      _quantity = 1;
    });
    _searchController.clear();
    context
        .read<CatalogBloc>()
        .add(const CatalogRestoreRequested(query: '', filter: ProductFilter()));
    _refreshCount();
    _persist();
  }

  void _toggleFavorite(String id) {
    setState(() => _favoriteIds.contains(id)
        ? _favoriteIds.remove(id)
        : _favoriteIds.add(id));
    sl<ToggleFavorite>()(ProductIdParams(id));
  }

  void _toggleExpanded(String id) =>
      setState(() => _expandedProductId = _expandedProductId == id ? null : id);

  List<FilterChipData> _buildChips() {
    final chips = <FilterChipData>[];
    if (_filter.categoryId != null) {
      chips.add(FilterChipData(
        label: 'orders.filter.category'
            .trParams({'name': _selectedCategoryName ?? _filter.categoryId}),
        onClear: () => _selectCategory(null),
      ));
    }
    for (final facet in FilterFacet.values) {
      final label = ProductFilterFacets.chipLabel(facet, _filter);
      if (label != null) {
        chips.add(FilterChipData(
          label: label,
          onClear: () => _onFacetChanged(facet, null),
        ));
      }
    }
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text(
          'orders.filter.title'.tr,
          style: TextStyle(
              color: colors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800),
        ),
        actions: [
          if (_filter.activeFacetCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _clearAllFilters,
                child: Text('common.clear_all'.tr,
                    style: TextStyle(color: colors.warning)),
              ),
            ),
        ],
      ),
      body: BlocBuilder<CatalogBloc, CatalogState>(
        builder: (context, state) {
          final items =
              state is CatalogLoaded ? state.items : const <Product>[];
          final loading = state is CatalogLoading;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  children: [
                    _searchField(context),
                    const SizedBox(height: 16),
                    const _SectionLabel('Category'),
                    const SizedBox(height: 8),
                    FilterCategorySelector(
                      categories: _categories,
                      selectedCategoryId: _filter.categoryId,
                      onSelect: _selectCategory,
                    ),
                    const SizedBox(height: 16),
                    _buildFacetDropdowns(items, loading),
                    _buildUnitAndQuantity(),
                    const SizedBox(height: 16),
                    ActiveFilterChipsBar(
                      chips: _buildChips(),
                      onClearAll: _clearAllFilters,
                    ),
                    const SizedBox(height: 12),
                    const _SectionLabel('Results'),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 320,
                      child: ProductListSection(
                        state: state,
                        favoriteIds: _favoriteIds,
                        expandedProductId: _expandedProductId,
                        leadId: widget.leadId,
                        customerId: widget.customerId,
                        onToggleFavorite: _toggleFavorite,
                        onToggleExpanded: _toggleExpanded,
                        height: 280,
                        hasActiveAttributeFilter: _filter.hasActiveAttributes,
                      ),
                    ),
                  ],
                ),
              ),
              FilterActionBar(
                resultCount: _count ?? items.length,
                canReset: _canReset,
                loading: _count == null && loading,
                onReset: _resetEverything,
                onApply: () => Navigator.of(context).maybePop(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFacetDropdowns(List<Product> items, bool loading) {
    final facets = ProductFilterFacets.facetsFor(_selectedCategoryName);
    if (facets.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final facet in facets) ...[
          FilterDropdown(
            label: facet.label,
            icon: _facetIcon(facet),
            value: ProductFilterFacets.selectedValue(facet, _filter),
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
              const _SectionLabel('Unit'),
              const SizedBox(height: 8),
              UnitSelector.standard(
                selected: _unit,
                onChanged: (unit) {
                  setState(() => _unit = unit);
                  _persist();
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('Quantity'),
            const SizedBox(height: 8),
            QuantityStepper(
              value: _quantity,
              onChanged: (qty) {
                setState(() => _quantity = qty);
                _persist();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _searchField(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: colors.iconMuted, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              textInputAction: TextInputAction.search,
              style: TextStyle(color: colors.textPrimary, fontSize: 13.5),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'orders.filter.search_hint'.tr,
                hintStyle: TextStyle(color: colors.textHint, fontSize: 13.5),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            InkWell(
              onTap: () {
                _searchController.clear();
                _onSearch('');
              },
              borderRadius: BorderRadius.circular(20),
              child:
                  Icon(Icons.close_rounded, color: colors.iconMuted, size: 18),
            ),
        ],
      ),
    );
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
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: colors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
    );
  }
}
