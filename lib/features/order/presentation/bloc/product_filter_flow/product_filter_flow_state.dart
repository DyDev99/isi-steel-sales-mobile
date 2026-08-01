import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/category.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/filter/category_filter_schema.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/filter/filter_option.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/filter/filter_selection.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/filter/filter_step.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product_filter.dart';

/// Which screen of the configurator the rep is on. Derived from the state
/// rather than stored, so the two can never disagree.
enum FilterFlowStage { categories, steps, products }

enum FilterFlowStatus { initial, loading, ready, failure }

/// Lifecycle of the *product list only* — kept separate from
/// [FilterFlowStatus] so loading a page of results never makes the filter
/// summary or the answered steps flicker.
enum ProductListStatus { idle, loading, loaded, loadingMore, failure }

/// The complete guided-selection flow as one immutable value.
///
/// Every widget in the flow renders a projection of this and owns no state of
/// its own — including the "which step am I on" question, which is answered by
/// [activeStep] rather than by a PageController or a local index. That is what
/// makes back-navigation, chip removal and process death all behave the same:
/// they are each just a different [FilterSelection].
class ProductFilterFlowState extends Equatable {
  const ProductFilterFlowState({
    this.status = FilterFlowStatus.initial,
    this.errorMessage,
    this.categories = const [],
    this.category,
    this.schema,
    this.selection = const FilterSelection.empty(),
    this.skippedStepKeys = const {},
    this.activeStep,
    this.activeOptions = const [],
    this.optionsLoading = false,
    this.products = const [],
    this.productStatus = ProductListStatus.idle,
    this.page = 0,
    this.hasMore = false,
    this.query = '',
    this.sortBy = ProductSortBy.relevance,
    this.availableOnly = false,
  });

  final FilterFlowStatus status;
  final String? errorMessage;

  final List<Category> categories;
  final Category? category;
  final CategoryFilterSchema? schema;

  final FilterSelection selection;

  /// Steps that resolved to zero options for the current selection and were
  /// therefore passed over. Tracked so the flow doesn't re-offer them and so
  /// "back" can step over them in the same order it stepped forward.
  final Set<String> skippedStepKeys;

  /// The step being asked right now; null once every step is answered.
  final FilterStep? activeStep;
  final List<FilterOption> activeOptions;
  final bool optionsLoading;

  final List<Product> products;
  final ProductListStatus productStatus;
  final int page;
  final bool hasMore;

  /// Free-text search. Unlike the guided steps this is available at every
  /// stage: an experienced rep who already knows the material code should not
  /// have to walk a hierarchy to reach it.
  final String query;

  /// Result-set preferences set from the Filter sheet. They re-run the product
  /// query but never invalidate a [selection].
  final ProductSortBy sortBy;
  final bool availableOnly;

  /// A query long enough to be worth a catalog round-trip. One character
  /// matches most of the catalog, which is the unbounded read this flow exists
  /// to prevent.
  static const minQueryLength = 2;

  bool get hasSearch => query.trim().length >= minQueryLength;

  FilterFlowStage get stage {
    // An explicit search outranks the hierarchy: the rep has told us exactly
    // what they want, so show results wherever they were in the flow.
    if (hasSearch) return FilterFlowStage.products;
    if (category == null) return FilterFlowStage.categories;
    // "No active step" only means the flow is finished once we actually know
    // what the steps are. While the schema or an option list is in flight
    // there is no active step *yet*, and treating that as completion would
    // flash the product stage — and, worse, satisfy [isFilterComplete].
    if (activeStep != null || optionsLoading || schema == null) {
      return FilterFlowStage.steps;
    }
    return FilterFlowStage.products;
  }

  /// True once every required step is answered — the only condition under which
  /// products may be requested.
  bool get isFilterComplete => stage == FilterFlowStage.products;

  /// 1-based position of the active step, for "Step 2 of 5".
  int get activeStepNumber {
    final current = activeStep;
    final steps = schema?.steps;
    if (current == null || steps == null) return 0;
    return steps.indexOf(current) + 1;
  }

  int get totalSteps => schema?.steps.length ?? 0;

  /// Whether there is anywhere to go back to from here.
  bool get canGoBack => category != null;

  ProductFilterFlowState copyWith({
    FilterFlowStatus? status,
    String? Function()? errorMessage,
    List<Category>? categories,
    Category? Function()? category,
    CategoryFilterSchema? Function()? schema,
    FilterSelection? selection,
    Set<String>? skippedStepKeys,
    FilterStep? Function()? activeStep,
    List<FilterOption>? activeOptions,
    bool? optionsLoading,
    List<Product>? products,
    ProductListStatus? productStatus,
    int? page,
    bool? hasMore,
    String? query,
    ProductSortBy? sortBy,
    bool? availableOnly,
  }) {
    return ProductFilterFlowState(
      status: status ?? this.status,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      categories: categories ?? this.categories,
      category: category != null ? category() : this.category,
      schema: schema != null ? schema() : this.schema,
      selection: selection ?? this.selection,
      skippedStepKeys: skippedStepKeys ?? this.skippedStepKeys,
      activeStep: activeStep != null ? activeStep() : this.activeStep,
      activeOptions: activeOptions ?? this.activeOptions,
      optionsLoading: optionsLoading ?? this.optionsLoading,
      products: products ?? this.products,
      productStatus: productStatus ?? this.productStatus,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      query: query ?? this.query,
      sortBy: sortBy ?? this.sortBy,
      availableOnly: availableOnly ?? this.availableOnly,
    );
  }

  /// The catalog query the current state resolves to — one place, so the
  /// guided path and the direct-search path can never drift apart.
  ProductFilter get productFilter => selection.toProductFilter(
        category?.id,
        sortBy: sortBy,
        availableOnly: availableOnly,
      );

  /// Anything the rep can clear from the Filter sheet.
  bool get hasAnyFilter =>
      category != null ||
      selection.isNotEmpty ||
      query.isNotEmpty ||
      availableOnly ||
      sortBy != ProductSortBy.relevance;

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        categories,
        category,
        schema,
        selection,
        skippedStepKeys,
        activeStep,
        activeOptions,
        optionsLoading,
        products,
        productStatus,
        page,
        hasMore,
        query,
        sortBy,
        availableOnly,
      ];
}
