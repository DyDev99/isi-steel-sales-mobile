import 'package:get_it/get_it.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/local/customer_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/notification/data/repositories/customer_notification_repository.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/repositories/notification_repository.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/usecases/fetch_notifications.dart';

/// Registers the notifications sheet.
///
/// This feature previously had no registration of its own — its use case was
/// built by `registerLeadFeature` against `LeadRepository`, which is why
/// removing the lead feature took the notifications sheet down with it.
///
/// Must run after `registerCustomerFeature`, which provides
/// [CustomerLocalDataSource]. Registration is lazy, so ordering only matters
/// for resolution, not for this call.
void registerNotificationFeature(GetIt sl) {
  sl.registerLazySingleton<NotificationRepository>(
    () => CustomerNotificationRepository(sl<CustomerLocalDataSource>()),
  );

  sl.registerLazySingleton(() => FetchNotifications(sl()));
}
