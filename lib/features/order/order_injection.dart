import 'package:get_it/get_it.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/app_database.dart';
import 'package:isi_steel_sales_mobile/core/logging/app_logger.dart';
import 'package:isi_steel_sales_mobile/core/services/pdf/pdf_file_service.dart';
import 'package:isi_steel_sales_mobile/core/services/pdf/pdf_service.dart';
import 'package:isi_steel_sales_mobile/core/services/pdf/pdf_share_service.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/pdf/pdf_generation_cubit.dart';
import 'package:isi_steel_sales_mobile/core/database/hive/hive_service.dart';
import 'package:isi_steel_sales_mobile/core/network/network_info.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/cart_drift_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/cart_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/catalog_database.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/catalog_filter_store.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/product_drift_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/product_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/quotation_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/sync_queue_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/sales_order_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/remote/mock_product_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/remote/product_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/repositories/cart_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/order/data/repositories/category_repository_impl.dart';
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
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/product_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/quotation_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/sales_order_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/sync_queue_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/sync_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/barcode_scanner_service.dart';
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
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/fetch_recent_products.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_credit_summary.dart';
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
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/watch_quotations.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/watch_sales_orders.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/catalog_bloc.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/product_detail_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync/continue_work_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync/pending_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/services/geolocator_order_location_service.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/services/image_picker_search_service.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/services/speech_voice_search_service.dart';

/// Registers the product catalog + quotation/sales-order + sync engine that
/// live inside the Orders feature. Async because it opens the sqflite
/// database once before anything else can be registered against it —
/// `main()` already awaits `initDependencies()`, so this just extends that
/// same await chain.
Future<void> registerOrderFeature(GetIt sl) async {
  final catalogDb = await CatalogDatabase.open();
  sl.registerLazySingleton<CatalogDatabase>(() => catalogDb);

  // ── Data sources ────────────────────────────────────────────────────
  // Products/prices/stock live in the single encrypted Drift DB (T4 cutover);
  // cart/quotation/sales-order/sync-queue still use `catalogDb` (own slice).
  sl.registerLazySingleton<ProductLocalDataSource>(
      () => ProductDriftLocalDataSource(sl<AppDatabase>().catalogDao));
  sl.registerLazySingleton<CartLocalDataSource>(
      () => CartDriftLocalDataSource(sl<AppDatabase>().cartDao));
  sl.registerLazySingleton<QuotationLocalDataSource>(
      () => QuotationLocalDataSourceImpl(sl()));
  sl.registerLazySingleton<SalesOrderLocalDataSource>(
      () => SalesOrderLocalDataSourceImpl(sl()));
  sl.registerLazySingleton<ProductRemoteDataSource>(
      () => MockProductRemoteDataSource());
  sl.registerLazySingleton<CatalogFilterStore>(
      () => CatalogFilterStore(HiveService.cacheBox));
  sl.registerLazySingleton<SyncQueueLocalDataSource>(
      () => SyncQueueLocalDataSourceImpl(sl()));

  // ── Services ────────────────────────────────────────────────────────

  sl.registerLazySingleton<VoiceSearchService>(
      () => const SpeechVoiceSearchService());
  sl.registerLazySingleton<ImageSearchService>(
      () => const ImagePickerSearchService());
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

  sl.registerLazySingleton(() => FetchCart(sl()));
  sl.registerLazySingleton(() => AddToCart(sl()));
  sl.registerLazySingleton(() => UpdateCartItem(sl()));
  sl.registerLazySingleton(() => RemoveFromCart(sl()));
  sl.registerLazySingleton(() => ClearCart(sl()));
  sl.registerLazySingleton(() => ReplaceCart(sl()));

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
        sessionManager: sl<SessionManager>(),
      ));
  sl.registerFactory(() => PendingSyncCubit(repository: sl(), processor: sl()));
  sl.registerFactory(() => ContinueWorkCubit(
        watchQuotations: sl(),
        syncQueue: sl(),
        deleteQuotation: sl(),
      ));

  // PDF export for quotation documents. Core PDF services are registered in
  // the root DI container (initDependencies) before this feature runs.
  sl.registerFactory(() => PdfGenerationCubit(
        pdfService: sl<PdfService>(),
        fileService: sl<PdfFileService>(),
        shareService: sl<PdfShareService>(),
        session: sl<SessionManager>(),
        logger: sl<AppLogger>(),
      ));
}
