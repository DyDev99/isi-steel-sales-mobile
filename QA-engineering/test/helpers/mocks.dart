import 'package:mocktail/mocktail.dart';
import 'package:steelforce_app/features/customer/domain/create_customer_usecase.dart';
import 'package:steelforce_app/features/customer/domain/customer.dart';
import 'package:steelforce_app/features/customer/domain/customer_repository.dart';

class MockCustomerRepository extends Mock implements CustomerRepository {}

class MockCreateCustomerUseCase extends Mock implements CreateCustomerUseCase {}

class FakeCustomer extends Fake implements Customer {}

/// Call once in setUpAll() of any test that uses any<Customer>().
void registerTestFallbacks() {
  registerFallbackValue(FakeCustomer());
}

/// Shared valid test data.
const validCustomer = Customer(
  name: 'Sok Dara Steel Co.',
  phone: '+85512345678',
  type: CustomerType.wholesale,
  creditLimit: 5000,
);
