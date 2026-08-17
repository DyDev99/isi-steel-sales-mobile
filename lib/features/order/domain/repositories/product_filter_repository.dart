import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/category.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/filter/category_filter_schema.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/filter/filter_option.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/filter/filter_selection.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/filter/filter_step.dart';

/// Drives the guided product configurator one level at a time.
///
/// Every method here answers exactly one question the rep is currently being
/// asked — "which categories?", "what comes next for Palm?", "which thicknesses
/// exist for Palm 70?" — and never more. There is deliberately no
/// "give me the whole tree" method: that would be the same unbounded download
/// this flow exists to avoid.
///
/// The *hierarchy* (which steps, in which order, under which business label) is
/// SAP-owned and arrives from the remote source. The *values* at each level are
/// resolved from the locally synced catalog, so the flow keeps working with no
/// connectivity and can never offer an option that matches nothing.
abstract interface class ProductFilterRepository {
  /// Top-level categories that open the flow. Nothing else is loaded with them.
  ResultFuture<List<Category>> getFilterCategories();

  /// The filter hierarchy SAP publishes for [categoryId]. Categories with no
  /// published schema resolve to [CategoryFilterSchema.flat].
  ResultFuture<CategoryFilterSchema> getFilterSchema(String categoryId);

  /// Distinct options for exactly [step], narrowed by every answer already in
  /// [selection]. Options that match zero products are never returned, which is
  /// what makes the flow dead-end free.
  ResultFuture<List<FilterOption>> getStepOptions({
    required CategoryFilterSchema schema,
    required FilterStep step,
    required FilterSelection selection,
  });

  /// The stock locations that still hold something matching [selection], with
  /// how many SKUs each one keeps alive.
  ///
  /// Separate from [getStepOptions] because location is not a step: the rep
  /// answers it *after* seeing the matched SKUs, to pick which plant to quote
  /// from. Same bounded facet read as every other level — a few short strings,
  /// never a product row.
  ResultFuture<List<FilterOption>> getStockLocationOptions({
    required String? categoryId,
    required FilterSelection selection,
  });
}
