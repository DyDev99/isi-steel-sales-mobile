import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_filter.dart';

sealed class CustomersState extends Equatable {
  const CustomersState();
  @override
  List<Object?> get props => [];
}

final class CustomersInitial extends CustomersState {
  const CustomersInitial();
}

final class CustomersLoading extends CustomersState {
  const CustomersLoading();
}

final class CustomersLoaded extends CustomersState {
  const CustomersLoaded({
    required this.items,
    required this.page,
    required this.hasMore,
    required this.isLoadingMore,
    required this.query,
    required this.filter,
    required this.recent,
    required this.favoriteIds,
  });

  final List<Customer> items;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final String query;
  final CustomerFilter filter;
  final List<Customer> recent;
  final Set<String> favoriteIds;

  CustomersLoaded copyWith({
    List<Customer>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    String? query,
    CustomerFilter? filter,
    List<Customer>? recent,
    Set<String>? favoriteIds,
  }) {
    return CustomersLoaded(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      recent: recent ?? this.recent,
      favoriteIds: favoriteIds ?? this.favoriteIds,
    );
  }

  @override
  List<Object?> get props =>
      [items, page, hasMore, isLoadingMore, query, filter, recent, favoriteIds];
}

final class CustomersError extends CustomersState {
  const CustomersError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
