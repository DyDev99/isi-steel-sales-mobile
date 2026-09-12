import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/mobile_price.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/pricing_repository.dart';

class CustomerPricesParams extends Equatable {
  const CustomerPricesParams({
    required this.customerId,
    required this.materials,
  });

  final String customerId;

  /// SAP material numbers. Batched into one request via the endpoint's
  /// repeatable `materials` parameter.
  final List<String> materials;

  @override
  List<Object?> get props => [customerId, materials];
}

/// What this customer pays for these materials, according to the backend.
class GetCustomerMaterialPrices
    extends UseCase<List<MobilePrice>, CustomerPricesParams> {
  const GetCustomerMaterialPrices(this._repository);
  final PricingRepository _repository;

  @override
  ResultFuture<List<MobilePrice>> call(CustomerPricesParams params) =>
      _repository.getPrices(
        customerId: params.customerId,
        materials: params.materials,
      );
}
