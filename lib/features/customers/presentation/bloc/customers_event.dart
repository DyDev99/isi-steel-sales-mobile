import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_filter.dart';

sealed class CustomersEvent extends Equatable {
  const CustomersEvent();
  @override
  List<Object?> get props => [];
}

final class CustomersLoadRequested extends CustomersEvent {
  const CustomersLoadRequested();
}

final class CustomersRefreshRequested extends CustomersEvent {
  const CustomersRefreshRequested();
}

final class CustomersLoadMoreRequested extends CustomersEvent {
  const CustomersLoadMoreRequested();
}

final class CustomersSearchChanged extends CustomersEvent {
  const CustomersSearchChanged(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

final class CustomersFilterChanged extends CustomersEvent {
  const CustomersFilterChanged(this.filter);
  final CustomerFilter filter;
  @override
  List<Object?> get props => [filter];
}

final class CustomersFavoriteToggled extends CustomersEvent {
  const CustomersFavoriteToggled(this.customerId);
  final String customerId;
  @override
  List<Object?> get props => [customerId];
}
