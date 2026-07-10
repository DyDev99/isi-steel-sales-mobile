import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/price_tier.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/promotion_type.dart';

/// All standard-pricing tiers for one SKU, plus whatever promotion is
/// currently attached to it. Made-to-order pricing never lives here — see
/// [MtoPricingService].
class ProductPricing extends Equatable {
  const ProductPricing({
    required this.costPrice,
    required this.standardPrice,
    required this.wholesalePrice,
    required this.dealerPrice,
    required this.vipPrice,
    required this.creditPrice,
    required this.cashPrice,
    required this.currency,
    this.promotionPrice,
    this.promotionType,
    this.promotionLabel,
  });

  final double costPrice;
  final double standardPrice;
  final double wholesalePrice;
  final double dealerPrice;
  final double vipPrice;
  final double creditPrice;
  final double cashPrice;
  final String currency;

  final double? promotionPrice;
  final PromotionType? promotionType;
  final String? promotionLabel;

  bool get hasPromotion =>
      promotionPrice != null && promotionPrice! < standardPrice;

  double priceFor(PriceTier tier) => switch (tier) {
        PriceTier.standard => standardPrice,
        PriceTier.wholesale => wholesalePrice,
        PriceTier.dealer => dealerPrice,
        PriceTier.vip => vipPrice,
        PriceTier.credit => creditPrice,
        PriceTier.cash => cashPrice,
      };

  double effectivePrice([PriceTier tier = PriceTier.standard]) =>
      hasPromotion ? promotionPrice! : priceFor(tier);

  @override
  List<Object?> get props => [
        costPrice,
        standardPrice,
        wholesalePrice,
        dealerPrice,
        vipPrice,
        creditPrice,
        cashPrice,
        currency,
        promotionPrice,
        promotionType,
        promotionLabel,
      ];
}
