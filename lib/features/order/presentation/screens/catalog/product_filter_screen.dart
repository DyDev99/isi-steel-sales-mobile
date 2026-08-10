import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_text_context.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/fetch_favorites.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/toggle_favorite.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/sync_state.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/product_filter_flow/product_filter_flow_bloc.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/product_filter_flow/product_filter_flow_event.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/product_filter_flow/product_filter_flow_state.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/cart_line_binding.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/guided_product_filter_view.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

/// Standalone guided product configurator.
///
/// Replaces the old "everything on one page" filter screen: no product query
/// runs until the rep has walked the category's filter hierarchy to the end.
/// The screen itself is thin — [GuidedProductFilterView] renders the flow and
/// [ProductFilterFlowBloc] owns every piece of its state.
class ProductFilterScreen extends StatefulWidget {
  const ProductFilterScreen({super.key, this.leadId, this.customerId});

  static const routeName = 'order-product-filter';

  final String? leadId;
  final String? customerId;

  static Widget provider({String? leadId, String? customerId}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (_) =>
                sl<ProductFilterFlowBloc>()..add(const FilterFlowStarted())),
        BlocProvider(create: (_) => sl<CartCubit>()..load()),
        // The finder pulls the catalog itself rather than assuming whichever
        // screen the rep arrived from already did. Entering here on a device
        // with nothing synced used to leave an empty category picker with no
        // way out.
        BlocProvider(create: (_) => sl<SyncCubit>()..syncIfNeeded()),
      ],
      child: ProductFilterScreen(leadId: leadId, customerId: customerId),
    );
  }

  @override
  State<ProductFilterScreen> createState() => _ProductFilterScreenState();
}

class _ProductFilterScreenState extends State<ProductFilterScreen> {
  Set<String> _favoriteIds = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final result = await sl<FetchFavorites>()(const NoParams());
    if (!mounted) return;
    result.when(
      success: (products) =>
          setState(() => _favoriteIds = products.map((p) => p.id).toSet()),
      failure: (_) {},
    );
  }

  Future<void> _toggleFavorite(Product product) async {
    setState(() {
      if (!_favoriteIds.add(product.id)) _favoriteIds.remove(product.id);
    });
    await sl<ToggleFavorite>()(ProductIdParams(product.id));
  }

  /// The quantity stepper on each card is the only write path into the cart —
  /// zero removes the line, so there is no separate add or delete action.
  CartLineBinding get _cartLines => CartLineBinding(
        cart: context.read<CartCubit>(),
        leadId: widget.leadId,
        customerId: widget.customerId,
      );

  /// System back retraces the flow one step at a time before leaving the
  /// screen — the rep's selections are never thrown away by a stray back tap.
  /// Returns true once there is nothing left to retrace.
  bool _stepBack() {
    final bloc = context.read<ProductFilterFlowBloc>();
    if (!bloc.state.canGoBack) return true;
    bloc.add(const FilterFlowBackRequested());
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_stepBack()) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: colors.canvas,
        appBar: AppBar(
          backgroundColor: colors.canvas,
          elevation: 0,
          iconTheme: IconThemeData(color: colors.textPrimary),
          title: BlocBuilder<ProductFilterFlowBloc, ProductFilterFlowState>(
            buildWhen: (a, b) => a.category != b.category,
            builder: (context, state) => Text(
              context.localizedOrNull(state.category?.name) ??
                  'orders.filter.title'.tr,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: context.rsp(17),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          actions: [
            BlocBuilder<ProductFilterFlowBloc, ProductFilterFlowState>(
              buildWhen: (a, b) => a.canGoBack != b.canGoBack,
              builder: (context, state) => state.canGoBack
                  ? Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextButton(
                        onPressed: () => context
                            .read<ProductFilterFlowBloc>()
                            .add(const FilterFlowReset()),
                        child: Text('common.clear_all'.tr,
                            style: TextStyle(color: colors.warning)),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        // A sync that lands after the flow has already read an empty catalog
        // has to be picked up, otherwise the rep sits on "no categories" while
        // the data they need is on the device.
        body: BlocListener<SyncCubit, SyncState>(
          listenWhen: (a, b) => b is SyncSucceeded,
          listener: (context, _) => context
              .read<ProductFilterFlowBloc>()
              .add(const FilterFlowStarted()),
          child: GuidedProductFilterView(
            favoriteIds: _favoriteIds,
            onToggleFavorite: _toggleFavorite,
            quantityFor: (product) => _cartLines.quantityFor(product),
            onQuantityChanged: (product, quantity) =>
                _cartLines.setQuantity(product, quantity),
            lineTotalFor: (product, quantity) =>
                _cartLines.lineTotalLabel(product, quantity),
          ),
        ),
      ),
    );
  }
}
