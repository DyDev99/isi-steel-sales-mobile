import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/navigation/end_visit.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/cart_item.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/credit_summary.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/off_visit_reason.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/product_material_number.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/image_search_service.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/voice_search_service.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/catalog_params.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/fetch_favorites.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_credit_summary.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/toggle_favorite.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_state.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/stock_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/sync_state.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/product_filter_flow/product_filter_flow_bloc.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/pricing/pricing_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/promotion/promotion_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/product_filter_flow/product_filter_flow_event.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/quotation/customized_product_form_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/quotation/promotion_section.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/promotions/promo_view.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/quotation/quotation_detail_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/quotation/quotation_preview_screen.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/catalog/sync_status_banner.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/cart_line_binding.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/filter_flow/guided_product_filter_view.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/cart_preview_section.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/credit_summary_card.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/manual_price_input_sheet.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/quotation_bottom_bar.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/quotation_preview_section.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/manual_discount_input_sheet.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/widgets/quotation/shipment_widget_section.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/quotation_api_entities.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/quotation/quotation_builder_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/quotation/quotation_builder_state.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/back_to_home.dart';

/// Quotation builder — a guided product finder rather than a catalog dump.
class QuotationBuilderScreen extends StatefulWidget {
  const QuotationBuilderScreen({
    super.key,
    this.customer,
    this.customerId,
    this.leadId,
    this.leadDisplayName,
    this.offVisitReason,
    this.gpsLat,
    this.gpsLng,
    this.editingQuotation,
    this.editingQuotationId,
  });

  static const routeName = 'order-quotation-builder';

  final Customer? customer;

  /// The customer this quotation is for, when only their id is known.
  ///
  /// Several entry points open the builder for a shop the rep has already
  /// chosen — the customer card's "create quotation", the checked-in visit
  /// flow, the Continue-Working resume — and have the id without having loaded
  /// the whole [Customer]. They used to pass it as [leadId], which is the only
  /// slot that existed, so everything scoped to the customer read null and
  /// behaved as though the rep were serving a walk-in.
  ///
  /// **Read it through [customerContextId], never on its own.** It is
  /// deliberately not wired into the cart or the saved quotation: those still
  /// key off [leadId] exactly as before, and changing that would rewrite how
  /// existing lines merge and how a quotation is filed.
  final String? customerId;

  final String? leadId;
  final String? leadDisplayName;
  final OffVisitReason? offVisitReason;
  final double? gpsLat;
  final double? gpsLng;
  final Quotation? editingQuotation;
  final String? editingQuotationId;

  String? get effectiveQuotationId =>
      editingQuotationId ?? editingQuotation?.id;

  /// Whose account this quotation is being built against, however the caller
  /// happened to supply it.
  ///
  /// The one place anything customer-scoped — pricing, promotions — should ask.
  /// Null means a genuine walk-in with no account, which is a real state and
  /// renders as such; it must not be conflated with "the caller only had the
  /// id", which is what reading `customer?.id` alone did.
  ///
  /// [leadId] is **not** a fallback here. A lead is an unregistered shop with
  /// no SAP account, so sending its id to `/pricing/customers/{id}` would 404
  /// and surface as "customer not found" — an error, where the honest answer is
  /// that there is nobody to price for yet.
  String? get customerContextId => customer?.id ?? customerId;

  @override
  State<QuotationBuilderScreen> createState() => _QuotationBuilderScreenState();
}

class _QuotationBuilderScreenState extends State<QuotationBuilderScreen> {
  Future<CreditSummary?>? _summaryFuture;

  static const double _taxRate = 0.10;

  Set<String> _favoriteIds = {};
  final Map<String, double> _manualPrices = {};

  // Shipment & Payment selection states
  ShipmentMethod _shipmentMethod = ShipmentMethod.pickup;
  PickupLocation? _pickupLocation = PickupLocation.factory;
  DeliveryAddressOption? _deliveryOption;
  bool _isCod = false; // COD state defaulting to 'No'
  bool _isTaxApplicable = true; // Tax state: Tax Invoice (10%) or Commercial Invoice (0%)

  final TextEditingController _newAddressController = TextEditingController();
  final TextEditingController _newPhoneController = TextEditingController();

  /// Owned here rather than looked up from `context`.
  late final StockCubit _stock = sl<StockCubit>();
  late final PricingCubit _pricing =
      sl<PricingCubit>()..setCustomer(widget.customerContextId);
  late final QuotationBuilderCubit _builderCubit = sl<QuotationBuilderCubit>();

  @override
  void initState() {
    super.initState();

    context.read<SyncCubit>().syncIfNeeded();
    _loadFavorites();

    if (widget.customerContextId != null) {
      _builderCubit.initialize(
        customerId: widget.customerContextId!,
        existingQuotationId: widget.effectiveQuotationId,
        shipmentType:
            _shipmentMethod == ShipmentMethod.pickup ? 'Pickup' : 'Delivery',
        shipTo: _deliveryOption == DeliveryAddressOption.newAddress
            ? _newAddressController.text
            : widget.customer?.address,
      );
    }

    if (widget.customer != null) {
      _summaryFuture = sl<GetCreditSummary>()(
        GetCreditSummaryParams(widget.customer!.id),
      ).then(
        (result) => result.when(success: (s) => s, failure: (_) => null),
      );
    }
  }

  @override
  void dispose() {
    _newAddressController.dispose();
    _newPhoneController.dispose();
    _stock.close();
    _pricing.close();
    _builderCubit.close();
    super.dispose();
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

  CartLineBinding get _cartLines => CartLineBinding(
        cart: context.read<CartCubit>(),
        leadId: widget.leadId,
        customerId: widget.customer?.id,
        priceResolver: (product) {
          final p = _pricing.state[product.materialNumber];
          if (p != null && p.hasAmount) return p.price;
          final manual = _manualPrices[product.id] ??
              _manualPrices[product.materialNumber];
          if (manual != null && manual > 0) return manual;
          return null;
        },
        isManualPriceResolver: (product) {
          final p = _pricing.state[product.materialNumber];
          if (p != null && p.hasAmount) return false;
          final manual = _manualPrices[product.id] ??
              _manualPrices[product.materialNumber];
          return manual != null && manual > 0;
        },
      );

  Future<void> _handleInputPrice(Product product) async {
    final p = _pricing.state[product.materialNumber];
    if (p != null && p.hasAmount) return;

    final existing = _cartLines.lineFor(product);
    final currentPrice = existing?.isManualPrice == true
        ? existing?.unitPriceOverride
        : (_manualPrices[product.id] ?? _manualPrices[product.materialNumber]);

    final entered = await showManualPriceInputSheet(
      context: context,
      product: product,
      unit: product.unit,
      currentPrice: currentPrice,
    );

    if (entered == null || !mounted) return;

    setState(() {
      if (entered > 0) {
        _manualPrices[product.id] = entered;
        _manualPrices[product.materialNumber] = entered;
      } else {
        _manualPrices.remove(product.id);
        _manualPrices.remove(product.materialNumber);
      }
    });

    await _cartLines.setManualPrice(
      product,
      entered > 0 ? entered : null,
    );
  }

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

  /// Sets a cart line's quantity.
  ///
  /// **No stock gate.** Material selection is independent of stock: a rep may
  /// put any catalogue material on a quotation, and SAP's verdict is settled
  /// later in the workflow rather than at the point of choosing.
  ///
  /// This method used to `await` a live stock read before every increase and
  /// refuse the line on `!canOrder`. Two things were wrong with that. The
  /// verdict answers about a sales area the handset frequently had not
  /// supplied, so it came back `false` for materials that were perfectly
  /// orderable; and even when it was right, "SAP has none at this plant today"
  /// is not a reason a rep cannot quote.
  ///
  /// What still runs is the binding's own validation — credit limit, missing
  /// customer — which is business logic this change does not touch.
  Future<void> _setLineQuantity(Product product, int quantity) async {
    // Still asked, still shown further down the flow — just not a gate. Held
    // for five minutes and deduplicated, so this costs nothing per tap.
    unawaited(_stock.ensure(product.materialNumber));
    await _writeLine(product, quantity);

    final bState = _builderCubit.state;
    if (bState is QuotationBuilderReady) {
      final existingLine = bState.quotation.lines
          .cast<QuotationLineItem?>()
          .firstWhere(
            (l) => l?.materialNumber == product.materialNumber,
            orElse: () => null,
          );
      if (quantity <= 0 && existingLine != null) {
        unawaited(_builderCubit.deleteLine(existingLine.id));
      } else if (existingLine != null) {
        unawaited(_builderCubit.updateLineQuantity(
          lineId: existingLine.id,
          quantity: quantity.toDouble(),
          unit: product.unit,
        ));
      } else if (quantity > 0) {
        unawaited(_builderCubit.addLine(
          materialNumber: product.materialNumber,
          quantity: quantity.toDouble(),
          unit: product.unit,
        ));
      }
    }
  }

  /// The single write into the quotation, and the only place its rejections
  /// are reported.
  Future<void> _writeLine(Product product, int quantity) async {
    final verdict = await _cartLines.setQuantity(product, quantity);
    if (verdict.isValid || !mounted) return;

    // Whatever else the binding rejects — a credit limit, a missing customer —
    // still gets said. What it no longer does is interpolate a stock figure
    // and a warehouse that were always going to come out blank.
    final key = verdict.messageKey;
    if (key == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(key.tr)));
  }

  /// The "Complete Visit" action beside Save. Ends the visit and drains the
  /// outbound queue — see [endVisitAndSync] for why the check-out is committed
  /// before the push rather than alongside it.
  void _completeVisit() {
    unawaited(endVisitAndSync(context));
  }

  Future<void> _saveQuotation() async {
    final bState = _builderCubit.state;
    final serverTotals =
        bState is QuotationBuilderReady ? bState.effectiveTotals : null;

    final cartState = context.read<CartCubit>().state;
    final double subtotal = serverTotals?.gross ??
        (cartState is CartLoaded ? cartState.subtotal : 0.0);
    final double totalDiscount = serverTotals?.discountTotal ??
        (cartState is CartLoaded ? cartState.discount : 0.0);
    final double taxAmount = serverTotals?.tax ??
        (_isTaxApplicable
            ? (subtotal - totalDiscount).clamp(0.0, double.infinity) * _taxRate
            : 0.0);
    final double finalTotal = serverTotals?.net ??
        ((subtotal - totalDiscount).clamp(0.0, double.infinity) + taxAmount);

    final quotation = await context.read<CartCubit>().saveQuotation(
          customerId: widget.customer?.id,
          shopName: widget.customer?.shopName,
          leadId: widget.leadId,
          leadDisplayName: widget.leadDisplayName,
          offVisitReason: widget.offVisitReason,
          gpsLat: widget.gpsLat,
          gpsLng: widget.gpsLng,
          editing: widget.editingQuotation,
          subtotal: subtotal,
          discount: totalDiscount,
          tax: taxAmount,
          total: finalTotal,
        );

    if (!mounted) return;
    final effectiveId = (bState is QuotationBuilderReady
            ? bState.quotation.id
            : null) ??
        quotation?.id;
    if (effectiveId == null && quotation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('orders.quotation_extra.save_failed'.tr)));
      return;
    }

    Navigator.of(context).pushReplacement(MaterialPageRoute(
      settings: const RouteSettings(name: QuotationDetailScreen.routeName),
      builder: (_) => QuotationDetailScreen(
        quotationId: effectiveId,
        quotation: quotation,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MultiBlocProvider(
      providers: [
        BlocProvider<ProductFilterFlowBloc>(
          create: (_) =>
              sl<ProductFilterFlowBloc>()..add(const FilterFlowStarted()),
        ),
        // Sits above the product list so every card and stepper below reads the
        // same per-material verdicts. `.value`, not `create` — the instance
        // belongs to the State so that `_setLineQuantity` can use it without a
        // context lookup that would search above this provider.
        BlocProvider<StockCubit>.value(value: _stock),
        // Scoped to this quotation's customer. Entitlements are per account:
        // a negotiated deal for one shop must never surface against another,
        // and a walk-in sees only unscoped promotions.
        BlocProvider<PromotionCubit>(
          create: (_) =>
              sl<PromotionCubit>()..setCustomer(widget.customerContextId),
        ),
        // Same scoping, and for a stronger reason: SAP prices a material *for
        // a customer*, so there is no such thing as this quotation's price
        // without knowing whose it is. A walk-in has no customer id, and the
        // cards say "select a customer" rather than showing a figure quoted
        // for somebody else.
        BlocProvider<PricingCubit>.value(
          value: _pricing,
        ),
        BlocProvider<QuotationBuilderCubit>.value(
          value: _builderCubit,
        ),
      ],
      child: BlocListener<SyncCubit, SyncState>(
        listenWhen: (a, b) => b is SyncSucceeded,
        listener: (context, _) {
          context.read<ProductFilterFlowBloc>().add(const FilterFlowStarted());
          // A resync can change what is sellable and from where, so the held
          // verdicts are now describing a catalog that has moved underneath
          // them. Dropping them costs a round trip on next use and avoids
          // showing a band that predates the sync.
          _stock.invalidate();
        },
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
                    size: context.rsp(28),
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
                      fontSize: context.rsp(17),
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: context.rw(16)),
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
                      customerId: widget.customer?.id,
                      leadId: widget.leadId,
                      favoriteIds: _favoriteIds,
                      onToggleFavorite: _toggleFavorite,
                      quantityFor: (product) => _cartLines.quantityFor(product),
                      onQuantityChanged: _setLineQuantity,
                      lineTotalFor: (product, quantity) =>
                          _cartLines.lineTotalLabel(product, quantity),
                      onCustomize: _openCustomize,
                      onVoiceSearch: () => sl<VoiceSearchService>().listen(),
                      onImageSearch: () => sl<ImageSearchService>()
                          .matchQuery(ImageSearchSource.gallery),
                      onInputPrice: _handleInputPrice,
                      hostManualPriceFor: (product) =>
                          _manualPrices[product.id] ??
                          _manualPrices[product.materialNumber],
                    ),
                    SizedBox(height: context.rh(16)),

                    // Shipment selection section with Cash on Delivery (COD) & Tax
                    ShipmentSelectionWidget(
                      method: _shipmentMethod,
                      pickupLocation: _pickupLocation,
                      deliveryOption: _deliveryOption,
                      isCod: _isCod,
                      isTaxApplicable: _isTaxApplicable,
                      defaultAddress: widget.customer?.address,
                      newAddressController: _newAddressController,
                      newPhoneController: _newPhoneController,
                      onMethodChanged: (method) {
                        setState(() {
                          _shipmentMethod = method;
                          if (method == ShipmentMethod.pickup) {
                            _pickupLocation ??= PickupLocation.factory;
                            _deliveryOption = null;
                          } else {
                            _deliveryOption ??=
                                DeliveryAddressOption.defaultAddress;
                            _pickupLocation = null;
                          }
                        });
                        unawaited(_builderCubit.updateHeader(
                          shipmentType: method == ShipmentMethod.pickup
                              ? 'Pickup'
                              : 'Delivery',
                          shipTo: _deliveryOption ==
                                  DeliveryAddressOption.newAddress
                              ? _newAddressController.text
                              : widget.customer?.address,
                        ));
                      },
                      onPickupLocationChanged: (location) {
                        setState(() {
                          _pickupLocation = location;
                        });
                      },
                      onDeliveryOptionChanged: (option) {
                        setState(() {
                          _deliveryOption = option;
                        });
                        if (_shipmentMethod == ShipmentMethod.delivery) {
                          unawaited(_builderCubit.updateHeader(
                            shipmentType: 'Delivery',
                            shipTo: option == DeliveryAddressOption.newAddress
                                ? _newAddressController.text
                                : widget.customer?.address,
                          ));
                        }
                      },
                      onCodChanged: (isCod) {
                        setState(() {
                          _isCod = isCod;
                        });
                      },
                      onTaxApplicableChanged: (isTaxApplicable) {
                        setState(() {
                          _isTaxApplicable = isTaxApplicable;
                        });
                      },
                    ),
                    SizedBox(height: context.rh(16)),
                    // Fed from the shipment state above, so the block
                    // re-evaluates on every change: the COD / Pickup discount
                    // is earned by collecting from the depot, and switching to
                    // Delivery must take it off the table rather than leave a
                    // rate on screen that the invoice will not honour.
                    PromotionSectionWidget(
                      customerId: widget.customerContextId,
                      terms: OrderTerms(
                        isPickup: _shipmentMethod == ShipmentMethod.pickup,
                      ),
                    ),
                    SizedBox(height: context.rh(16)),
                    const CartPreviewSection(),
                    BlocBuilder<QuotationBuilderCubit, QuotationBuilderState>(
                      builder: (context, builderState) {
                        return BlocBuilder<CartCubit, CartState>(
                          builder: (context, cartState) {
                            final List<CartItem> cartItems = cartState is CartLoaded
                                ? cartState.items
                                : const <CartItem>[];
                            final int totalItemsCount = cartItems.length;

                            final bool hasServerPreview =
                                builderState is QuotationBuilderReady;
                            final QuotationTotals? serverTotals =
                                hasServerPreview
                                    ? builderState.effectiveTotals
                                    : null;

                            // Cardinal rule: Compute nothing on client.
                            // Server-calculated totals from preview/detail endpoints.
                            final double subtotal = serverTotals?.gross ??
                                (cartState is CartLoaded
                                    ? cartState.subtotal
                                    : 0.0);
                            final double totalDiscount =
                                serverTotals?.discountTotal ??
                                    (cartState is CartLoaded
                                        ? cartState.discount
                                        : 0.0);
                            final double taxAmount = serverTotals?.tax ??
                                (_isTaxApplicable
                                    ? (subtotal - totalDiscount).clamp(
                                            0.0, double.infinity) *
                                        _taxRate
                                    : 0.0);
                            final double finalTotal = serverTotals?.net ??
                                ((subtotal - totalDiscount)
                                        .clamp(0.0, double.infinity) +
                                    taxAmount);
                            final String currency =
                                serverTotals?.currency ?? 'USD';
                            final bool isEstimate =
                                serverTotals?.isEstimate ?? false;
                            final int approvalLevel = hasServerPreview
                                ? builderState.requiredApprovalLevel
                                : 0;
                            final warnings = hasServerPreview
                                ? builderState.warnings
                                : const <QuotationWarning>[];
                            final agreements = hasServerPreview
                                ? builderState.agreements
                                : const <CustomerAgreement>[];

                            final String displayShopName =
                                widget.customer?.shopName ??
                                    widget.leadDisplayName ??
                                    'orders.quotation_extra.walk_in'.tr;

                            return QuotationPreviewSection(
                              shopName: displayShopName,
                              items: cartItems,
                              subtotal: subtotal,
                              discount: totalDiscount,
                              tax: taxAmount,
                              total: finalTotal,
                              currency: currency,
                              isEstimate: isEstimate,
                              requiredApprovalLevel: approvalLevel,
                              warnings: warnings,
                              agreements: agreements,
                              isTaxApplicable: _isTaxApplicable,
                              onEditDiscount: (item) async {
                                final double maxLimit = hasServerPreview
                                    ? builderState.manualDiscountLimit
                                    : 10.0;
                                final cartCubit = context.read<CartCubit>();
                                final double? newPercent =
                                    await showManualDiscountInputSheet(
                                  context: context,
                                  item: item,
                                  currentDiscountPercent: item.discountPercent,
                                  maxDiscountPercent: maxLimit,
                                  agreements: agreements,
                                  suggestedChips: hasServerPreview
                                      ? builderState.discountAuthority?.suggestedChips
                                      : null,
                                );
                                if (newPercent == null || !mounted) return;

                                await cartCubit.updateDiscount(
                                      item.id,
                                      newPercent,
                                    );

                                if (hasServerPreview) {
                                  final line = builderState.quotation.lines
                                      .cast<QuotationLineItem?>()
                                      .firstWhere(
                                        (l) =>
                                            l?.materialNumber ==
                                            item.product.materialNumber,
                                        orElse: () => null,
                                      );
                                  if (line != null) {
                                    await _builderCubit.setDiscounts([
                                      QuotationDiscountIntent(
                                        lineId: line.id,
                                        percent: newPercent,
                                      ),
                                    ]);
                                  }
                                }
                              },
                              onEditPrice: (item) async {
                                final p = _pricing
                                    .state[item.product.materialNumber];
                                if (p != null && p.hasAmount) return;

                                final cartCubit = context.read<CartCubit>();
                                final price = await showManualPriceInputSheet(
                                  context: context,
                                  item: item,
                                  currentPrice: item.isManualPrice
                                      ? item.unitPriceOverride
                                      : null,
                                );
                                if (price != null && mounted) {
                                  setState(() {
                                    if (price > 0) {
                                      _manualPrices[item.product.id] = price;
                                      _manualPrices[
                                          item.product.materialNumber] = price;
                                    } else {
                                      _manualPrices.remove(item.product.id);
                                      _manualPrices.remove(
                                          item.product.materialNumber);
                                    }
                                  });
                                  await cartCubit.updateUnitPrice(
                                    item.id,
                                    price > 0 ? price : null,
                                    isManualPrice: true,
                                  );
                                }
                              },
                              onEnlargeTap: totalItemsCount == 0
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => BlocProvider.value(
                                            value: context.read<CartCubit>(),
                                            child: QuotationScreen(
                                              shopName: displayShopName,
                                              subtotal: subtotal,
                                              discount: totalDiscount,
                                              tax: taxAmount,
                                              total: finalTotal,
                                              items: cartItems,
                                              isTaxApplicable: _isTaxApplicable,
                                              currency: currency,
                                              quotationNumber: hasServerPreview
                                                  ? builderState.quotation.number
                                                  : widget.effectiveQuotationId,
                                              customerPhone:
                                                  widget.customer?.phone,
                                              customerAddress:
                                                  widget.customer?.address,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                            );
                          },
                        );
                      },
                    ),
                    SizedBox(height: context.rh(16)),
                  ],
                ),
              ),
              QuotationBottomBar(
                onSave: _saveQuotation,
                backLabelKey: 'my_visits.inventory.completion.complete_visit',
                onBack: _completeVisit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
