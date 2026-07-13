import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:isi_steel_sales_mobile/core/local/app_preferences.dart';
import 'package:isi_steel_sales_mobile/core/local/hive_service.dart';
import 'package:isi_steel_sales_mobile/core/network/connectivity_cubit.dart';
import 'package:isi_steel_sales_mobile/core/network/network_info.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/app_coach_injection.dart';
import 'package:isi_steel_sales_mobile/features/authentication/authentication_injection.dart';
import 'package:isi_steel_sales_mobile/features/localization/presentation/bloc/language_cubit.dart';
import 'package:isi_steel_sales_mobile/features/customers/customers_injection.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/home_injection.dart';
import 'package:isi_steel_sales_mobile/features/lead/lead_injection.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/my_visits_injection.dart';
import 'package:isi_steel_sales_mobile/features/order/order_injection.dart';
import 'package:isi_steel_sales_mobile/features/profile/profile_injection.dart';
import 'package:isi_steel_sales_mobile/features/revenue/revenue_injection.dart';
import 'package:isi_steel_sales_mobile/features/settings/theme/theme_injection.dart';

/// Global service locator.
final GetIt sl = GetIt.instance;

/// Call once from `main()` before `runApp`.
Future<void> initDependencies() async {
  // ── External singletons ────────────────────────────────────────────
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerFactory<ConnectivityCubit>(() => ConnectivityCubit(sl()));
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<SessionManager>(() => SessionManager());
  sl.registerLazySingleton<AppPreferences>(
    () => AppPreferencesImpl(HiveService.cacheBox),
  );
  sl.registerLazySingleton<LanguageCubit>(() => LanguageCubit(sl()));
  sl.registerLazySingleton<ShellTabController>(() => ShellTabController());
  registerThemeFeature(sl);

  // ── Features ───────────────────────────────────────────────────────
  registerAuthFeature(sl);
  initCustomerFeatures();
  registerLeadFeature(sl);
  await registerOrderFeature(sl);
  await registerCustomerFeature(sl);
  await registerMyVisitsFeature(sl);
  registerProfileFeature(sl);
  registerRevenueFeature(sl);
  registerAppCoachFeature(sl);
}
