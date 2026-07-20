import 'package:isi_steel_sales_mobile/core/api_client/api_service/sap_api_service.dart';
import 'package:isi_steel_sales_mobile/core/api_client/endpoints/sap_endpoints.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/models/sap_auth_response_model.dart';

/// Authentication against SAP.
///
/// SAP is the only authentication provider. There is no mock branch, no fake
/// user and no locally-minted token — the previous implementation short-circuited
/// on a hardcoded `tester@gmail.com` / `tester@12345` pair and returned a
/// fabricated `mock_access_token_123`, which would have authenticated nobody
/// against a real SAP system while appearing to work in every demo.
abstract interface class AuthRemoteDataSource {
  /// `POST /api/Auth/Login` — the only SAP endpoint that takes no bearer token.
  Future<SapAuthResponseModel> login({
    required String username,
    required String password,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._api);

  final SapApiService _api;

  @override
  Future<SapAuthResponseModel> login({
    required String username,
    required String password,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      SapEndpoints.login,
      data: {'username': username, 'password': password},
      // Login mints the token, so it must not carry one. Without this the auth
      // interceptor would ask the token manager for a session, which would try
      // to log in — recursing into this very call.
      skipAuth: true,
      decoder: (body) =>
          body is Map<String, dynamic> ? body : const <String, dynamic>{},
    );

    return SapAuthResponseModel.fromJson(response.data);
  }
}
