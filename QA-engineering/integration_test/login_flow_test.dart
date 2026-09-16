import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:steelforce_app/main.dart' as app;

import 'robots/login_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E-LOGIN-001 QA user can log in and reach dashboard', (tester) async {
    app.main();
    await LoginRobot(tester).loginAsQaUser();
  });
}
