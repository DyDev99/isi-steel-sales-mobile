import 'package:isi_steel_sales_mobile/core/api_client/api_service/api_service.dart';

/// [ApiService] bound to the ISI Steel Sales backend.
///
/// **Scope: app-native concerns only** — user profile, notifications, app
/// configuration, feature flags, preferences, analytics, and customer
/// notes/activities. SAP business objects never belong here; they are
/// `SapApiService`'s.
///
/// Shares every line of transport logic with `SapApiService` — see that class
/// for why the *instances* are nonetheless separate.
class IsiApiService extends DioApiService {
  const IsiApiService(super.client);
}
