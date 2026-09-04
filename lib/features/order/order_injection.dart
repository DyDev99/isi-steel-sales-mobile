import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:isi_steel_sales_mobile/core/config/data_source_mode.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/app_database.dart';
import 'package:isi_steel_sales_mobile/core/logging/app_logger.dart';
import 'package:isi_steel_sales_mobile/core/services/pdf/pdf_file_service.dart';
import 'package:isi_steel_sales_mobile/core/services/pdf/pdf_service.dart';
import 'package:isi_steel_sales_mobile/core/services/pdf/pdf_share_service.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/pdf/pdf_generation_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sales_order/sales_order_list_cubit.dart';
import 'package:isi_steel_sales_mobile/core/database/hive/hive_service.dart';
import 'package:isi_steel_sales_mobile/core/network/network_info.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/cart_drift_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/cart_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/catalog_filter_store.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/product_drift_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/product_filter_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/product_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/quotation_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/sync_queue_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/sales_order_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/remote/mock_product_filter_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/remote/mock_product_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/remote/api_material_selection_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/remote/material_selection_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/remote/pricing_realtime_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/remote/pricing_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/remote/product_filter_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/remote/product_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/repositories/cart_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/order/data/repositories/category_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/order/data/repositories/api_product_filter_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/order/data/repositories/material_availability_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/order/data/repositories/pricing_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/order/data/repositories/product_filter_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/order/data/repositories/static_promotion_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/order/data/repositories/product_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/order/data/repositories/quotation_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/order/data/repositories/sales_order_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/order/data/repositories/sync_queue_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/order/data/repositories/sync_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/order/data/services/mock_credit_service.dart';
import 'package:isi_steel_sales_mobile/features/order/data/services/mock_quotation_sap_service.dart';
import 'package:isi_steel_sales_mobile/features/order/data/services/mock_mto_pricing_service.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/cart_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/category_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/material_availability_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/pricing_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/product_filter_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/promotion_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/product_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/quotation_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/sales_order_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/sync_queue_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/sync_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/credit_service.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/image_search_service.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/mto_pricing_service.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/order_location_service.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/quotation_sap_service.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/sync_queue_processor.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/voice_search_service.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/add_to_cart.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/browse_products.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/capture_location_once.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/clear_cart.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/count_products.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/create_sales_order.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/delete_quotation.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/fetch_brands.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/fetch_cart.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/fetch_categories.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/fetch_favorites.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/fetch_filter_categories.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/fetch_recent_products.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_category_filter_schema.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_credit_summary.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/check_material_availability.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_filter_step_options.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/evaluate_promotion.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_customer_material_prices.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_materials.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_promotions.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_stock_location_options.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_last_synced_at.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_pricing.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_product_by_barcode.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_product_by_id.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_product_variants.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_products_by_category.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_quotation_by_id.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_sales_order_by_id.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_warehouse_stock.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/record_viewed.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/remove_from_cart.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/replace_cart.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/request_mto_quote.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/run_delta_sync.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/run_initial_sync.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/save_quotation.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/toggle_favorite.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/update_cart_item.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/update_quotation.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/validate_order_line.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/watch_quotations.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/watch_sales_orders.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/catalog_bloc.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/product_detail_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/product_filter_flow/product_filter_flow_bloc.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/pricing/pricing_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/promotion/promotion_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync/continue_work_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync/pending_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/services/geolocator_order_location_service.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/services/image_picker_search_service.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/services/speech_voice_search_service.dart';
import 'package:isi_steel_sales_mobile/core/camera/image_capture_service.dart';

/// Registers the product catalog + quotation/sales-order + sync engine that
/// live inside the Orders feature.
///
/// Still `Future`-returning after the T1.5b cutover even though nothing is
/// awaited here any more: `AppDatabase` opens lazily on first use, so there is
/// no database to open up front. The signature is kept because
/// `initDependencies()` awaits every feature registrar uniformly, and churning
/// that contract for one feature buys nothing.
Future<void> registerOrderFeature(GetIt sl) async {
  // ── Data sources ────────────────────────────────────────────────────
  // T1.5b: quotations, sales orders and the sync queue moved off the plaintext
  // `catalog.db` into the single encrypted Drift database, joining
  // products/prices/stock and the cart. The Orders feature now holds no private
  // database handle at all (ADR-004).
  sl.registerLazySingleton<ProductLocalDataSource>(
      () => ProductDriftLocalDataSource(sl<AppDatabase>().catalogDao));
  sl.registerLazySingleton<CartLocalDataSource>(
      () => CartDriftLocalDataSource(sl<AppDatabase>().cartDao));
  sl.registerLazySingleton<QuotationLocalDataSource>(
      () => QuotationLocalDataSourceImpl(sl<AppDatabase>().quotationDao));
  sl.registerLazySingleton<SalesOrderLocalDataSource>(
      () => SalesOrderLocalDataSourceImpl(sl<AppDatabase>().salesOrderDao));
  sl.registerLazySingleton<ProductRemoteDataSource>(
      () => MockProductRemoteDataSource());
  sl.registerLazySingleton<ProductFilterRemoteDataSource>(
      () => MockProductFilterRemoteDataSource());
  // The guided material finder's four reads. Registered unconditionally: the
  // availability check below needs it even on the offline path, where it is
  // the only thing that can answer "may I sell this?" at all.
  sl.registerLazySingleton<PricingRemoteDataSource>(
      () => ApiPricingRemoteDataSource(sl<Dio>()));
  // TODO(release-gate): replace with a SignalR-backed source once a client
  // package is approved — no SignalR client is in pubspec today, and
  // hand-rolling the hub handshake would be a second auth mechanism the spec
  // forbids. Until then every price is REST-fetched and nothing claims to be
  // live that is not.
  sl.registerLazySingleton<PricingRealtimeSource>(
      () => DisconnectedPricingRealtimeSource());
  sl.registerLazySingleton<MaterialSelectionRemoteDataSource>(
      () => ApiMaterialSelectionRemoteDataSource(sl<Dio>()));
  sl.registerLazySingleton<ProductFilterLocalDataSource>(
      () => ProductFilterDriftLocalDataSource(sl<AppDatabase>().catalogDao));
  sl.registerLazySingleton<CatalogFilterStore>(
      () => CatalogFilterStore(HiveService.cacheBox));
  sl.registerLazySingleton<SyncQueueLocalDataSource>(
      () => SyncQueueLocalDataSourceImpl(sl<AppDatabase>().syncQueueDao));

  // ── Services ────────────────────────────────────────────────────────

  sl.registerLazySingleton<VoiceSearchService>(
      () => const SpeechVoiceSearchService());
  sl.registerLazySingleton<ImageSearchService>(
      () => ImagePickerSearchService(sl<ImageCaptureService>()));
  sl.registerLazySingleton<MtoPricingService>(
      () => MockMtoPricingService(sl()));
  sl.registerLazySingleton<CreditService>(() => const MockCreditService());
  sl.registerLazySingleton<OrderLocationService>(
      () => const GeolocatorOrderLocationService());
  sl.registerLazySingleton<QuotationSapService>(
      () => const MockQuotationSapService());

  // ── Repositories ────────────────────────────────────────────────────
  sl.registerLazySingleton<ProductRepository>(
      () => ProductRepositoryImpl(sl()));
  sl.registerLazySingleton<CategoryRepository>(
      () => CategoryRepositoryImpl(sl()));
  // The guided finder runs against the platform's material selection API, and
  // falls back to the device's synced catalog when the app is built for mocks.
  // Both satisfy the same interface, so nothing above this line knows which
  // one answered.
  sl.registerLazySingleton<ProductFilterRepository>(
    () => DataSourceMode.useLiveApi
        ? ApiProductFilterRepositoryImpl(sl())
        : ProductFilterRepositoryImpl(
            remote: sl(), local: sl(), products: sl()),
  );
  // SAP's live sellability check — the one call in this feature that reaches
  // the ERP, spent when a rep commits to a material at the SKU step.
  //
  // TODO(release-gate): the sales-area triple (salesOrg / disChannel /
  // division) is not carried by the session yet, so SAP answers every check
  // with `INPUT_*` and `isSellable: false`. That renders as "No stock", which
  // is safe — it never invents a yes — but uninformative until the rep's sales
  // area is resolved and passed here.
  // TODO(release-gate): swap for an API-backed implementation when the
  // promotions endpoint ships. Everything above `PromotionRepository` already
  // talks to the interface, so this line is the whole migration.
  sl.registerLazySingleton<PricingRepository>(
    () => PricingRepositoryImpl(remote: sl(), network: sl<NetworkInfo>()),
  );
  sl.registerLazySingleton<PromotionRepository>(
      () => const StaticPromotionRepositoryImpl());
  sl.registerLazySingleton<MaterialAvailabilityRepository>(
    () => MaterialAvailabilityRepositoryImpl(
      remote: sl(),
      network: sl<NetworkInfo>(),
    ),
  );
  sl.registerLazySingleton<CartRepository>(
      () => CartRepositoryImpl(cartLocal: sl(), productLocal: sl()));
  sl.registerLazySingleton<QuotationRepository>(
      () => QuotationRepositoryImpl(local: sl(), productLocal: sl()));
  sl.registerLazySingleton<SalesOrderRepository>(
      () => SalesOrderRepositoryImpl(local: sl(), productLocal: sl()));
  sl.registerLazySingleton<SyncRepository>(
    () => SyncRepositoryImpl(
        remote: sl(), local: sl(), network: sl<NetworkInfo>()),
  );
  sl.registerLazySingleton<SyncQueueRepository>(
      () => SyncQueueRepositoryImpl(sl()));

  // ── Sync engine (outbound SAP queue) ────────────────────────────────
  sl.registerLazySingleton<SyncQueueProcessor>(
    () => SyncQueueProcessor(
      queue: sl(),
      quotations: sl(),
      sap: sl(),
      network: sl<NetworkInfo>(),
    ),
  );

  // ── Use cases ───────────────────────────────────────────────────────
  sl.registerLazySingleton(() => BrowseProducts(sl()));
  sl.registerLazySingleton(() => CountProducts(sl()));
  sl.registerLazySingleton(() => GetProductById(sl()));
  sl.registerLazySingleton(() => GetProductByBarcode(sl()));
  sl.registerLazySingleton(() => GetProductsByCategory(sl()));
  sl.registerLazySingleton(() => GetProductVariants(sl()));
  sl.registerLazySingleton(() => GetWarehouseStock(sl()));
  sl.registerLazySingleton(() => GetPricing(sl()));
  sl.registerLazySingleton(() => FetchBrands(sl()));
  sl.registerLazySingleton(() => ToggleFavorite(sl()));
  sl.registerLazySingleton(() => FetchFavorites(sl()));
  sl.registerLazySingleton(() => FetchRecentProducts(sl()));
  sl.registerLazySingleton(() => RecordViewed(sl()));
  sl.registerLazySingleton(() => FetchCategories(sl()));
  sl.registerLazySingleton(() => RequestMtoQuote(sl()));

  // Guided product configurator: one usecase per level of the flow.
  sl.registerLazySingleton(() => FetchFilterCategories(sl()));
  sl.registerLazySingleton(() => GetCategoryFilterSchema(sl()));
  sl.registerLazySingleton(() => GetFilterStepOptions(sl()));
  sl.registerLazySingleton(() => GetStockLocationOptions(sl()));
  sl.registerLazySingleton(() => GetMaterials(sl()));
  sl.registerLazySingleton(() => CheckMaterialAvailability(sl()));
  sl.registerLazySingleton(() => GetPromotions(sl()));
  sl.registerLazySingleton(() => EvaluatePromotion(sl()));
  sl.registerLazySingleton(() => GetCustomerMaterialPrices(sl()));

  sl.registerLazySingleton(() => FetchCart(sl()));
  sl.registerLazySingleton(() => AddToCart(sl()));
  sl.registerLazySingleton(() => UpdateCartItem(sl()));
  sl.registerLazySingleton(() => RemoveFromCart(sl()));
  sl.registerLazySingleton(() => ClearCart(sl()));
  sl.registerLazySingleton(() => ReplaceCart(sl()));
  sl.registerLazySingleton(() => ValidateOrderLine(sl()));

  sl.registerLazySingleton(() => SaveQuotation(sl()));
  sl.registerLazySingleton(() => UpdateQuotation(sl()));
  sl.registerLazySingleton(() => GetQuotationById(sl()));
  sl.registerLazySingleton(() => DeleteQuotation(sl()));
  sl.registerLazySingleton(() => WatchQuotations(sl()));
  sl.registerLazySingleton(() => CreateSalesOrder(sl()));
  sl.registerLazySingleton(() => GetSalesOrderById(sl()));
  sl.registerLazySingleton(() => WatchSalesOrders(sl()));
  sl.registerLazySingleton(() => GetCreditSummary(sl()));
  sl.registerLazySingleton(() => CaptureLocationOnce(sl()));

  sl.registerLazySingleton(() => RunInitialSync(sl()));
  sl.registerLazySingleton(() => RunDeltaSync(sl()));
  sl.registerLazySingleton(() => GetLastSyncedAt(sl()));

  // ── Presentation ────────────────────────────────────────────────────
  sl.registerFactory(
      () => CatalogBloc(browseProducts: sl(), fetchBrands: sl()));
  sl.registerFactory(() => ProductFilterFlowBloc(
        fetchFilterCategories: sl(),
        getCategoryFilterSchema: sl(),
        getFilterStepOptions: sl(),
        getStockLocationOptions: sl(),
        getMaterials: sl(),
        checkMaterialAvailability: sl(),
      ));
  sl.registerFactory(() => ProductDetailCubit(
        getProductById: sl(),
        getProductVariants: sl(),
        getWarehouseStock: sl(),
        toggleFavorite: sl(),
        recordViewed: sl(),
        fetchFavorites: sl(),
      ));
  sl.registerFactory(() => CartCubit(
        fetchCart: sl(),
        addToCart: sl(),
        updateCartItem: sl(),
        removeFromCart: sl(),
        clearCart: sl(),
        replaceCart: sl(),
        saveQuotation: sl(),
        updateQuotation: sl(),
      ));
  sl.registerFactory(() => SyncCubit(
        runInitialSync: sl(),
        runDeltaSync: sl(),
        getLastSyncedAt: sl(),
        countProducts: sl(),
        sessionManager: sl<SessionManager>(),
      ));
  // A factory, not a singleton: it holds per-material debounce timers and a
  // customer scope, both of which belong to one screen's lifetime.
  sl.registerFactory(() => PromotionCubit(evaluate: sl()));
  // A factory: it owns a customer scope and hub subscription that belong to
  // one quotation's lifetime, and must be torn down with the screen.
  sl.registerFactory(() => PricingCubit(getPrices: sl(), realtime: sl()));
  sl.registerFactory(() => PendingSyncCubit(repository: sl(), processor: sl()));
  sl.registerFactory(() => ContinueWorkCubit(
        watchQuotations: sl(),
        syncQueue: sl(),
        deleteQuotation: sl(),
      ));

  // PDF export for quotation documents. Core PDF services are registered in
  // the root DI container (initDependencies) before this feature runs.
  // Read-only sales-order list, driven by the WatchSalesOrders stream. A
  // factory, not a singleton: it holds a live subscription that must be torn
  // down with the screen.
  sl.registerFactory(() => SalesOrderListCubit(watchSalesOrders: sl()));
  sl.registerFactory(() => PdfGenerationCubit(
        pdfService: sl<PdfService>(),
        fileService: sl<PdfFileService>(),
        shareService: sl<PdfShareService>(),
        session: sl<SessionManager>(),
        logger: sl<AppLogger>(),
      ));
}
