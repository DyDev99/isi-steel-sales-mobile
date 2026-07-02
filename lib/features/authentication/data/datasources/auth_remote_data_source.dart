import 'package:dio/dio.dart';
import 'package:isi_steel_sales_mobile/core/constants/app_constant.dart';
import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/models/auth_response_model.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/models/auth_token_model.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  });
  Future<UserModel> getCurrentUser();
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);
  final Dio _client;

  @override
  @override
Future<AuthResponseModel> login({
  required String email,
  required String password,
}) async {
  
  // --- MOCK LOGIN FOR TESTING ---
  if (email == 'tester@gmail.com' && password == 'tester@12345') {
    return AuthResponseModel(
      user: const UserModel(
        id: 'user_001',
        email: 'tester@gmail.com',
        fullName: 'Test Tester',
        roles: {}, 
      ),
      token: const AuthTokenModel(
        accessToken: 'mock_access_token_123',
        refreshToken: 'mock_refresh_token_456',
      ),
    );
  }
  // ------------------------------

  try {
    final res = await _client.post<DataMap>(
      AppConstants.loginEndpoint,
      data: {'email': email, 'password': password},
    );
    return AuthResponseModel.fromMap(res.data ?? const {});
  } on DioException catch (e) {
    throw _map(e);
  }
}

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final res = await _client.get<DataMap>(AppConstants.currentUserEndpoint);
      final map = res.data ?? const {};
      return UserModel.fromMap((map['user'] as DataMap?) ?? map);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _client.post<void>(AppConstants.logoutEndpoint);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// Normalises Dio failures into the app's typed exceptions.
  Exception _map(DioException e) {
    final code = e.response?.statusCode;

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const NetworkException();
    }
    if (code == 401 || code == 403) {
      return AuthenticationException(
        message: _serverMessage(e) ?? 'Invalid email or password.',
        statusCode: code,
      );
    }
    return ServerException(
      message: _serverMessage(e) ?? 'Something went wrong. Please try again.',
      statusCode: code,
    );
  }

  String? _serverMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return null;
  }
}
