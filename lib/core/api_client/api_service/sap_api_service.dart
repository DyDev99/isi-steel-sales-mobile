import 'package:isi_steel_sales_mobile/core/api_client/api_service/api_service.dart';

/// [ApiService] bound to the SAP backend.
///
/// A named type rather than a bare `ApiService` instance so a datasource
/// declares which backend it talks to in its constructor signature. Wiring a
/// SAP datasource to the ISI service then fails to compile, instead of failing
/// at runtime against the wrong host.
///
/// **Scope: SAP S/4HANA business objects only** — authentication, business
/// partner, customer master, and later products, quotations, sales orders,
/// inventory, territory and depot. Nothing app-specific belongs here.
///
/// Shares all transport logic with `IsiApiService`: the same [DioApiService]
/// implementation, the same `DioClient`, the same interceptor stack, the same
/// error mapping. Only the *configured instance* differs — the two backends
/// have different hosts, different TLS posture and different credentials, and a
/// single shared instance would attach the SAP bearer token to ISI requests.
class SapApiService extends DioApiService {
  const SapApiService(super.client);
}
