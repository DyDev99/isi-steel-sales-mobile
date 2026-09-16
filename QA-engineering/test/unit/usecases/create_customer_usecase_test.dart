import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:steelforce_app/features/customer/domain/create_customer_usecase.dart';
import 'package:steelforce_app/features/customer/domain/customer.dart';
import 'package:steelforce_app/features/customer/domain/customer_repository.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockCustomerRepository repo;
  late CreateCustomerUseCase useCase;

  setUpAll(registerTestFallbacks);
  setUp(() {
    repo = MockCustomerRepository();
    useCase = CreateCustomerUseCase(repo);
  });

  test('given valid customer when called then saves via repository', () async {
    when(() => repo.createCustomer(any()))
        .thenAnswer((_) async => const Customer(
              id: 'C-1',
              name: 'Sok Dara Steel Co.',
              phone: '+85512345678',
              type: CustomerType.wholesale,
              creditLimit: 5000,
            ));

    final result = await useCase(validCustomer);

    expect(result.id, 'C-1');
    verify(() => repo.createCustomer(validCustomer)).called(1);
  });

  test('given invalid customer when called then throws and never calls API', () async {
    const bad = Customer(
        name: '', phone: '12', type: CustomerType.retail, creditLimit: -1);

    await expectLater(
      useCase(bad),
      throwsA(isA<ValidationException>().having(
          (e) => e.errors.keys, 'fields', containsAll(['name', 'phone', 'creditLimit']))),
    );
    verifyNever(() => repo.createCustomer(any()));
  });

  for (final error in <Exception>[
    const NetworkException(),
    const UnauthorizedException(),
    const ServerException(500),
  ]) {
    test('given repository throws ${error.runtimeType} then it propagates', () async {
      when(() => repo.createCustomer(any())).thenThrow(error);
      await expectLater(useCase(validCustomer), throwsA(same(error)));
    });
  }
}
