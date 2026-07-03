import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_filter.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/browse_customers.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/customer_params.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/fetch_recent_customers.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/toggle_favorite_customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customers_event.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customers_state.dart';

const _pageSize = 30;

/// Paginated customer directory — never loads the whole book into memory,
/// only the visible pages. Search is debounced + `restartable()` so fast
/// typing never races two in-flight queries (same shape as `CatalogBloc`).
class CustomersBloc extends Bloc<CustomersEvent, CustomersState> {
  CustomersBloc({
    required BrowseCustomers browseCustomers,
    required FetchRecentCustomers fetchRecentCustomers,
    required ToggleFavoriteCustomer toggleFavoriteCustomer,
  })  : _browseCustomers = browseCustomers,
        _fetchRecentCustomers = fetchRecentCustomers,
        _toggleFavoriteCustomer = toggleFavoriteCustomer,
        super(const CustomersInitial()) {
    on<CustomersLoadRequested>(_onLoad, transformer: droppable());
    on<CustomersRefreshRequested>(_onRefresh, transformer: droppable());
    on<CustomersLoadMoreRequested>(_onLoadMore, transformer: droppable());
    on<CustomersSearchChanged>(_onSearchChanged, transformer: restartable());
    on<CustomersFilterChanged>(_onFilterChanged, transformer: restartable());
    on<CustomersFavoriteToggled>(_onFavoriteToggled, transformer: sequential());
  }

  final BrowseCustomers _browseCustomers;
  final FetchRecentCustomers _fetchRecentCustomers;
  final ToggleFavoriteCustomer _toggleFavoriteCustomer;

  Future<void> _onLoad(CustomersLoadRequested event, Emitter<CustomersState> emit) async {
    emit(const CustomersLoading());

    final recentResult = await _fetchRecentCustomers(const NoParams());
    final recent = recentResult.when(success: (r) => r, failure: (_) => const <Customer>[]);

    final result = await _browseCustomers(const BrowseCustomersParams(page: 0, pageSize: _pageSize));
    result.when(
      success: (paged) => emit(CustomersLoaded(
        items: paged.items,
        page: 0,
        hasMore: paged.hasMore,
        isLoadingMore: false,
        query: '',
        filter: const CustomerFilter(),
        recent: recent,
        favoriteIds: const {},
      )),
      failure: (f) => emit(CustomersError(f.message)),
    );
  }

  Future<void> _onRefresh(CustomersRefreshRequested event, Emitter<CustomersState> emit) async {
    final current = state;
    if (current is! CustomersLoaded) return _onLoad(const CustomersLoadRequested(), emit);

    final result = await _browseCustomers(
      BrowseCustomersParams(page: 0, pageSize: _pageSize, query: current.query, filter: current.filter),
    );
    result.when(
      success: (paged) => emit(current.copyWith(items: paged.items, page: 0, hasMore: paged.hasMore)),
      failure: (_) => null,
    );
  }

  Future<void> _onLoadMore(CustomersLoadMoreRequested event, Emitter<CustomersState> emit) async {
    final current = state;
    if (current is! CustomersLoaded || !current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));
    final nextPage = current.page + 1;
    final result = await _browseCustomers(
      BrowseCustomersParams(page: nextPage, pageSize: _pageSize, query: current.query, filter: current.filter),
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

  Future<void> _onSearchChanged(CustomersSearchChanged event, Emitter<CustomersState> emit) async {
    final current = state;
    if (current is! CustomersLoaded) return;

    await Future<void>.delayed(const Duration(milliseconds: 300));
    final result = await _browseCustomers(
      BrowseCustomersParams(page: 0, pageSize: _pageSize, query: event.query, filter: current.filter),
    );
    result.when(
      success: (paged) => emit(current.copyWith(
        items: paged.items,
        page: 0,
        hasMore: paged.hasMore,
        query: event.query,
      )),
      failure: (f) => emit(CustomersError(f.message)),
    );
  }

  Future<void> _onFilterChanged(CustomersFilterChanged event, Emitter<CustomersState> emit) async {
    final current = state;
    if (current is! CustomersLoaded) return;

    final result = await _browseCustomers(
      BrowseCustomersParams(page: 0, pageSize: _pageSize, query: current.query, filter: event.filter),
    );
    result.when(
      success: (paged) => emit(current.copyWith(
        items: paged.items,
        page: 0,
        hasMore: paged.hasMore,
        filter: event.filter,
      )),
      failure: (f) => emit(CustomersError(f.message)),
    );
  }

  Future<void> _onFavoriteToggled(CustomersFavoriteToggled event, Emitter<CustomersState> emit) async {
    final current = state;
    if (current is! CustomersLoaded) return;

    final favorites = Set<String>.from(current.favoriteIds);
    if (!favorites.add(event.customerId)) favorites.remove(event.customerId);
    emit(current.copyWith(favoriteIds: favorites));

    await _toggleFavoriteCustomer(CustomerIdParams(event.customerId));
  }
}
