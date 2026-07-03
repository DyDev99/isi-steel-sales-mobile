import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_activity.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_filter.dart';

class CustomerIdParams extends Equatable {
  const CustomerIdParams(this.customerId);
  final String customerId;
  @override
  List<Object?> get props => [customerId];
}

class BrowseCustomersParams extends Equatable {
  const BrowseCustomersParams({
    required this.page,
    required this.pageSize,
    this.query = '',
    this.filter = const CustomerFilter(),
  });

  final int page;
  final int pageSize;
  final String query;
  final CustomerFilter filter;

  @override
  List<Object?> get props => [page, pageSize, query, filter];
}

class AddCustomerNoteParams extends Equatable {
  const AddCustomerNoteParams({required this.customerId, required this.body});
  final String customerId;
  final String body;
  @override
  List<Object?> get props => [customerId, body];
}

class AddCustomerActivityParams extends Equatable {
  const AddCustomerActivityParams(this.activity);
  final CustomerActivity activity;
  @override
  List<Object?> get props => [activity];
}
