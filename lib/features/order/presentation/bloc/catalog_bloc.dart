import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product_filter.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/browse_products.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/fetch_brands.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog_event.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog_state.dart';

const _pageSize = 30;

/// Paginated product grid with **deferred fetching**: it starts in
/// [CatalogIdle] and makes no network round-trip until the user runs an
/// explicit query (text/voice/image) or picks a category/filter — so opening
/// the catalog is instant. Search is debounced + `restartable()` so fast
/// typing never races two in-flight queries.
class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  CatalogBloc({required BrowseProducts browseProducts, required FetchBrands fetchBrands})
      : _browseProducts = browseProducts,
        _fetchBrands = fetchBrands,
        super(const CatalogIdle()) {
    on<CatalogLoadRequested>(_onLoad, transformer: droppable());
    on<CatalogRefreshRequested>(_onRefresh, transformer: droppable());
    on<CatalogLoadMoreRequested>(_onLoadMore, transformer: droppable());
    on<CatalogSearchChanged>(_onSearchChanged, transformer: restartable());
    on<CatalogFilterChanged>(_onFilterChanged, transformer: restartable());
    on<CatalogVoiceSearchRequested>(_onVoiceSearch, transformer: restartable());
    on<CatalogImageSearchRequested>(_onImageSearch, transformer: restartable());
  }

  final BrowseProducts _browseProducts;
  final FetchBrands _fetchBrands;

  /// Brands are fetched once and reused — they don't change between queries,
  /// and the filter sheet needs them regardless of which query populated the grid.
  List<String>? _brands;

  Future<List<String>> _ensureBrands() async {
    if (_brands != null) return _brands!;
    final result = await _fetchBrands(const NoParams());
    return _brands = result.when(success: (b) => b, failure: (_) => const <String>[])!;
  }

  /// The single fetch path shared by text/voice/image/filter queries. Shows a
  /// full-screen spinner only when coming from idle; when a grid is already on
  /// screen it swaps results in place (no jarring flash).
  Future<void> _runQuery(String query, ProductFilter filter, Emitter<CatalogState> emit) async {
    if (state is! CatalogLoaded) emit(const CatalogLoading());
    final brands = await _ensureBrands();
    final result = await _browseProducts(
      BrowseProductsParams(page: 0, pageSize: _pageSize, query: query, filter: filter),
    );
    result.when(
      success: (paged) => emit(CatalogLoaded(
        items: paged.items,
        page: 0,
        hasMore: paged.hasMore,
        isLoadingMore: false,
        query: query,
        filter: filter,
        brands: brands,
      )),
      failure: (f) => emit(CatalogError(f.message)),
    );
  }

  Future<void> _onLoad(CatalogLoadRequested event, Emitter<CatalogState> emit) =>
      _runQuery('', const ProductFilter(), emit);

  Future<void> _onSearchChanged(CatalogSearchChanged event, Emitter<CatalogState> emit) async {
    final current = state;
    final filter = current is CatalogLoaded ? current.filter : const ProductFilter();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await _runQuery(event.query, filter, emit);
  }

  Future<void> _onFilterChanged(CatalogFilterChanged event, Emitter<CatalogState> emit) async {
    final current = state;
    final query = current is CatalogLoaded ? current.query : '';
    await _runQuery(query, event.filter, emit);
  }

  Future<void> _onVoiceSearch(CatalogVoiceSearchRequested event, Emitter<CatalogState> emit) async {
    final current = state;
    final filter = current is CatalogLoaded ? current.filter : const ProductFilter();
    await _runQuery(event.query, filter, emit);
  }

  Future<void> _onImageSearch(CatalogImageSearchRequested event, Emitter<CatalogState> emit) async {
    final current = state;
    final filter = current is CatalogLoaded ? current.filter : const ProductFilter();
    await _runQuery(event.query, filter, emit);
  }

  Future<void> _onRefresh(CatalogRefreshRequested event, Emitter<CatalogState> emit) async {
    final current = state;
    if (current is! CatalogLoaded) return _runQuery('', const ProductFilter(), emit);

    final result = await _browseProducts(
      BrowseProductsParams(page: 0, pageSize: _pageSize, query: current.query, filter: current.filter),
    );
    result.when(
      success: (paged) => emit(current.copyWith(items: paged.items, page: 0, hasMore: paged.hasMore)),
      failure: (_) => null,
    );
  }

  Future<void> _onLoadMore(CatalogLoadMoreRequested event, Emitter<CatalogState> emit) async {
    final current = state;
    if (current is! CatalogLoaded || !current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));
    final nextPage = current.page + 1;
    final result = await _browseProducts(
      BrowseProductsParams(page: nextPage, pageSize: _pageSize, query: current.query, filter: current.filter),
    );
    result.when(
      success: (paged) => emit(current.copyWith(
        items: [...current.items, ...paged.items],
        page: nextPage,
        hasMore: paged.hasMore,
        isLoadingMore: false,
      )),
      failure: (_) => emit(current.copyWith(isLoadingMore: false)),
    );
  }
}
