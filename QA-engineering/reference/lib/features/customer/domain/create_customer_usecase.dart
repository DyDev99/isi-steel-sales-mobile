import 'customer.dart';
import 'customer_repository.dart';
import 'validators.dart';

class CreateCustomerUseCase {
  CreateCustomerUseCase(this._repository);
  final CustomerRepository _repository;

  /// Validates again at the domain layer so bad data never reaches the API.
  Future<Customer> call(Customer customer) async {
    final errors = <String, String>{};
    final n = CustomerValidators.name(customer.name);
    final p = CustomerValidators.phone(customer.phone);
    final c = CustomerValidators.creditLimit(customer.creditLimit.toString());
    if (n != null) errors['name'] = n;
    if (p != null) errors['phone'] = p;
    if (c != null) errors['creditLimit'] = c;
    if (errors.isNotEmpty) throw ValidationException(errors);
    return _repository.createCustomer(customer);
  }
}
