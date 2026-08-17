import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/filter/category_filter_schema.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/filter/filter_option.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/filter/filter_step.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/filter/product_attribute.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product_filter.dart';

/// One resolved answer in the guided flow: which step was answered, with which
/// option, and which catalog column that lands on.
class FilterSelectionEntry extends Equatable {
  const FilterSelectionEntry({
    required this.stepKey,
    required this.stepLabel,
    required this.attribute,
    required this.sortOrder,
    required this.option,
  });

  final String stepKey;
  final String stepLabel;
  final ProductAttribute attribute;
  final int sortOrder;
  final FilterOption option;

  @override
  List<Object?> get props => [stepKey, stepLabel, attribute, sortOrder, option];
}

/// The rep's answers so far, in step order.
///
/// Immutable: every mutation returns a new instance, so a bloc state holding
/// one can never be changed out from under a widget mid-animation.
///
/// The dependency rule lives here rather than in the bloc because it is
/// business truth, not UI behaviour: **answering or clearing a step invalidates
/// every step below it**. Picking a different Palm family cannot silently keep
/// a thickness that family never came in.
class FilterSelection extends Equatable {
  const FilterSelection(this.entries);

  const FilterSelection.empty() : entries = const [];

  /// Sorted by [FilterSelectionEntry.sortOrder]; never contains two entries for
  /// the same step.
  final List<FilterSelectionEntry> entries;

  bool get isEmpty => entries.isEmpty;
  bool get isNotEmpty => entries.isNotEmpty;

  FilterSelectionEntry? entryFor(String stepKey) {
    for (final entry in entries) {
      if (entry.stepKey == stepKey) return entry;
    }
    return null;
  }

  String? valueFor(String stepKey) => entryFor(stepKey)?.option.value;

  /// Answers [step] with [option], dropping every answer that ranked below it.
  FilterSelection select(FilterStep step, FilterOption option) {
    final kept = entries.where((e) => e.sortOrder < step.sortOrder).toList()
      ..add(FilterSelectionEntry(
        stepKey: step.key,
        stepLabel: step.label,
        attribute: step.attribute,
        sortOrder: step.sortOrder,
        option: option,
      ))
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return FilterSelection(kept);
  }

  /// Removes [stepKey]'s answer and everything that depended on it. Removing
  /// "Thickness" also drops "Length" — and, upstream, the product list.
  FilterSelection clearFrom(String stepKey) {
    final target = entryFor(stepKey);
    if (target == null) return this;
    return FilterSelection(
      entries.where((e) => e.sortOrder < target.sortOrder).toList(),
    );
  }

  /// The first required step still unanswered, or null once the flow is
  /// complete. Drives both "which selector do I render" and "may I query
  /// products yet".
  FilterStep? nextStep(CategoryFilterSchema schema) {
    for (final step in schema.steps) {
      if (!step.isRequired) continue;
      if (entryFor(step.key) == null) return step;
    }
    return null;
  }

  bool isComplete(CategoryFilterSchema schema) => nextStep(schema) == null;

  /// Collapses the answers into the catalog query the repository understands.
  /// This is the single translation point between "guided flow" and the
  /// existing [ProductFilter] the catalog has always spoken — which is why the
  /// legacy quotation/catalog query path keeps working untouched.
  ///
  /// [categoryId] is nullable so a power user's direct search — typing a
  /// material code before choosing anything — resolves through this same path
  /// rather than a second, divergent query builder.
  ///
  /// [sortBy] and [availableOnly] come from the Filter sheet rather than the
  /// guided steps: they are presentation preferences over the result set, not
  /// answers that narrow the hierarchy, so they never invalidate a selection.
  /// [warehouseCode] narrows to one stock location. It is passed in rather than
  /// answered as a step because location is chosen *after* the rep sees which
  /// SKUs matched — it refines the result set, like sort and availability, and
  /// so must never invalidate an answered step.
  ProductFilter toProductFilter(
    String? categoryId, {
    ProductSortBy sortBy = ProductSortBy.relevance,
    bool availableOnly = false,
    String? warehouseCode,
  }) {
    var filter = ProductFilter(
      categoryId: categoryId,
      sortBy: sortBy,
      availableOnly: availableOnly,
      warehouseCode: warehouseCode,
    );
    for (final entry in entries) {
      final value = entry.option.value;
      final number = entry.attribute.isNumeric ? double.tryParse(value) : null;
      filter = switch (entry.attribute) {
        ProductAttribute.family => filter.copyWith(familyId: () => value),
        // A schema that publishes location as a step still lands on the same
        // column the chip row sets, so the two can never disagree.
        ProductAttribute.warehouse =>
          filter.copyWith(warehouseCode: () => value),
        ProductAttribute.subCategory =>
          filter.copyWith(subCategory: () => value),
        ProductAttribute.brand => filter.copyWith(brand: () => value),
        ProductAttribute.size => filter.copyWith(size: () => value),
        ProductAttribute.grade => filter.copyWith(grade: () => value),
        ProductAttribute.material => filter.copyWith(material: () => value),
        ProductAttribute.length => filter.copyWith(length: () => number),
        ProductAttribute.width => filter.copyWith(width: () => number),
        ProductAttribute.height => filter.copyWith(height: () => number),
        ProductAttribute.diameter => filter.copyWith(diameter: () => number),
        ProductAttribute.thickness => filter.copyWith(thickness: () => number),
      };
    }
    return filter;
  }

  @override
  List<Object?> get props => [entries];
}
