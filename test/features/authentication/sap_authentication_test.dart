import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/api_client/auth/auth_session.dart';
import 'package:isi_steel_sales_mobile/features/authentication/data/models/sap_auth_response_model.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user_role.dart';

/// Covers SAP sign-in parsing, role mapping and token-expiry semantics.
///
/// The security-relevant assertions are the role-mapping ones: an unrecognised
/// SAP role must never resolve to anything privileged.
void main() {
  group('SapAuthResponseModel.fromJson', () {
    test('parses the documented login reply', () {
      final model = SapAuthResponseModel.fromJson({
        'token': 'eyJhbGciOiJIUzI1NiIs...',
        'expiresAt': '2026-07-20T09:30:00Z',
        'username': 'admin',
        'role': 'Admin',
      });

      expect(model.token, 'eyJhbGciOiJIUzI1NiIs...');
      expect(model.username, 'admin');
      expect(model.role, 'Admin');
      expect(model.expiresAt.toUtc(), DateTime.utc(2026, 7, 20, 9, 30));
    });

    test('a reply with no token is rejected', () {
      // Accepting one would store an empty bearer and turn every later call
      // into an unexplained 401.
      expect(
        () => SapAuthResponseModel.fromJson(const {'username': 'admin'}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => SapAuthResponseModel.fromJson(const {'token': ''}),
        throwsA(isA<FormatException>()),
      );
    });

    test('an unparsable expiry is treated as already expired', () {
      // Fail-closed: renewing too eagerly costs one login, whereas trusting a
      // bad expiry means every later request 401s with no recovery path.
      final model = SapAuthResponseModel.fromJson(const {
        'token': 't',
        'expiresAt': 'not-a-date',
      });

      expect(model.expiresAt.isBefore(DateTime.now()), isTrue);
    });

    test('a missing expiry is treated as already expired', () {
      final model = SapAuthResponseModel.fromJson(const {'token': 't'});
      expect(model.expiresAt.isBefore(DateTime.now()), isTrue);
    });
  });

  group('SapRoleMapper', () {
    test('maps the roles the technical document names', () {
      expect(SapRoleMapper.toUserRole('Admin'), UserRole.admin);
      expect(SapRoleMapper.toUserRole('Operator'), UserRole.salesRep);
    });

    test('is case-insensitive', () {
      expect(SapRoleMapper.toUserRole('ADMIN'), UserRole.admin);
      expect(SapRoleMapper.toUserRole('admin'), UserRole.admin);
    });

    test('an unknown role degrades to guest, never to a privileged role', () {
      // The load-bearing security assertion. A new or misspelled SAP role must
      // not silently grant elevated access in the app.
      for (final role in ['Superuser', 'ZZ_CUSTOM', '', 'administrator ']) {
        expect(
          SapRoleMapper.toUserRole(role),
          UserRole.guest,
          reason: 'unrecognised role "$role" must be least-privileged',
        );
      }
    });
  });

  group('toUser', () {
    test('carries the SAP identity across without inventing fields', () {
      final user = SapAuthResponseModel.fromJson(const {
        'token': 't',
        'expiresAt': '2099-01-01T00:00:00Z',
        'username': 'sok.dara',
        'role': 'Operator',
      }).toUser();

      expect(user.id, 'sok.dara');
      expect(user.fullName, 'sok.dara');
      expect(user.roles, {UserRole.salesRep});
      expect(user.primaryRole, UserRole.salesRep);
    });

    test('email is left empty rather than fabricated', () {
      // SAP returns no email. Synthesising `username@company` would produce an
      // address that looks real and does not exist.
      final user = SapAuthResponseModel.fromJson(const {
        'token': 't',
        'username': 'admin',
        'role': 'Admin',
      }).toUser();

      expect(user.email, isEmpty);
      expect(user.company, isNull);
      expect(user.avatarUrl, isNull);
    });
  });

  group('AuthSession expiry', () {
    AuthSession sessionExpiringIn(Duration delta) => AuthSession(
          accessToken: 'token',
          expiresAt: DateTime.now().toUtc().add(delta),
          username: 'admin',
          role: 'Admin',
        );

    test('a comfortably future token is valid', () {
      expect(sessionExpiringIn(const Duration(minutes: 30)).isValid, isTrue);
    });

    test('a past token is expired', () {
      expect(sessionExpiringIn(const Duration(minutes: -1)).isExpired, isTrue);
    });

    test('a token expiring inside the skew window counts as expired', () {
      // Guards against dispatching a request with a token that lapses in
      // flight, which would surface as a spurious 401 and an avoidable retry.
      expect(sessionExpiringIn(const Duration(seconds: 20)).isExpired, isTrue);
    });

    test('an empty token is never valid regardless of expiry', () {
      final session = AuthSession(
        accessToken: '',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        username: 'admin',
        role: 'Admin',
      );
      expect(session.isValid, isFalse);
    });

    test('SAP sessions cannot refresh — there is no refresh endpoint', () {
      // §3.2: renewal means re-authenticating, which is why TokenManager keeps
      // the credentials rather than a refresh token.
      expect(sessionExpiringIn(const Duration(hours: 1)).canRefresh, isFalse);
    });

    test('round-trips through JSON for secure storage', () {
      final original = sessionExpiringIn(const Duration(minutes: 30));
      final restored = AuthSession.fromJson(original.toJson());

      expect(restored.accessToken, original.accessToken);
      expect(restored.username, original.username);
      expect(restored.role, original.role);
      expect(restored.isValid, isTrue);
    });
  });
}
