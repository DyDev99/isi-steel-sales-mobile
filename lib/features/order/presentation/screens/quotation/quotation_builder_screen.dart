import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/cart_item.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/credit_summary.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/off_visit_reason.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/image_search_service.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/voice_search_service.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/fetch_favorites.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_credit_summary.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/toggle_favorite.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_state.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/sync_state.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/product_filter_flow/product_filter_flow_bloc.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/product_filter_flow/product_filter_flow_event.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/quotation/customized_product_form_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/quotation/quotation_detail_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/quotation/quotation_preview_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/sync_status_banner.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/cart_line_binding.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/guided_product_filter_view.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/cart_preview_section.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/credit_summary_card.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/quotation_bottom_bar.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/quotation_preview_section.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/back_to_home.dart';

/// Quotation builder — a guided product finder rather than a catalog dump.
///
/// Entering no longer fires a product query. The rep searches by code, or
/// picks a category and walks that category's SAP-defined filter hierarchy;
/// only then are products fetched, and the quantity stepper on each card
/// writes them straight into the cart.
///
/// Below the finder: cart preview, quotation preview, save. The header
/// discount picker is gone — per-line discounts (`CartItem.discountPercent`)
/// are unaffected and still reach the totals through the cart subtotal.
class QuotationBuilderScreen extends StatefulWidget {
  const QuotationBuilderScreen({
    super.key,
    this.customer,
    this.leadId,
    this.leadDisplayName,
    this.offVisitReason,
    this.gpsLat,
    this.gpsLng,
    this.editingQuotation,
  });

  static const routeName = 'order-quotation-builder';

  final Customer? customer;
  final String? leadId;
  final String? leadDisplayName;
  final OffVisitReason? offVisitReason;
  final double? gpsLat;
  final double? gpsLng;
  final Quotation? editingQuotation;

  @override
  State<QuotationBuilderScreen> createState() => _QuotationBuilderScreenState();
}

class _QuotationBuilderScreenState extends State<QuotationBuilderScreen> {
  Future<CreditSummary?>? _summaryFuture;

  /// Unchanged from before the discount picker was removed — it was never a
  /// property of the picker, just applied after it.
  static const double _taxRate = 0.10;

  Set<String> _favoriteIds = {};

  @override
  void initState() {
    super.initState();

    context.read<SyncCubit>().syncIfNeeded();
    _loadFavorites();

    if (widget.customer != null) {
      _summaryFuture = sl<GetCreditSummary>()(
        GetCreditSummaryParams(widget.customer!.id),
      ).then(
        (result) => result.when(success: (s) => s, failure: (_) => null),
      );
    }
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

  /// The quantity stepper on each product card is the only way a plain line
  /// enters this quotation now — there is no separate "add" step to get out of
  /// sync with.
  CartLineBinding get _cartLines => CartLineBinding(
        cart: context.read<CartCubit>(),
        leadId: widget.leadId,
        customerId: widget.customer?.id,
      );

  /// Opens the category-aware customization form, carrying the live [CartCubit]
  /// so the customized line lands in this same cart.
  void _openCustomize(Product product) {
    final cartCubit = context.read<CartCubit>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cartCubit,
          child: CustomizedProductFormScreen(
            baseProduct: product,
            leadId: widget.leadId,
            customerId: widget.customer?.id,
          ),
        ),
      ),
    );
  }

  Future<void> _saveQuotation() async {
    final quotation = await context.read<CartCubit>().saveQuotation(
          customerId: widget.customer?.id,
          shopName: widget.customer?.shopName,
          leadId: widget.leadId,
          leadDisplayName: widget.leadDisplayName,
          offVisitReason: widget.offVisitReason,
          gpsLat: widget.gpsLat,
          gpsLng: widget.gpsLng,
          editing: widget.editingQuotation,
        );

    if (!mounted) return;
    if (quotation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('orders.quotation_extra.save_failed'.tr)));
      return;
    }

    Navigator.of(context).pushReplacement(MaterialPageRoute(
      settings: const RouteSettings(name: QuotationDetailScreen.routeName),
      builder: (_) => QuotationDetailScreen(quotation: quotation),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Provided here rather than at every call site so the four navigation
    // entry points into this screen don't each have to know about the
    // configurator's bloc.
    return BlocProvider<ProductFilterFlowBloc>(
      create: (_) =>
          sl<ProductFilterFlowBloc>()..add(const FilterFlowStarted()),
      child: BlocListener<SyncCubit, SyncState>(
        // `syncIfNeeded()` fires in initState, so on a device with an empty
        // catalog the flow reads "no categories" before the pull finishes.
        // Reloading on success is what turns that into a brief empty state
        // instead of a dead end.
        listenWhen: (a, b) => b is SyncSucceeded,
        listener: (context, _) => context
            .read<ProductFilterFlowBloc>()
            .add(const FilterFlowStarted()),
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            backgroundColor: colorScheme.surface,
            elevation: 0,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            title: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    color: colorScheme.primary,
                    size: 28.sp,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    widget.customer?.shopName ??
                        widget.leadDisplayName ??
                        'orders.quotation.builder_title'.tr,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: const BackToHomeButton(),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    const SyncStatusBanner(),
                    if (widget.customer != null && _summaryFuture != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: FutureBuilder<CreditSummary?>(
                          future: _summaryFuture,
                          builder: (_, snapshot) => snapshot.data == null
                              ? const SizedBox.shrink()
                              : CreditSummaryCard(
                                  creditLimit: widget.customer!.creditLimit,
                                  summary: snapshot.data!,
                                ),
                        ),
                      ),
                    GuidedProductFilterView(
                      sticky: false,
                      favoriteIds: _favoriteIds,
                      onToggleFavorite: _toggleFavorite,
                      quantityFor: (product) => _cartLines.quantityFor(product),
                      onQuantityChanged: (product, quantity) =>
                          _cartLines.setQuantity(product, quantity),
                      lineTotalFor: (product, quantity) =>
                          _cartLines.lineTotalLabel(product, quantity),
                      onCustomize: _openCustomize,
                      onVoiceSearch: () => sl<VoiceSearchService>().listen(),
                      onImageSearch: () => sl<ImageSearchService>()
                          .matchQuery(ImageSearchSource.gallery),
                    ),
                    const SizedBox(height: 16),
                    const CartPreviewSection(),
                    BlocBuilder<CartCubit, CartState>(
                      builder: (context, cartState) {
                        final List<CartItem> cartItems = cartState is CartLoaded
                            ? cartState.items
                            : const <CartItem>[];
                        final double subtotal =
                            cartState is CartLoaded ? cartState.subtotal : 0.0;
                        final int totalItemsCount = cartItems.length;

                        // No header discount: the preset-percentage picker is
                        // gone. Per-line discounts (`CartItem.discountPercent`)
                        // are untouched and still flow through `subtotal`.
                        const double discountAmount = 0;
                        final double taxAmount = subtotal * _taxRate;
                        final double finalTotal = subtotal + taxAmount;

                        final String displayShopName =
                            widget.customer?.shopName ??
                                widget.leadDisplayName ??
                                'orders.quotation_extra.walk_in'.tr;

                        return QuotationPreviewSection(
                          shopName: displayShopName,
                          items: cartItems,
                          subtotal: subtotal,
                          discount: discountAmount,
                          tax: taxAmount,
                          total: finalTotal,
                          onEnlargeTap: totalItemsCount == 0
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => QuotationScreen(
                                        shopName: displayShopName,
                                        subtotal: subtotal,
                                        discount: discountAmount,
                                        tax: taxAmount,
                                        total: finalTotal,
                                        items: cartItems,
                                        quotationNumber:
                                            widget.editingQuotation?.id,
                                        customerPhone: widget.customer?.phone,
                                        customerAddress:
                                            widget.customer?.address,
                                      ),
                                    ),
                                  );
                                },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              QuotationBottomBar(onSave: _saveQuotation),
            ],
          ),
        ),
      ),
    );
  }
}
