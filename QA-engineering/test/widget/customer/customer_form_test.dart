import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:steelforce_app/core/testing/test_keys.dart';
import 'package:steelforce_app/features/customer/domain/customer.dart';
import 'package:steelforce_app/features/customer/domain/customer_repository.dart';
import 'package:steelforce_app/features/customer/presentation/customer_form.dart';
import 'package:steelforce_app/features/customer/presentation/customer_form_bloc.dart';

import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';

void main() {
  late MockCreateCustomerUseCase createCustomer;

  setUpAll(registerTestFallbacks);
  setUp(() => createCustomer = MockCreateCustomerUseCase());

  Future<void> pumpForm(WidgetTester tester, {Size size = const Size(390, 844)}) {
    return tester.pumpApp(
      BlocProvider(
        create: (_) => CustomerFormBloc(createCustomer),
        child: const CustomerForm(),
      ),
      size: size,
    );
  }

  Future<void> fillValid(WidgetTester tester) async {
    await tester.enterText(find.byKey(TestKeys.customerName), 'Sok Dara Steel Co.');
    await tester.enterText(find.byKey(TestKeys.customerPhone), '+85512345678');
    await tester.enterText(find.byKey(TestKeys.customerCreditLimit), '5000');
    await tester.pump();
  }

  testWidgets('@smoke form renders all fields and submit button', (tester) async {
    await pumpForm(tester);
    for (final key in [
      TestKeys.customerName,
      TestKeys.customerPhone,
      TestKeys.customerType,
      TestKeys.customerCreditLimit,
      TestKeys.customerSubmit,
    ]) {
      expect(find.byKey(key), findsOneWidget, reason: 'missing $key');
    }
  }, tags: ['smoke']);

  testWidgets('no validation errors are shown before first submit', (tester) async {
    await pumpForm(tester);
    expect(find.text('Customer name is required'), findsNothing);
  });

  testWidgets('TC-CUST-001 empty submit shows required-field errors', (tester) async {
    await pumpForm(tester);
    await tester.tap(find.byKey(TestKeys.customerSubmit));
    await tester.pump();

    expect(find.text('Customer name is required'), findsOneWidget);
    expect(find.text('Phone is required'), findsOneWidget);
    expect(find.text('Credit limit is required'), findsOneWidget);
    verifyNever(() => createCustomer(any()));
  });

  testWidgets('TC-CUST-011 negative credit limit shows error', (tester) async {
    await pumpForm(tester);
    await fillValid(tester);
    await tester.enterText(find.byKey(TestKeys.customerCreditLimit), '-500');
    await tester.tap(find.byKey(TestKeys.customerSubmit));
    await tester.pump();
    expect(find.text('Credit limit cannot be negative'), findsOneWidget);
  });

  testWidgets('TC-CUST-002 valid submit shows loading then success', (tester) async {
    final completer = Completer<Customer>();
    when(() => createCustomer(any())).thenAnswer((_) => completer.future);

    await pumpForm(tester);
    await fillValid(tester);
    await tester.tap(find.byKey(TestKeys.customerSubmit));
    await tester.pump();

    expect(find.byKey(TestKeys.customerSubmitLoading), findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.byKey(TestKeys.customerSubmit));
    expect(button.onPressed, isNull, reason: 'button must be disabled while submitting');

    completer.complete(validCustomer);
    await tester.pumpAndSettle();

    expect(find.byKey(TestKeys.customerSuccess), findsOneWidget);
    expect(find.byKey(TestKeys.customerSubmitLoading), findsNothing);
  });

  testWidgets('TC-CUST-040 offline submit shows network error', (tester) async {
    when(() => createCustomer(any())).thenThrow(const NetworkException());
    await pumpForm(tester);
    await fillValid(tester);
    await tester.tap(find.byKey(TestKeys.customerSubmit));
    await tester.pumpAndSettle();

    expect(find.byKey(TestKeys.customerError), findsOneWidget);
    expect(find.textContaining('No internet'), findsOneWidget);
  });

  testWidgets('user can change customer type', (tester) async {
    when(() => createCustomer(any())).thenAnswer((_) async => validCustomer);
    await pumpForm(tester);
    await fillValid(tester);
    await tester.tap(find.byKey(TestKeys.customerType));
    await tester.pumpAndSettle();
    await tester.tap(find.text('contractor').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(TestKeys.customerSubmit));
    await tester.pumpAndSettle();

    final captured = verify(() => createCustomer(captureAny())).captured.single as Customer;
    expect(captured.type, CustomerType.contractor);
  });

  for (final size in const [Size(320, 568), Size(412, 915), Size(800, 1280)]) {
    testWidgets('renders without overflow on ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      await pumpForm(tester, size: size);
      await tester.tap(find.byKey(TestKeys.customerSubmit));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}
