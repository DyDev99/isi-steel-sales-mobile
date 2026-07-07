import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/customer_credit.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/discount_option.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/product_category.dart';

/// Data contract for the Revenue feature. Implementations back this with
/// mock data only — no real API/SAP integration yet.
abstract interface class RevenueRepository {
  ResultFuture<List<Product>> getProducts();
  ResultFuture<List<ProductCategory>> getCategories();
  ResultFuture<List<DiscountOption>> getDiscountOptions();
  ResultFuture<CustomerCredit> getCustomerCredit();
}
