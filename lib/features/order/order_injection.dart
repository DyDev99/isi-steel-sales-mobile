import 'package:get_it/get_it.dart';
import 'package:isi_steel_sales_mobile/core/network/network_info.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/cart_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/catalog_database.dart';
import 'package:isi_steel_sales_mobile/features/order/data/local/product_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/remote/mock_product_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/remote/product_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/order/data/repositories/cart_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/order/data/repositories/category_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/order/data/repositories/product_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/order/data/repositories/sync_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/order/data/services/mock_mto_pricing_service.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/cart_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/category_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/product_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/repositories/sync_repository.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/barcode_scanner_service.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/image_search_service.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/mto_pricing_service.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/voice_search_service.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/add_to_cart.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/browse_products.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/checkout_cart.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/clear_cart.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/fetch_brands.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/fetch_cart.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/fetch_categories.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/fetch_favorites.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/fetch_pending_orders.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/fetch_recent_products.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_last_synced_at.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_pricing.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_product_by_barcode.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_product_by_id.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_product_variants.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_products_by_category.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/get_warehouse_stock.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/record_viewed.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/remove_from_cart.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/request_mto_quote.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/run_delta_sync.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/run_initial_sync.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/toggle_favorite.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/usecases/update_cart_item.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog_bloc.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/product_detail_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/services/image_picker_search_service.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/services/mobile_barcode_scanner_service.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/services/speech_voice_search_service.dart';

/// Registers the product catalog + cart + sync engine that live inside the
/// Orders feature. Async because it opens the sqflite database once before
/// anything else can be registered against it — `main()` already awaits
/// `initDependencies()`, so this just extends that same await chain.
Future<void> registerOrderFeature(GetIt sl) async {
  final catalogDb = await CatalogDatabase.open();
  sl.registerLazySingleton<CatalogDatabase>(() => catalogDb);

  // ── Data sources ────────────────────────────────────────────────────
  sl.registerLazySingleton<ProductLocalDataSource>(() => ProductLocalDataSourceImpl(sl()));
  sl.registerLazySingleton<CartLocalDataSource>(() => CartLocalDataSourceImpl(sl()));
  sl.registerLazySingleton<ProductRemoteDataSource>(() => MockProductRemoteDataSource());

  // ── Services ────────────────────────────────────────────────────────
  sl.registerLazySingleton<BarcodeScannerService>(() => const MobileBarcodeScannerService());
  sl.registerLazySingleton<VoiceSearchService>(() => const SpeechVoiceSearchService());
  sl.registerLazySingleton<ImageSearchService>(() => const ImagePickerSearchService());
  sl.registerLazySingleton<MtoPricingService>(() => MockMtoPricingService(sl()));

  // ── Repositories ────────────────────────────────────────────────────
  sl.registerLazySingleton<ProductRepository>(() => ProductRepositoryImpl(sl()));
  sl.registerLazySingleton<CategoryRepository>(() => CategoryRepositoryImpl(sl()));
  sl.registerLazySingleton<CartRepository>(() => CartRepositoryImpl(cartLocal: sl(), productLocal: sl()));
  sl.registerLazySingleton<SyncRepository>(
    () => SyncRepositoryImpl(remote: sl(), local: sl(), network: sl<NetworkInfo>()),
  );

  // ── Use cases ───────────────────────────────────────────────────────
  sl.registerLazySingleton(() => BrowseProducts(sl()));
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
  sl.registerLazySingleton(() => CheckoutCart(sl()));
  sl.registerLazySingleton(() => FetchPendingOrders(sl()));

  sl.registerLazySingleton(() => RunInitialSync(sl()));
  sl.registerLazySingleton(() => RunDeltaSync(sl()));
  sl.registerLazySingleton(() => GetLastSyncedAt(sl()));

  // ── Presentation ────────────────────────────────────────────────────
  sl.registerFactory(() => CatalogBloc(browseProducts: sl(), fetchBrands: sl()));
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
        checkoutCart: sl(),
      ));
  sl.registerFactory(() => SyncCubit(
        runInitialSync: sl(),
        runDeltaSync: sl(),
        getLastSyncedAt: sl(),
        sessionManager: sl<SessionManager>(),
      ));
}
