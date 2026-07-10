import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/revenue/data/datasources/local/revenue_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/customer_credit.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/discount_option.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/product_category.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/repositories/revenue_repository.dart';

class RevenueRepositoryImpl implements RevenueRepository {
  const RevenueRepositoryImpl(this._localDataSource);
  final RevenueLocalDataSource _localDataSource;

  @override
  ResultFuture<List<Product>> getProducts() async {
    try {
      return Success(await _localDataSource.getProducts());
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<List<ProductCategory>> getCategories() async {
    try {
      return Success(await _localDataSource.getCategories());
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<List<DiscountOption>> getDiscountOptions() async {
    try {
      return Success(await _localDataSource.getDiscountOptions());
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<CustomerCredit> getCustomerCredit() async {
    try {
      return Success(await _localDataSource.getCustomerCredit());
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }
}
