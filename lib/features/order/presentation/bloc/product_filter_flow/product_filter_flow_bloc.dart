import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/filter/category_filter_schema.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/filter/filter_selection.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/filter/filter_step.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/browse_products.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/fetch_filter_categories.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_category_filter_schema.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_filter_step_options.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_stock_location_options.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/product_filter_flow/product_filter_flow_event.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/product_filter_flow/product_filter_flow_state.dart';

const _pageSize = 30;
const _searchDebounce = Duration(milliseconds: 300);

/// Drives the guided product configurator end to end: category → family →
/// specifications → products → add.
///
/// Two rules are enforced here and nowhere else, because they are the reason
/// the flow exists:
///
/// 1. **A product query only runs for a bounded request.** There is exactly
///    one call site for [BrowseProducts] in this class, guarded by
///    `hasSearch || isFilterComplete`. Browsing must finish the hierarchy;
///    searching must be deliberate enough to clear
///    [ProductFilterFlowState.minQueryLength]. Nothing else reaches the
///    catalog, so an idle screen can never pull the whole product list.
/// 2. **Each level costs one small query.** Options for step N+1 are fetched
///    when step N is answered — never speculatively, never in bulk.
///
/// Steps that resolve to no options for the current selection are skipped
/// automatically rather than shown empty, which is what lets one generic schema
/// serve categories with very different attribute coverage.
class ProductFilterFlowBloc
    extends Bloc<ProductFilterFlowEvent, ProductFilterFlowState> {
  ProductFilterFlowBloc({
    required FetchFilterCategories fetchFilterCategories,
    required GetCategoryFilterSchema getCategoryFilterSchema,
    required GetFilterStepOptions getFilterStepOptions,
    required GetStockLocationOptions getStockLocationOptions,
    required BrowseProducts browseProducts,
  })  : _fetchFilterCategories = fetchFilterCategories,
        _getCategoryFilterSchema = getCategoryFilterSchema,
        _getFilterStepOptions = getFilterStepOptions,
        _getStockLocationOptions = getStockLocationOptions,
        _browseProducts = browseProducts,
        super(const ProductFilterFlowState()) {
    // Flow mutations run sequentially: each one leaves the selection in a state
    // the next one reads, so interleaving them would resolve options against a
    // selection that no longer exists.
    on<FilterFlowStarted>(_onStarted, transformer: droppable());
    on<FilterCategorySelected>(_onCategorySelected, transformer: sequential());
    on<FilterStepAnswered>(_onStepAnswered, transformer: sequential());
    on<FilterStepCleared>(_onStepCleared, transformer: sequential());
    on<FilterFlowBackRequested>(_onBack, transformer: sequential());
    on<FilterFlowReset>(_onReset, transformer: sequential());
    on<FindNewProductRequested>(_onFindNewProduct, transformer: sequential());
    on<FilterPreferencesChanged>(_onPreferencesChanged,
        transformer: sequential());
    on<FilterProductSearchChanged>(_onSearchChanged,
        transformer: restartable());
    on<FilterProductsRefreshed>(_onRefreshed, transformer: droppable());
    on<FilterProductsLoadMoreRequested>(_onLoadMore, transformer: droppable());
    // Sequential like the other narrowing events: it re-runs the product query,
    // and two locations in flight at once would let the slower response
    // overwrite the newer selection's results.
    on<FilterStockLocationChanged>(_onStockLocationChanged,
        transformer: sequential());
  }

  final FetchFilterCategories _fetchFilterCategories;
  final GetCategoryFilterSchema _getCategoryFilterSchema;
  final GetFilterStepOptions _getFilterStepOptions;
  final GetStockLocationOptions _getStockLocationOptions;
  final BrowseProducts _browseProducts;

  // ── Entry ───────────────────────────────────────────────────────────

  Future<void> _onStarted(
      FilterFlowStarted event, Emitter<ProductFilterFlowState> emit) async {
    emit(state.copyWith(
        status: FilterFlowStatus.loading, errorMessage: () => null));
    final result = await _fetchFilterCategories(const NoParams());
    result.when(
      success: (categories) => emit(state.copyWith(
        status: FilterFlowStatus.ready,
        categories: categories,
      )),
      failure: (f) => emit(state.copyWith(
        status: FilterFlowStatus.failure,
        errorMessage: () => f.message,
      )),
    );
  }

  // ── Selection ───────────────────────────────────────────────────────

  Future<void> _onCategorySelected(FilterCategorySelected event,
      Emitter<ProductFilterFlowState> emit) async {
    emit(state.copyWith(
      category: () => event.category,
      schema: () => null,
      selection: const FilterSelection.empty(),
      skippedStepKeys: const {},
      activeStep: () => null,
      activeOptions: const [],
      optionsLoading: true,
      products: const [],
      productStatus: ProductListStatus.idle,
      query: '',
      page: 0,
      hasMore: false,
      errorMessage: () => null,
      stockLocations: const [],
      stockLocationCode: () => null,
    ));

    final result =
        await _getCategoryFilterSchema(CategorySchemaParams(event.category.id));

    final schema = result.when(
      success: (s) => s,
      failure: (_) => null,
    );
    if (schema == null) {
      emit(state.copyWith(
        optionsLoading: false,
        status: FilterFlowStatus.failure,
        errorMessage: () => result.when(
          success: (_) => null,
          failure: (f) => f.message,
        ),
      ));
      return;
    }

    emit(state.copyWith(schema: () => schema));
    await _advance(emit);
  }

  Future<void> _onStepAnswered(
      FilterStepAnswered event, Emitter<ProductFilterFlowState> emit) async {
    final schema = state.schema;
    final step = schema?.stepByKey(event.stepKey);
    if (schema == null || step == null) return;

    emit(state.copyWith(
      selection: state.selection.select(step, event.option),
      // Anything skipped downstream was skipped against the *old* answer; it
      // has to be re-evaluated, not inherited.
      skippedStepKeys:
          _skipsAbove(schema, state.skippedStepKeys, step.sortOrder),
      // The search survives: it narrows *with* the filters, it isn't an
      // alternative to them.
      products: const [],
      productStatus: ProductListStatus.idle,
      // A different answer matches a different set of SKUs, which may not be
      // held at the location the rep had pinned. Keeping it would silently
      // filter the new results down to nothing.
      stockLocations: const [],
      stockLocationCode: () => null,
    ));
    await _advance(emit);
  }

  Future<void> _onStepCleared(
      FilterStepCleared event, Emitter<ProductFilterFlowState> emit) async {
    final schema = state.schema;
    final entry = state.selection.entryFor(event.stepKey);
    if (schema == null || entry == null) return;

    emit(state.copyWith(
      selection: state.selection.clearFrom(event.stepKey),
      skippedStepKeys:
          _skipsAbove(schema, state.skippedStepKeys, entry.sortOrder),
      products: const [],
      productStatus: ProductListStatus.idle,
      stockLocations: const [],
      stockLocationCode: () => null,
    ));
    await _advance(emit);
  }

  Future<void> _onBack(
      FilterFlowBackRequested event, Emitter<ProductFilterFlowState> emit) {
    final entries = state.selection.entries;
    if (entries.isEmpty) return _onReset(const FilterFlowReset(), emit);
    return _onStepCleared(FilterStepCleared(entries.last.stepKey), emit);
  }

  Future<void> _onReset(
      FilterFlowReset event, Emitter<ProductFilterFlowState> emit) async {
    emit(_clearedFlow());
  }

  /// "Find New Product" — identical to a reset from the flow's point of view.
  /// It exists as its own event because it means something different to the
  /// rep (start the next line item, keep everything already in the cart) and
  /// because that intent is worth being able to see in a bloc trace.
  Future<void> _onFindNewProduct(FindNewProductRequested event,
      Emitter<ProductFilterFlowState> emit) async {
    emit(_clearedFlow());
  }

  ProductFilterFlowState _clearedFlow() => state.copyWith(
        category: () => null,
        schema: () => null,
        selection: const FilterSelection.empty(),
        skippedStepKeys: const {},
        activeStep: () => null,
        activeOptions: const [],
        optionsLoading: false,
        products: const [],
        productStatus: ProductListStatus.idle,
        page: 0,
        hasMore: false,
        query: '',
        errorMessage: () => null,
        stockLocations: const [],
        stockLocationCode: () => null,
        stockLocationsLoading: false,
      );

  Future<void> _onPreferencesChanged(FilterPreferencesChanged event,
      Emitter<ProductFilterFlowState> emit) async {
    emit(state.copyWith(
      sortBy: event.sortBy,
      availableOnly: event.availableOnly,
    ));
    await _maybeLoadProducts(emit);
  }

  /// Walks forward from the current selection to the next step that has
  /// something to ask, loading exactly one option list per candidate, and
  /// requests products once nothing is left to ask.
  Future<void> _advance(Emitter<ProductFilterFlowState> emit) async {
    final schema = state.schema;
    if (schema == null) return;

    var skipped = state.skippedStepKeys;

    while (true) {
      final candidate = _nextStep(schema, state.selection, skipped);
      if (candidate == null) {
        emit(state.copyWith(
          activeStep: () => null,
          activeOptions: const [],
          optionsLoading: false,
          skippedStepKeys: skipped,
        ));
        await _loadProducts(emit, page: 0);
        return;
      }

      emit(state.copyWith(
        activeStep: () => candidate,
        activeOptions: const [],
        optionsLoading: true,
        skippedStepKeys: skipped,
      ));

      final result = await _getFilterStepOptions(FilterStepOptionsParams(
        schema: schema,
        step: candidate,
        selection: state.selection,
      ));

      final options = result.when(
        success: (o) => o,
        failure: (_) => null,
      );

      if (options == null) {
        emit(state.copyWith(
          optionsLoading: false,
          status: FilterFlowStatus.failure,
          errorMessage: () =>
              result.when(success: (_) => null, failure: (f) => f.message),
        ));
        return;
      }

      // Nothing to choose from — an empty picker is a dead end, so pass over it
      // instead of rendering it.
      if (options.isEmpty) {
        skipped = {...skipped, candidate.key};
        continue;
      }

      emit(state.copyWith(
        activeOptions: options,
        optionsLoading: false,
        status: FilterFlowStatus.ready,
        skippedStepKeys: skipped,
      ));
      // Steps remain, but an active search means results are on screen right
      // now — the answer just changed what "matching" means, so they follow it.
      await _maybeLoadProducts(emit);
      return;
    }
  }

  static FilterStep? _nextStep(
    CategoryFilterSchema schema,
    FilterSelection selection,
    Set<String> skipped,
  ) {
    for (final step in schema.steps) {
      if (skipped.contains(step.key)) continue;
      if (selection.entryFor(step.key) != null) continue;
      return step;
    }
    return null;
  }

  /// Keeps only the skips decided *above* [sortOrder]. A step skipped further
  /// down was skipped because of an answer that has just changed, so that
  /// verdict no longer holds and it must be re-evaluated.
  static Set<String> _skipsAbove(
    CategoryFilterSchema schema,
    Set<String> skipped,
    int sortOrder,
  ) {
    return skipped.where((key) {
      final step = schema.stepByKey(key);
      return step != null && step.sortOrder < sortOrder;
    }).toSet();
  }

  // ── Products ────────────────────────────────────────────────────────
  //
  // Reachable two ways, and only these two: the hierarchy is fully answered,
  // or the rep typed a search long enough to be deliberate. Both are bounded —
  // one by the filters, the other by paging — which is what keeps the
  // "never download the catalog" guarantee intact while still letting an
  // experienced rep jump straight to a material code.

  Future<void> _onSearchChanged(FilterProductSearchChanged event,
      Emitter<ProductFilterFlowState> emit) async {
    if (event.query == state.query) return;
    await Future<void>.delayed(_searchDebounce);
    emit(state.copyWith(query: event.query));

    if (state.hasSearch || state.isFilterComplete) {
      await _loadProducts(emit, page: 0);
      return;
    }
    // The search was cleared before the hierarchy was finished — drop the
    // results and let the rep carry on where they left off.
    emit(state.copyWith(
      products: const [],
      productStatus: ProductListStatus.idle,
      page: 0,
      hasMore: false,
    ));
  }

  Future<void> _onRefreshed(FilterProductsRefreshed event,
          Emitter<ProductFilterFlowState> emit) =>
      _maybeLoadProducts(emit);

  /// Loads the first page when — and only when — the current state is one the
  /// product query is allowed to run for.
  Future<void> _maybeLoadProducts(Emitter<ProductFilterFlowState> emit) async {
    if (!state.hasSearch && !state.isFilterComplete) return;
    await _loadProducts(emit, page: 0);
  }

  Future<void> _onStockLocationChanged(FilterStockLocationChanged event,
      Emitter<ProductFilterFlowState> emit) async {
    if (event.warehouseCode == state.stockLocationCode) return;
    emit(state.copyWith(
      stockLocationCode: () => event.warehouseCode,
      products: const [],
      page: 0,
      hasMore: false,
    ));
    await _maybeLoadProducts(emit);
  }

  /// Resolves which locations can supply the current match.
  ///
  /// Runs alongside the first page of results, never per page: the answer
  /// depends on the selection, not on how far the rep has scrolled. A failure
  /// is swallowed on purpose — losing the location chips must not turn a
  /// working product list into an error screen.
  Future<void> _loadStockLocations(Emitter<ProductFilterFlowState> emit) async {
    emit(state.copyWith(stockLocationsLoading: true));
    final result = await _getStockLocationOptions(StockLocationOptionsParams(
      categoryId: state.category?.id,
      selection: state.selection,
    ));
    emit(state.copyWith(
      stockLocations: result.when(
        success: (options) => options,
        failure: (_) => const [],
      ),
      stockLocationsLoading: false,
    ));
  }

  Future<void> _onLoadMore(FilterProductsLoadMoreRequested event,
      Emitter<ProductFilterFlowState> emit) async {
    if (!state.hasMore ||
        state.productStatus == ProductListStatus.loadingMore) {
      return;
    }
    await _loadProducts(emit, page: state.page + 1);
  }

  Future<void> _loadProducts(
    Emitter<ProductFilterFlowState> emit, {
    required int page,
  }) async {
    // The one gate on product reads in this feature.
    if (!state.hasSearch && !state.isFilterComplete) return;

    emit(state.copyWith(
      productStatus:
          page == 0 ? ProductListStatus.loading : ProductListStatus.loadingMore,
      errorMessage: () => null,
    ));

    final result = await _browseProducts(BrowseProductsParams(
      page: page,
      pageSize: _pageSize,
      query: state.query,
      filter: state.productFilter,
    ));

    result.when(
      success: (paged) => emit(state.copyWith(
        products: page == 0 ? paged.items : [...state.products, ...paged.items],
        page: page,
        hasMore: paged.hasMore,
        productStatus: ProductListStatus.loaded,
      )),
      failure: (f) => emit(state.copyWith(
        productStatus: ProductListStatus.failure,
        errorMessage: () => f.message,
      )),
    );

    // After the results, so the list paints first — the chips refine what is
    // already on screen and are never worth delaying it for.
    if (page == 0 && state.productStatus == ProductListStatus.loaded) {
      await _loadStockLocations(emit);
    }
  }
}
