import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_status.dart';

enum CustomerSortBy { recentOrder, nameAsc, nearest, valueDesc }

class CustomerFilter extends Equatable {
  const CustomerFilter({
    this.territory,
    this.status,
    this.productCategory,
    this.sortBy = CustomerSortBy.recentOrder,
  });

  final String? territory;
  final CustomerStatus? status;
  final String? productCategory;
  final CustomerSortBy sortBy;

  bool get isEmpty =>
      territory == null && status == null && productCategory == null;

  CustomerFilter copyWith({
    String? Function()? territory,
    CustomerStatus? Function()? status,
    String? Function()? productCategory,
    CustomerSortBy? sortBy,
  }) {
    return CustomerFilter(
      territory: territory != null ? territory() : this.territory,
      status: status != null ? status() : this.status,
      productCategory:
          productCategory != null ? productCategory() : this.productCategory,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  List<Object?> get props => [territory, status, productCategory, sortBy];
}
