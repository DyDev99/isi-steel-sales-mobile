/// Thrown by data sources. Repositories catch these and translate them
/// into [Failure]s so exceptions never leak past the data layer.
///
/// **Scope: persistence and local operations.** Transport errors are the
/// networking layer's, and are declared as `ApiException` in
/// `core/api_client/api_service/api_exception.dart`. The two families are kept
/// apart deliberately — a repository that both calls a backend and writes to
/// Drift needs to tell "SAP rejected this" from "the local write failed", and a
/// single merged hierarchy makes that distinction disappear.
///
/// A repository using both imports the networking one with a prefix:
///
/// ```dart
/// import 'package:.../core/api_client/api_service/api_exception.dart' as net;
/// ```
library;

class ServerException implements Exception {
  const ServerException({required this.message, this.statusCode});
  final String message;
  final int? statusCode;
}

class CacheException implements Exception {
  const CacheException({this.message = 'Cache error.'});
  final String message;
}

class NetworkException implements Exception {
  const NetworkException({this.message = 'No internet connection.'});
  final String message;
}

class AuthenticationException implements Exception {
  const AuthenticationException({required this.message, this.statusCode});
  final String message;
  final int? statusCode;
}
