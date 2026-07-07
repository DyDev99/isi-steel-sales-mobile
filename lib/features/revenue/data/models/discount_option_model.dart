import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/discount_option.dart';

class DiscountOptionModel extends DiscountOption {
  const DiscountOptionModel({
    required super.id,
    required super.label,
    required super.percentage,
    super.isDefault,
  });

  factory DiscountOptionModel.fromJson(DataMap json) => DiscountOptionModel(
        id: json['id'] as String,
        label: json['label'] as String,
        percentage: (json['percentage'] as num).toDouble(),
        isDefault: json['isDefault'] as bool? ?? false,
      );
}
