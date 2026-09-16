import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:steelforce_app/features/customer/domain/customer.dart';
import 'package:steelforce_app/features/customer/domain/customer_repository.dart';
import 'package:steelforce_app/features/customer/presentation/customer_form_bloc.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockCreateCustomerUseCase createCustomer;

  setUpAll(registerTestFallbacks);
  setUp(() => createCustomer = MockCreateCustomerUseCase());

  CustomerFormBloc build() => CustomerFormBloc(createCustomer);

  const filled = CustomerFormState(
    name: 'Sok Dara Steel Co.',
    phone: '+85512345678',
    creditLimit: '5000',
    type: CustomerType.wholesale,
  );

  test('initial state is empty and editing', () {
    expect(build().state, const CustomerFormState());
  });

  blocTest<CustomerFormBloc, CustomerFormState>(
    'TC-CUST-001 given empty form when submitted then shows errors and does not call API',
    build: build,
    act: (b) => b.add(const FormSubmitted()),
    expect: () => [const CustomerFormState(showErrors: true)],
    verify: (_) => verifyNever(() => createCustomer(any())),
  );

  blocTest<CustomerFormBloc, CustomerFormState>(
    'TC-CUST-002 given valid form when submitted then submitting -> success',
    setUp: () => when(() => createCustomer(any())).thenAnswer((_) async => validCustomer),
    build: build,
    seed: () => filled,
    act: (b) => b.add(const FormSubmitted()),
    expect: () => [
      filled.copyWith(status: FormStatus.submitting, showErrors: true),
      filled.copyWith(status: FormStatus.success, showErrors: true),
    ],
    verify: (_) => verify(() => createCustomer(validCustomer)).called(1),
  );

  blocTest<CustomerFormBloc, CustomerFormState>(
    'TC-CUST-030 given double-tap submit then API is called only once',
    setUp: () {
      final completer = Completer<Customer>();
      when(() => createCustomer(any())).thenAnswer((_) => completer.future);
      Future<void>.delayed(const Duration(milliseconds: 50), () => completer.complete(validCustomer));
    },
    build: build,
    seed: () => filled,
    act: (b) => b
      ..add(const FormSubmitted())
      ..add(const FormSubmitted()),
    wait: const Duration(milliseconds: 100),
    verify: (_) => verify(() => createCustomer(any())).called(1),
  );

  final errorCases = <Exception, String>{
    const NetworkException(): 'No internet connection. Please try again.',
    const UnauthorizedException(): 'Your session has expired. Please log in again.',
    const ServerException(500): 'Server error. Please try again later.',
  };
  errorCases.forEach((error, message) {
    blocTest<CustomerFormBloc, CustomerFormState>(
      'TC-CUST-040 given API throws ${error.runtimeType} then shows "$message"',
      setUp: () => when(() => createCustomer(any())).thenThrow(error),
      build: build,
      seed: () => filled,
      act: (b) => b.add(const FormSubmitted()),
      expect: () => [
        filled.copyWith(status: FormStatus.submitting, showErrors: true),
        filled.copyWith(status: FormStatus.failure, showErrors: true, errorMessage: message),
      ],
    );
  });

  blocTest<CustomerFormBloc, CustomerFormState>(
    'given failure when user edits a field then error message clears',
    build: build,
    seed: () => filled.copyWith(status: FormStatus.failure, errorMessage: 'x'),
    act: (b) => b.add(const NameChanged('New name')),
    expect: () => [
      filled.copyWith(status: FormStatus.failure, name: 'New name'),
    ],
  );
}
