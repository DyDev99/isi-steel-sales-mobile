import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steelforce_app/core/testing/test_keys.dart';

import 'login_robot.dart';

class CustomerRobot {
  CustomerRobot(this.tester);
  final WidgetTester tester;

  Future<void> openCustomers() async {
    await tester.tap(find.byKey(TestKeys.navCustomer));
    await pumpUntilFound(tester, find.byKey(TestKeys.customerList));
  }

  Future<void> openCreateForm() async {
    await tester.tap(find.byKey(TestKeys.customerAddButton));
    await pumpUntilFound(tester, find.byKey(TestKeys.customerForm));
  }

  Future<void> fillForm({required String name, required String phone, required String creditLimit}) async {
    await tester.enterText(find.byKey(TestKeys.customerName), name);
    await tester.enterText(find.byKey(TestKeys.customerPhone), phone);
    await tester.enterText(find.byKey(TestKeys.customerCreditLimit), creditLimit);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
  }

  Future<void> submit() async {
    await tester.ensureVisible(find.byKey(TestKeys.customerSubmit));
    await tester.tap(find.byKey(TestKeys.customerSubmit));
    await tester.pump();
  }

  Future<void> expectSuccess() => pumpUntilFound(tester, find.byKey(TestKeys.customerSuccess));

  Future<void> searchFor(String text) async {
    await tester.enterText(find.byKey(TestKeys.customerSearch), text);
    await tester.pump(const Duration(milliseconds: 600)); // debounce
  }
}
