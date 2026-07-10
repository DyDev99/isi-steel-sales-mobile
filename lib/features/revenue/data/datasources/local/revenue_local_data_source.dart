import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/features/revenue/data/mock/revenue_mock_data.dart';
import 'package:isi_steel_sales_mobile/features/revenue/data/models/category_model.dart';
import 'package:isi_steel_sales_mobile/features/revenue/data/models/customer_credit_model.dart';
import 'package:isi_steel_sales_mobile/features/revenue/data/models/discount_option_model.dart';
import 'package:isi_steel_sales_mobile/features/revenue/data/models/product_model.dart';

abstract interface class RevenueLocalDataSource {
  Future<List<ProductModel>> getProducts();
  Future<List<CategoryModel>> getCategories();
  Future<List<DiscountOptionModel>> getDiscountOptions();
  Future<CustomerCreditModel> getCustomerCredit();
}

/// UI-only implementation backed entirely by [RevenueMockData] — no real
/// cache/database behind it yet. Throws [CacheException] on any read
/// failure so [RevenueRepositoryImpl] can translate it into a [Failure]
/// the same way a real data source would.
class RevenueMockLocalDataSource implements RevenueLocalDataSource {
  const RevenueMockLocalDataSource();

  static const _simulatedLatency = Duration(milliseconds: 350);

  @override
  Future<List<ProductModel>> getProducts() async {
    await Future.delayed(_simulatedLatency);
    try {
      return RevenueMockData.products.map(ProductModel.fromJson).toList();
    } catch (_) {
      throw const CacheException(message: 'Unable to load products.');
    }
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    await Future.delayed(_simulatedLatency);
    try {
      return RevenueMockData.categories.map(CategoryModel.fromJson).toList();
    } catch (_) {
      throw const CacheException(message: 'Unable to load categories.');
    }
  }

  @override
  Future<List<DiscountOptionModel>> getDiscountOptions() async {
    await Future.delayed(_simulatedLatency);
    try {
      return RevenueMockData.discountOptions
          .map(DiscountOptionModel.fromJson)
          .toList();
    } catch (_) {
      throw const CacheException(message: 'Unable to load discount options.');
    }
  }

  @override
  Future<CustomerCreditModel> getCustomerCredit() async {
    await Future.delayed(_simulatedLatency);
    try {
      return CustomerCreditModel.fromJson(RevenueMockData.customerCredit);
    } catch (_) {
      throw const CacheException(message: 'Unable to load customer credit.');
    }
  }
}
