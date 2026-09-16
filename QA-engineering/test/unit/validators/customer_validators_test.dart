@Tags(['smoke'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:steelforce_app/features/customer/domain/validators.dart';

void main() {
  group('CustomerValidators.creditLimit', () {
    final cases = <String?, bool>{
      '5000': true, // TC-CUST-010 happy path
      '0': true, // OPEN QUESTION: business must confirm 0 is allowed
      '0.50': true,
      ' 250 ': true, // surrounding whitespace is trimmed
      '-500': false, // TC-CUST-011 negative
      'abc': false, // TC-CUST-012 non-numeric
      '': false, // TC-CUST-013 empty
      null: false,
      'NaN': false,
      'Infinity': false,
      '1000000000': true, // max boundary
      '1000000000.01': false, // just above max
    };
    cases.forEach((input, valid) {
      test('given "$input" then valid=$valid', () {
        expect(CustomerValidators.creditLimit(input) == null, valid);
      });
    });
  });

  group('CustomerValidators.phone', () {
    for (final ok in ['012345678', '+85512345678', '012 345 678', '012-345-678']) {
      test('TC-CUST-020 accepts "$ok"', () {
        expect(CustomerValidators.phone(ok), isNull);
      });
    }
    for (final bad in ['', '123', 'abcdefghij', '+855 12 34x 678', '1234567890123456']) {
      test('TC-CUST-021 rejects "$bad"', () {
        expect(CustomerValidators.phone(bad), isNotNull);
      });
    }
  });

  group('CustomerValidators.name', () {
    test('TC-CUST-001 rejects empty or whitespace-only name', () {
      expect(CustomerValidators.name(''), isNotNull);
      expect(CustomerValidators.name('   '), isNotNull);
    });
    test('rejects names longer than 100 characters', () {
      expect(CustomerValidators.name('a' * 101), isNotNull);
      expect(CustomerValidators.name('a' * 100), isNull);
    });
    test('accepts Khmer and Unicode names', () {
      expect(CustomerValidators.name('ក្រុមហ៊ុន ដែក'), isNull);
    });
  });
}
