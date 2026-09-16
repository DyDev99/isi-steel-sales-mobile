import 'package:flutter/widgets.dart';

/// Stable keys used by widget and integration tests.
/// Never find widgets by visible text in E2E tests: text changes and gets translated.
class TestKeys {
  TestKeys._();

  // Login
  static const loginUsername = Key('login_username');
  static const loginPassword = Key('login_password');
  static const loginSubmit = Key('login_submit');

  // Navigation
  static const dashboardScreen = Key('dashboard_screen');
  static const navCustomer = Key('nav_customer');

  // Customer list
  static const customerList = Key('customer_list');
  static const customerAddButton = Key('customer_add_button');
  static const customerSearch = Key('customer_search');

  // Customer form
  static const customerForm = Key('customer_form');
  static const customerName = Key('customer_name');
  static const customerPhone = Key('customer_phone');
  static const customerType = Key('customer_type');
  static const customerCreditLimit = Key('customer_credit_limit');
  static const customerSubmit = Key('customer_submit');
  static const customerSubmitLoading = Key('customer_submit_loading');
  static const customerSuccess = Key('customer_success');
  static const customerError = Key('customer_error');
}
