import 'package:isi_steel_sales_mobile/features/order/domain/entities/filter/category_filter_schema.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/filter/filter_step.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/filter/product_attribute.dart';

/// DTO for one level of a SAP-published filter hierarchy.
///
/// Field names mirror the wire contract, not the entity, so a change on the SAP
/// side lands here and nowhere else. Unknown `attribute`/`style`/`role` values
/// degrade gracefully rather than throwing: a rep in the field must never lose
/// the whole configurator because SAP shipped one new enum member.
class FilterStepModel {
  const FilterStepModel({
    required this.key,
    required this.label,
    required this.attribute,
    required this.sortOrder,
    required this.style,
    required this.role,
    required this.unitSuffix,
    required this.decimals,
    required this.isRequired,
  });

  final String key;
  final String label;
  final String attribute;
  final int sortOrder;
  final String style;
  final String role;
  final String? unitSuffix;
  final int? decimals;
  final bool isRequired;

  factory FilterStepModel.fromJson(Map<String, dynamic> json) {
    return FilterStepModel(
      key: json['key'] as String,
      label: json['label'] as String,
      attribute: json['attribute'] as String,
      sortOrder: (json['sortOrder'] as num).toInt(),
      style: json['style'] as String? ?? 'chips',
      role: json['role'] as String? ?? 'specification',
      unitSuffix: json['unitSuffix'] as String?,
      decimals: (json['decimals'] as num?)?.toInt(),
      isRequired: json['required'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'attribute': attribute,
        'sortOrder': sortOrder,
        'style': style,
        'role': role,
        'unitSuffix': unitSuffix,
        'decimals': decimals,
        'required': isRequired,
      };

  /// Null when [attribute] names a column this build of the app has no place to
  /// put — the step is dropped instead of poisoning the whole schema.
  FilterStep? toEntity() {
    final resolved = ProductAttribute.tryParse(attribute);
    if (resolved == null) return null;
    return FilterStep(
      key: key,
      label: label,
      attribute: resolved,
      sortOrder: sortOrder,
      style: _styleFrom(style),
      role: _roleFrom(role),
      unitSuffix: unitSuffix,
      decimals: decimals,
      isRequired: isRequired,
    );
  }

  static FilterStepStyle _styleFrom(String raw) => switch (raw.toLowerCase()) {
        'grid' => FilterStepStyle.grid,
        'list' => FilterStepStyle.list,
        _ => FilterStepStyle.chips,
      };

  static FilterStepRole _roleFrom(String raw) => switch (raw.toLowerCase()) {
        'family' => FilterStepRole.family,
        'dimension' => FilterStepRole.dimension,
        _ => FilterStepRole.specification,
      };
}

class CategoryFilterSchemaModel {
  const CategoryFilterSchemaModel({
    required this.categoryId,
    required this.categoryName,
    required this.steps,
  });

  final String categoryId;
  final String categoryName;
  final List<FilterStepModel> steps;

  factory CategoryFilterSchemaModel.fromJson(Map<String, dynamic> json) {
    return CategoryFilterSchemaModel(
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String? ?? '',
      steps: (json['steps'] as List? ?? const [])
          .map((e) => FilterStepModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'categoryName': categoryName,
        'steps': steps.map((s) => s.toJson()).toList(),
      };

  /// Sorts once, here, so every layer above can rely on `steps` being in
  /// presentation order without re-sorting.
  CategoryFilterSchema toEntity() {
    final resolved = steps
        .map((s) => s.toEntity())
        .whereType<FilterStep>()
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return CategoryFilterSchema(
      categoryId: categoryId,
      categoryName: categoryName,
      steps: resolved,
    );
  }
}
