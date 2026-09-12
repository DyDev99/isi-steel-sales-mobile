import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/promotion/promotion_evaluation.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/promotion_repository.dart';

class EvaluatePromotionParams extends Equatable {
  const EvaluatePromotionParams({
    required this.materialCode,
    required this.categoryCode,
    required this.quantity,
    this.customerId,
  });

  final String materialCode;
  final String categoryCode;
  final int quantity;

  /// The customer the quotation is for. Null for a walk-in, which matches only
  /// unscoped promotions — a named account's negotiated deal must not leak.
  final String? customerId;

  @override
  List<Object?> get props => [materialCode, categoryCode, quantity, customerId];
}

/// What this customer earns on this material at this quantity.
///
/// The single question the product card asks, re-asked whenever the quantity
/// changes. Null means no promotion applies, and renders as nothing.
class EvaluatePromotion
    extends UseCase<PromotionEvaluation?, EvaluatePromotionParams> {
  const EvaluatePromotion(this._repository);
  final PromotionRepository _repository;

  @override
  ResultFuture<PromotionEvaluation?> call(EvaluatePromotionParams params) =>
      _repository.evaluate(
        materialCode: params.materialCode,
        categoryCode: params.categoryCode,
        quantity: params.quantity,
        customerId: params.customerId,
      );
}
