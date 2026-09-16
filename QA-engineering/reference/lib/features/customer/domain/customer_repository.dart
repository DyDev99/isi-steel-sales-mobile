import 'customer.dart';

class NetworkException implements Exception {
  const NetworkException();
}

class UnauthorizedException implements Exception {
  const UnauthorizedException();
}

class ServerException implements Exception {
  const ServerException(this.statusCode);
  final int statusCode;
}

class ValidationException implements Exception {
  const ValidationException(this.errors);
  final Map<String, String> errors;
}

abstract class CustomerRepository {
  Future<Customer> createCustomer(Customer customer);
}
