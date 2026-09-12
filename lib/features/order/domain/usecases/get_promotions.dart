import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/promotion/promotion.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/promotion_repository.dart';

class GetPromotionsParams extends Equatable {
  const GetPromotionsParams({this.customerId, this.includeUpcoming = false});

  final String? customerId;
  final bool includeUpcoming;

  @override
  List<Object?> get props => [customerId, includeUpcoming];
}

/// Promotions worth showing, for the dashboard strip and the promotions page.
class GetPromotions extends UseCase<List<Promotion>, GetPromotionsParams> {
  const GetPromotions(this._repository);
  final PromotionRepository _repository;

  @override
  ResultFuture<List<Promotion>> call(GetPromotionsParams params) =>
      _repository.getPromotions(
        customerId: params.customerId,
        includeUpcoming: params.includeUpcoming,
      );
}
