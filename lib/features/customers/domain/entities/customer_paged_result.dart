import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';

class CustomerPagedResult extends Equatable {
  const CustomerPagedResult({required this.items, required this.page, required this.hasMore});

  final List<Customer> items;
  final int page;
  final bool hasMore;

  @override
  List<Object?> get props => [items, page, hasMore];
}
