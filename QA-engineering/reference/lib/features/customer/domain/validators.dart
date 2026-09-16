/// Field validators. Each returns null when valid, or an error message.
class CustomerValidators {
  CustomerValidators._();

  /// Upper bound for credit limit. BUSINESS RULE: confirm with product owner.
  static const double maxCreditLimit = 1000000000;

  static String? name(String? input) {
    final v = input?.trim() ?? '';
    if (v.isEmpty) return 'Customer name is required';
    if (v.length > 100) return 'Customer name is too long';
    return null;
  }

  static final _phone = RegExp(r'^\+?[0-9]{8,15}$');

  static String? phone(String? input) {
    final v = (input ?? '').replaceAll(RegExp(r'[\s-]'), '');
    if (v.isEmpty) return 'Phone is required';
    if (!_phone.hasMatch(v)) return 'Phone number is invalid';
    return null;
  }

  /// A credit limit of 0 is currently accepted. BUSINESS RULE: confirm.
  static String? creditLimit(String? input) {
    final v = input?.trim() ?? '';
    if (v.isEmpty) return 'Credit limit is required';
    final n = double.tryParse(v);
    if (n == null || n.isNaN || n.isInfinite) {
      return 'Credit limit must be a number';
    }
    if (n < 0) return 'Credit limit cannot be negative';
    if (n > maxCreditLimit) return 'Credit limit exceeds the maximum';
    return null;
  }
}
