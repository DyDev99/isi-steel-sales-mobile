import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_text_context.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/cart_item.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/filter/filter_option.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/filter/filter_step.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_state.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/product_filter_flow/product_filter_flow_bloc.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/product_filter_flow/product_filter_flow_event.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/product_filter_flow/product_filter_flow_state.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/cart_summary_bar.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/category_selector.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/dynamic_filter_section.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/empty_products.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/filter_chip_bar.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/filter_flow_transition.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/filter_options_sheet.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/find_new_product_button.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/loading_products.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/product_family_selector.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/product_result_grid.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/product_search_bar.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/stock_location_chips.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

/// The product finder, assembled from the flow's reusable parts.
///
/// Layout is fixed and always in this order — search + filter, active filter
/// chips, then whichever stage the flow is on, then the cart summary. The
/// header never disappears: an experienced rep types a material code from the
/// category screen and gets products; a new rep walks the hierarchy. Both are
/// first-class, neither hides the other's entry point.
///
/// One widget serves both hosts (the standalone finder screen and the
/// quotation builder's product section) because it renders nothing but a
/// projection of [ProductFilterFlowState] plus the live [CartCubit], and
/// reports intent back as events. Set [sticky] when it owns the viewport.
class GuidedProductFilterView extends StatefulWidget {
  const GuidedProductFilterView({
    super.key,
    required this.favoriteIds,
    required this.onToggleFavorite,
    required this.onQuantityChanged,
    required this.quantityFor,
    this.lineTotalFor,
    this.onCustomize,
    this.onProductTap,
    this.onVoiceSearch,
    this.onImageSearch,
    this.onCartTap,
    this.sticky = true,
  });

  final Set<String> favoriteIds;
  final ValueChanged<Product> onToggleFavorite;

  /// The single write path into the quotation. Zero means "remove this line".
  final void Function(Product product, int quantity) onQuantityChanged;

  /// Current cart quantity for a product, resolved by the host from
  /// [CartCubit] so this view never owns cart state.
  final int Function(Product product) quantityFor;

  final String Function(Product product, int quantity)? lineTotalFor;

  final ValueChanged<Product>? onCustomize;
  final ValueChanged<Product>? onProductTap;

  /// Alternative ways to produce the query. They resolve to text and feed the
  /// same search field, so voice and photo lookup stay first-class.
  final Future<String?> Function()? onVoiceSearch;
  final Future<String?> Function()? onImageSearch;

  final VoidCallback? onCartTap;

  final bool sticky;

  @override
  State<GuidedProductFilterView> createState() =>
      _GuidedProductFilterViewState();
}

class _GuidedProductFilterViewState extends State<GuidedProductFilterView> {
  /// The text field's own editing buffer, not flow state. The query that
  /// actually filters lives in [ProductFilterFlowState.query].
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ProductFilterFlowBloc get _bloc => context.read<ProductFilterFlowBloc>();

  Future<void> _applyResolvedQuery(Future<String?> Function() resolve) async {
    final query = await resolve();
    if (query == null || query.trim().isEmpty || !mounted) return;
    _searchController.text = query;
    _bloc.add(FilterProductSearchChanged(query));
  }

  Future<void> _openFilterSheet(ProductFilterFlowState state) async {
    final result = await showFilterOptionsSheet(
      context: context,
      sortBy: state.sortBy,
      availableOnly: state.availableOnly,
      selection: state.selection,
      categoryLabel: context.localizedOrNull(state.category?.name),
    );
    if (result == null || !mounted) return;

    if (result.clearAll) {
      _searchController.clear();
      _bloc.add(const FilterFlowReset());
      return;
    }
    _bloc.add(FilterPreferencesChanged(
      sortBy: result.sortBy,
      availableOnly: result.availableOnly,
    ));
    // Each cleared step is dispatched on its own so the bloc applies its own
    // dependency rules to every one of them.
    for (final stepKey in result.clearedStepKeys) {
      _bloc.add(FilterStepCleared(stepKey));
    }
  }

  void _findNewProduct() {
    _searchController.clear();
    _bloc.add(const FindNewProductRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductFilterFlowBloc, ProductFilterFlowState>(
      builder: (context, state) {
        final header = _Header(
          state: state,
          searchController: _searchController,
          onSearchChanged: (value) =>
              _bloc.add(FilterProductSearchChanged(value)),
          onFilterTap: () => _openFilterSheet(state),
          onVoiceTap: widget.onVoiceSearch == null
              ? null
              : () => _applyResolvedQuery(widget.onVoiceSearch!),
          onImageTap: widget.onImageSearch == null
              ? null
              : () => _applyResolvedQuery(widget.onImageSearch!),
          onClearStep: (key) => _bloc.add(FilterStepCleared(key)),
          onClearCategory: () => _bloc.add(const FilterFlowReset()),
          onBack: () => _bloc.add(const FilterFlowBackRequested()),
        );

        final content = _StageContent(
          state: state,
          favoriteIds: widget.favoriteIds,
          quantityFor: widget.quantityFor,
          lineTotalFor: widget.lineTotalFor,
          onQuantityChanged: widget.onQuantityChanged,
          onToggleFavorite: widget.onToggleFavorite,
          onCustomize: widget.onCustomize,
          onProductTap: widget.onProductTap,
          onFindNewProduct: _findNewProduct,
        );

        final footer = _CartFooter(
          onTap: widget.onCartTap,
          onFindNewProduct: _findNewProduct,
          showFindNew: state.stage == FilterFlowStage.products,
        );

        if (!widget.sticky) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              SizedBox(height: context.rh(14)),
              content,
              SizedBox(height: context.rh(14)),
              footer,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: header,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                child: content,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: footer,
            ),
          ],
        );
      },
    );
  }
}

// ── Persistent header ─────────────────────────────────────────────────

/// Search, filter and the active-filter trail. Never hidden, at any stage.
class _Header extends StatelessWidget {
  const _Header({
    required this.state,
    required this.searchController,
    required this.onSearchChanged,
    required this.onFilterTap,
    required this.onVoiceTap,
    required this.onImageTap,
    required this.onClearStep,
    required this.onClearCategory,
    required this.onBack,
  });

  final ProductFilterFlowState state;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterTap;
  final VoidCallback? onVoiceTap;
  final VoidCallback? onImageTap;
  final ValueChanged<String> onClearStep;
  final VoidCallback onClearCategory;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProductSearchBar(
          controller: searchController,
          onChanged: onSearchChanged,
          onFilterTap: onFilterTap,
          activeFilterCount: _activeFilterCount,
          onVoiceTap: onVoiceTap,
          onImageTap: onImageTap,
        ),
        // AnimatedSize rather than a conditional child, so the header grows
        // into the chip row instead of the content below it jumping.
        AnimatedSize(
          duration: FilterFlowTransition.duration,
          curve: FilterFlowTransition.curve,
          alignment: Alignment.topCenter,
          child: state.category == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: FilterChipBar(
                    categoryLabel: context.localized(state.category!.name),
                    selection: state.selection,
                    onClearStep: onClearStep,
                    onClearCategory: onClearCategory,
                    trailing: _BackButton(onPressed: onBack),
                  ),
                ),
        ),
      ],
    );
  }

  /// Category + answered steps + stock + non-default sort. Search is excluded:
  /// it has its own visible field, so counting it would double-report.
  int get _activeFilterCount {
    var count = state.selection.entries.length;
    if (state.category != null) count++;
    if (state.availableOnly) count++;
    if (state.sortBy.name != 'relevance') count++;
    return count;
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: 'common.back'.tr,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: colors.surfaceSoft,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.border),
          ),
          child: Icon(Icons.undo_rounded,
              size: context.rr(16), color: colors.textPrimary),
        ),
      ),
    );
  }
}

// ── Stage switcher ────────────────────────────────────────────────────

class _StageContent extends StatelessWidget {
  const _StageContent({
    required this.state,
    required this.favoriteIds,
    required this.quantityFor,
    required this.lineTotalFor,
    required this.onQuantityChanged,
    required this.onToggleFavorite,
    required this.onCustomize,
    required this.onProductTap,
    required this.onFindNewProduct,
  });

  final ProductFilterFlowState state;
  final Set<String> favoriteIds;
  final int Function(Product product) quantityFor;
  final String Function(Product product, int quantity)? lineTotalFor;
  final void Function(Product product, int quantity) onQuantityChanged;
  final ValueChanged<Product> onToggleFavorite;
  final ValueChanged<Product>? onCustomize;
  final ValueChanged<Product>? onProductTap;
  final VoidCallback onFindNewProduct;

  @override
  Widget build(BuildContext context) {
    return FilterFlowTransition(
      stageKey: _stageKey,
      child: switch (state.stage) {
        FilterFlowStage.categories => _CategoryStage(state: state),
        FilterFlowStage.steps => _StepStage(state: state),
        FilterFlowStage.products => _ProductStage(
            state: state,
            favoriteIds: favoriteIds,
            quantityFor: quantityFor,
            lineTotalFor: lineTotalFor,
            onQuantityChanged: onQuantityChanged,
            onToggleFavorite: onToggleFavorite,
            onCustomize: onCustomize,
            onProductTap: onProductTap,
            onFindNewProduct: onFindNewProduct,
          ),
      },
    );
  }

  /// Keyed on stage identity, not data: re-running the query after a keystroke
  /// must not replay the slide-in.
  Object get _stageKey => switch (state.stage) {
        FilterFlowStage.categories => 'categories',
        FilterFlowStage.steps => 'step:${state.activeStep?.key}',
        FilterFlowStage.products =>
          'products:${state.category?.code}:${state.hasSearch}',
      };
}

// ── Stage: category ───────────────────────────────────────────────────

class _CategoryStage extends StatelessWidget {
  const _CategoryStage({required this.state});
  final ProductFilterFlowState state;

  @override
  Widget build(BuildContext context) {
    if (state.status == FilterFlowStatus.loading) {
      return LoadingProducts.grid(count: 6);
    }
    if (state.status == FilterFlowStatus.failure) {
      return _FailureState(message: state.errorMessage);
    }
    if (state.categories.isEmpty) {
      return EmptyProducts.chooseCategory(
        title: 'orders.guided_filter.no_categories_title'.tr,
        message: 'orders.guided_filter.no_categories_message'.tr,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StageHeader(
          title: 'orders.guided_filter.choose_category'.tr,
          subtitle: 'orders.guided_filter.choose_category_hint'.tr,
        ),
        SizedBox(height: context.rh(12)),
        CategorySelector(
          categories: state.categories,
          selectedCategoryId: state.category?.code,
          onSelect: (category) => context
              .read<ProductFilterFlowBloc>()
              .add(FilterCategorySelected(category)),
        ),
      ],
    );
  }
}

// ── Stage: one filter step ────────────────────────────────────────────

class _StepStage extends StatelessWidget {
  const _StepStage({required this.state});
  final ProductFilterFlowState state;

  @override
  Widget build(BuildContext context) {
    final step = state.activeStep;
    if (step == null) return const SizedBox.shrink();

    final bloc = context.read<ProductFilterFlowBloc>();
    void select(FilterOption option) =>
        bloc.add(FilterStepAnswered(stepKey: step.key, option: option));

    final Widget selector;
    if (state.optionsLoading) {
      selector = step.role == FilterStepRole.family
          ? LoadingProducts.list()
          : (step.style == FilterStepStyle.grid
              ? LoadingProducts.grid()
              : LoadingProducts.chips());
    } else if (state.activeOptions.isEmpty) {
      selector = EmptyProducts.chooseFamily(
        title: 'orders.guided_filter.no_options_title'
            .trParams({'label': step.label}),
        message: 'orders.guided_filter.no_options_message'.tr,
      );
    } else if (step.role == FilterStepRole.family) {
      selector = ProductFamilySelector(
        options: state.activeOptions,
        selectedValue: state.selection.valueFor(step.key),
        countLabelBuilder: (count) =>
            'orders.guided_filter.items_count'.trParams({'count': count}),
        onSelect: select,
      );
    } else {
      selector = DynamicFilterSection(
        step: step,
        options: state.activeOptions,
        selectedValue: state.selection.valueFor(step.key),
        onSelect: select,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StageHeader(
          title: 'orders.guided_filter.select_label'
              .trParams({'label': step.label}),
          subtitle: 'orders.guided_filter.step_progress'.trParams({
            'current': state.activeStepNumber,
            'total': state.totalSteps,
          }),
        ),
        SizedBox(height: context.rh(12)),
        selector,
      ],
    );
  }
}

// ── Stage: products ───────────────────────────────────────────────────

class _ProductStage extends StatelessWidget {
  const _ProductStage({
    required this.state,
    required this.favoriteIds,
    required this.quantityFor,
    required this.lineTotalFor,
    required this.onQuantityChanged,
    required this.onToggleFavorite,
    required this.onCustomize,
    required this.onProductTap,
    required this.onFindNewProduct,
  });

  final ProductFilterFlowState state;
  final Set<String> favoriteIds;
  final int Function(Product product) quantityFor;
  final String Function(Product product, int quantity)? lineTotalFor;
  final void Function(Product product, int quantity) onQuantityChanged;
  final ValueChanged<Product> onToggleFavorite;
  final ValueChanged<Product>? onCustomize;
  final ValueChanged<Product>? onProductTap;
  final VoidCallback onFindNewProduct;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProductFilterFlowBloc>();
    final loadingFirstPage = state.productStatus == ProductListStatus.loading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _StageHeader(
                title: 'orders.guided_filter.results'.tr,
                subtitle: loadingFirstPage
                    ? null
                    : 'orders.guided_filter.results_count'
                        .trParams({'count': state.products.length}),
              ),
            ),
            FindNewProductButton.compact(context, onTap: onFindNewProduct),
          ],
        ),
        // Between the header and the results: the rep has the material, and
        // this is where they choose which plant supplies it. Renders itself
        // away when there is only one.
        if (state.hasStockLocationChoice) ...[
          SizedBox(height: context.rh(4)),
          StockLocationChips(
            options: state.stockLocations,
            selectedCode: state.stockLocationCode,
            onSelect: (code) => bloc.add(FilterStockLocationChanged(code)),
          ),
        ],
        SizedBox(height: context.rh(10)),
        if (loadingFirstPage)
          LoadingProducts.products()
        else if (state.productStatus == ProductListStatus.failure)
          _FailureState(message: state.errorMessage)
        else if (state.products.isEmpty)
          EmptyProducts.noResults(
            title: 'orders.guided_filter.no_results_title'.tr,
            message: 'orders.guided_filter.no_results_message'.tr,
            action: TextButton.icon(
              onPressed: () => bloc.add(const FilterFlowBackRequested()),
              icon: Icon(Icons.arrow_back_rounded, size: context.rr(16)),
              label: Text('orders.guided_filter.change_filters'.tr),
            ),
          )
        else ...[
          // Rebuilds on cart changes so a `+` tap is reflected on the card
          // that produced it — the stepper is the commit, so it has to show
          // the committed value, not a local echo of it.
          BlocBuilder<CartCubit, CartState>(
            builder: (context, _) => ProductResultGrid(
              products: state.products,
              favoriteIds: favoriteIds,
              quantityFor: quantityFor,
              lineTotalBuilder: lineTotalFor,
              onQuantityChanged: onQuantityChanged,
              onToggleFavorite: onToggleFavorite,
              onCustomize: onCustomize,
              onTap: onProductTap,
              specLineBuilder: _specLine,
            ),
          ),
          if (state.hasMore)
            Center(
              child: state.productStatus == ProductListStatus.loadingMore
                  ? Padding(
                      padding: EdgeInsets.all(context.rr(12)),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : TextButton(
                      onPressed: () =>
                          bloc.add(const FilterProductsLoadMoreRequested()),
                      child: Text('orders.catalog.load_more'.tr),
                    ),
            ),
        ],
      ],
    );
  }

  /// The answered filters echoed back on the card, so the rep can confirm at a
  /// glance that this row is the 0.30 mm x 3.90 m they asked for. On a direct
  /// search there are no answers, so the SKU's own size stands in.
  String _specLine(Product product) {
    if (state.selection.isEmpty) return product.size;
    return [for (final e in state.selection.entries) e.option.label]
        .join(' · ');
  }
}

// ── Footer ────────────────────────────────────────────────────────────

class _CartFooter extends StatelessWidget {
  const _CartFooter({
    required this.onTap,
    required this.onFindNewProduct,
    required this.showFindNew,
  });

  final VoidCallback? onTap;
  final VoidCallback onFindNewProduct;
  final bool showFindNew;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        final items =
            cartState is CartLoaded ? cartState.items : const <CartItem>[];
        if (items.isEmpty) return const SizedBox(width: double.infinity);

        final totalQuantity =
            items.fold<double>(0, (sum, item) => sum + item.quantity);
        final subtotal = cartState is CartLoaded ? cartState.subtotal : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CartSummaryBar(
              lineCount: items.length,
              totalQuantity: totalQuantity,
              subtotal: subtotal,
              onTap: onTap,
            ),
            // Only offered once something is in the quotation and products are
            // on screen — before that there is nothing to move on from.
            if (showFindNew) ...[
              SizedBox(height: context.rh(10)),
              FindNewProductButton(onPressed: onFindNewProduct),
            ],
          ],
        );
      },
    );
  }
}

// ── Shared bits ───────────────────────────────────────────────────────

class _StageHeader extends StatelessWidget {
  const _StageHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: context.rsp(16),
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: context.rh(3)),
          Text(
            subtitle!,
            style: TextStyle(
                color: colors.textSecondary, fontSize: context.rsp(12)),
          ),
        ],
      ],
    );
  }
}

class _FailureState extends StatelessWidget {
  const _FailureState({required this.message});
  final String? message;

  @override
  Widget build(BuildContext context) => EmptyProducts(
        icon: Icons.error_outline_rounded,
        title: 'orders.guided_filter.error_title'.tr,
        message: message,
        action: TextButton(
          onPressed: () => context
              .read<ProductFilterFlowBloc>()
              .add(const FilterFlowStarted()),
          child: Text('common.retry'.tr),
        ),
      );
}
