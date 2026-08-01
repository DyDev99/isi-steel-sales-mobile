import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/product_filter_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/mock/isi_filter_schema_data.dart';
import 'package:isi_steel_sales_mobile/features/order/data/models/category_filter_schema_model.dart';
import 'package:isi_steel_sales_mobile/features/order/data/remote/product_filter_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/category.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/filter/category_filter_schema.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/filter/filter_option.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/filter/filter_selection.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/filter/filter_step.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/filter/product_attribute.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/product_filter_repository.dart';

/// Joins the two halves of the guided configurator: the SAP-published
/// hierarchy (remote) and the locally synced values that populate it (local).
///
/// Never returns a product. The whole point of this repository is that the rep
/// can walk five levels of a 100k-SKU catalog having transferred nothing but a
/// few kilobytes of option labels; product rows are the caller's separate,
/// final, paged request through [ProductRepository].
class ProductFilterRepositoryImpl implements ProductFilterRepository {
  ProductFilterRepositoryImpl({
    required ProductFilterRemoteDataSource remote,
    required ProductFilterLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final ProductFilterRemoteDataSource _remote;
  final ProductFilterLocalDataSource _local;

  Map<String, CategoryFilterSchemaModel>? _schemasById;

  @override
  ResultFuture<List<Category>> getFilterCategories() async {
    try {
      // CategoryModel already *is* a Category — widening, not mapping.
      return Success(
          List<Category>.from(await _local.categoriesWithProducts()));
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  @override
  ResultFuture<CategoryFilterSchema> getFilterSchema(String categoryId) async {
    try {
      final published = (await _loadSchemas())[categoryId];
      if (published != null) return Success(published.toEntity());

      // No bespoke hierarchy for this category — fall back to the generic one
      // the backend also publishes, rather than dropping the rep into an
      // unfiltered catalog. Its steps are all optional and the flow skips any
      // that resolve to nothing, so it adapts to whatever the category has.
      final generic = CategoryFilterSchemaModel.fromJson(
        IsiFilterSchemaData.genericSchemaFor(
          categoryId: categoryId,
          categoryName: '',
        ),
      );
      return Success(generic.toEntity());
    } on ServerException catch (e) {
      return Failed(ServerFailure(message: e.message));
    }
  }

  @override
  ResultFuture<List<FilterOption>> getStepOptions({
    required CategoryFilterSchema schema,
    required FilterStep step,
    required FilterSelection selection,
  }) async {
    try {
      final values = await _local.facetValues(
        facet: _facetKey(step.attribute),
        filter: selection.toProductFilter(schema.categoryId),
      );
      return Success(values
          .map((v) => FilterOption(
                value: v.value,
                label: _label(step, v.label),
                matchCount: v.matchCount,
              ))
          .toList());
    } on CacheException catch (e) {
      return Failed(CacheFailure(message: e.message));
    }
  }

  Future<Map<String, CategoryFilterSchemaModel>> _loadSchemas() async {
    final cached = _schemasById;
    if (cached != null) return cached;
    final schemas = await _remote.fetchFilterSchemas();
    return _schemasById = {for (final s in schemas) s.categoryId: s};
  }

  /// Domain attribute → the neutral facet name the catalog DAO whitelists.
  /// Kept here (data layer) so the domain never learns a storage vocabulary.
  static String _facetKey(ProductAttribute attribute) => switch (attribute) {
        ProductAttribute.family => 'family',
        ProductAttribute.subCategory => 'subCategory',
        ProductAttribute.brand => 'brand',
        ProductAttribute.size => 'size',
        ProductAttribute.grade => 'grade',
        ProductAttribute.material => 'material',
        ProductAttribute.length => 'length',
        ProductAttribute.width => 'width',
        ProductAttribute.height => 'height',
        ProductAttribute.diameter => 'diameter',
        ProductAttribute.thickness => 'thickness',
      };

  /// Applies the step's published notation to a raw catalog value: SQLite hands
  /// back "0.3" and "12.0" where the sales sheet says "0.30 mm" and "12 mm".
  static String _label(FilterStep step, String raw) {
    if (!step.attribute.isNumeric) return raw;
    final parsed = double.tryParse(raw);
    if (parsed == null) return raw;
    final decimals = step.decimals;
    final formatted = decimals != null
        ? parsed.toStringAsFixed(decimals)
        : (parsed == parsed.roundToDouble()
            ? parsed.toStringAsFixed(0)
            : parsed.toString());
    return step.unitSuffix == null
        ? formatted
        : '$formatted ${step.unitSuffix}';
  }
}
