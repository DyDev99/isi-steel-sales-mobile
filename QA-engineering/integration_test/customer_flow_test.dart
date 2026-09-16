import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:steelforce_app/main.dart' as app;

import 'robots/customer_robot.dart';
import 'robots/login_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E-CUST-001 login -> create customer -> appears in list', (tester) async {
    // Unique name so repeated runs don't collide in the QA database.
    final name = 'QA Auto ${DateTime.now().millisecondsSinceEpoch}';

    app.main();
    await LoginRobot(tester).loginAsQaUser();

    final customer = CustomerRobot(tester);
    await customer.openCustomers();
    await customer.openCreateForm();
    await customer.fillForm(name: name, phone: '+85512345678', creditLimit: '5000');
    await customer.submit();
    await customer.expectSuccess();

    // TODO: adapt navigation back to the list if your app does not auto-return.
    await customer.openCustomers();
    await customer.searchFor(name);
    await pumpUntilFound(tester, find.text(name));
  });
}
