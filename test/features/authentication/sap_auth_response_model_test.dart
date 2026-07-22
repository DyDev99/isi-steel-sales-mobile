import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/models/sap_auth_response_model.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user_role.dart';

void main() {
  group('SapAuthResponseModel.fromJson', () {
    // The exact shape the live server returned (values shortened). The facade
    // emits PascalCase; the technical doc shows camelCase. Both must parse.
    test('parses the PascalCase shape the live server returns', () {
      final model = SapAuthResponseModel.fromJson(const {
        'Token': 'eyJhbGabc.def.ghi',
        'ExpiresAt': '2026-07-22T03:23:36.4233524Z',
        'Username': 'Mobile',
        'Role': 'Operator',
      });

      expect(model.token, 'eyJhbGabc.def.ghi');
      expect(model.username, 'Mobile');
      expect(model.role, 'Operator');
      // Fractional seconds with 7 digits + 'Z' must parse, not fall back to
      // epoch (which would make the session look already-expired).
      expect(model.expiresAt.isAfter(DateTime.utc(2026, 7, 22)), isTrue);
      expect(model.expiresAt, DateTime.utc(2026, 7, 22, 3, 23, 36, 423, 352));
    });

    test('parses the camelCase shape from the technical document', () {
      final model = SapAuthResponseModel.fromJson(const {
        'token': 'eyJhbGabc.def.ghi',
        'expiresAt': '2026-07-22T03:23:36Z',
        'username': 'Mobile',
        'role': 'Admin',
      });

      expect(model.token, 'eyJhbGabc.def.ghi');
      expect(model.username, 'Mobile');
      expect(model.role, 'Admin');
    });

    test('Operator role maps to salesRep', () {
      final model = SapAuthResponseModel.fromJson(const {
        'Token': 'a.b.c',
        'ExpiresAt': '2026-07-22T03:23:36Z',
        'Username': 'Mobile',
        'Role': 'Operator',
      });
      expect(model.toUser().roles, contains(UserRole.salesRep));
    });

    test('missing token throws, and the message lists the keys but no values',
        () {
      expect(
        () => SapAuthResponseModel.fromJson(const {
          'ExpiresAt': '2026-07-22T03:23:36Z',
          'Username': 'Mobile',
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            allOf(contains('ExpiresAt'), contains('Username')),
          ),
        ),
      );
    });
  });
}
