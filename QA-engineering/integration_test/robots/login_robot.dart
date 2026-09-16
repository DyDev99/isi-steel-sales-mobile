import 'package:flutter_test/flutter_test.dart';
import 'package:steelforce_app/core/testing/test_keys.dart';

class LoginRobot {
  LoginRobot(this.tester);
  final WidgetTester tester;

  static const username = String.fromEnvironment('QA_USERNAME');
  static const password = String.fromEnvironment('QA_PASSWORD');

  Future<void> loginAsQaUser() async {
    if (username.isEmpty || password.isEmpty) {
      fail('QA_USERNAME / QA_PASSWORD not provided via --dart-define (environment issue)');
    }
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(TestKeys.loginUsername), username);
    await tester.enterText(find.byKey(TestKeys.loginPassword), password);
    await tester.tap(find.byKey(TestKeys.loginSubmit));
    await pumpUntilFound(tester, find.byKey(TestKeys.dashboardScreen));
  }
}

/// Waits for [finder] without relying on pumpAndSettle, which hangs on
/// infinite animations (spinners, shimmer).
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out after $timeout waiting for $finder');
}
