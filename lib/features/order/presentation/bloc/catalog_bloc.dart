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

/// Paginated product grid — never loads the whole catalog into memory, only
/// the visible pages. Search is debounced + `restartable()` so fast typing
/// never races two in-flight queries.
class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  CatalogBloc({required BrowseProducts browseProducts, required FetchBrands fetchBrands})
      : _browseProducts = browseProducts,
        _fetchBrands = fetchBrands,
        super(const CatalogInitial()) {
    on<CatalogLoadRequested>(_onLoad, transformer: droppable());
    on<CatalogRefreshRequested>(_onRefresh, transformer: droppable());
    on<CatalogLoadMoreRequested>(_onLoadMore, transformer: droppable());
    on<CatalogSearchChanged>(_onSearchChanged, transformer: restartable());
    on<CatalogFilterChanged>(_onFilterChanged, transformer: restartable());
  }

  final BrowseProducts _browseProducts;
  final FetchBrands _fetchBrands;

  Future<void> _onLoad(CatalogLoadRequested event, Emitter<CatalogState> emit) async {
    emit(const CatalogLoading());
    final brandsResult = await _fetchBrands(const NoParams());
    final brands = brandsResult.when(success: (b) => b, failure: (_) => const <String>[]);

    final result = await _browseProducts(const BrowseProductsParams(page: 0, pageSize: _pageSize));
    result.when(
      success: (paged) => emit(CatalogLoaded(
        items: paged.items,
        page: 0,
        hasMore: paged.hasMore,
        isLoadingMore: false,
        query: '',
        filter: const ProductFilter(),
        brands: brands,
      )),
      failure: (f) => emit(CatalogError(f.message)),
    );
  }

  Future<void> _onRefresh(CatalogRefreshRequested event, Emitter<CatalogState> emit) async {
    final current = state;
    if (current is! CatalogLoaded) return _onLoad(const CatalogLoadRequested(), emit);

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

  Future<void> _onSearchChanged(CatalogSearchChanged event, Emitter<CatalogState> emit) async {
    final current = state;
    if (current is! CatalogLoaded) return;

    await Future<void>.delayed(const Duration(milliseconds: 300));
    final result = await _browseProducts(
      BrowseProductsParams(page: 0, pageSize: _pageSize, query: event.query, filter: current.filter),
    );
    result.when(
      success: (paged) => emit(current.copyWith(
        items: paged.items,
        page: 0,
        hasMore: paged.hasMore,
        query: event.query,
      )),
      failure: (f) => emit(CatalogError(f.message)),
    );
  }

  Future<void> _onFilterChanged(CatalogFilterChanged event, Emitter<CatalogState> emit) async {
    final current = state;
    if (current is! CatalogLoaded) return;

    final result = await _browseProducts(
      BrowseProductsParams(page: 0, pageSize: _pageSize, query: current.query, filter: event.filter),
    );
    result.when(
      success: (paged) => emit(current.copyWith(
        items: paged.items,
        page: 0,
        hasMore: paged.hasMore,
        filter: event.filter,
      )),
      failure: (f) => emit(CatalogError(f.message)),
    );
  }
}
