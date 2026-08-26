import 'package:isi_steel_sales_mobile/features/authentication/domain/notification_lifecycle.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/logging/app_logger.dart';
import 'package:isi_steel_sales_mobile/core/session/app_restart_controller.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/core/session/session_scoped_store.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user_role.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/usecases/get_current_user.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/usecases/login.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/usecases/logout.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_event.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockLogin extends Mock implements Login {}

class _MockLogout extends Mock implements Logout {}

class _MockGetCurrentUser extends Mock implements GetCurrentUser {}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _RecordingStore implements SessionScopedStore {
  bool cleared = false;

  @override
  String get debugName => 'test.store';

  @override
  Future<void> clearForSignOut() async => cleared = true;
}

/// Fails every hook, to prove sign-out survives it.
class _ThrowingNotifications implements NotificationLifecycle {
  @override
  Future<void> onSignedIn() async => throw StateError('no network');

  @override
  Future<void> onSigningOut() async => throw StateError('no network');
}

/// Records when the notification side of sign-out ran.
///
/// A two-method fake rather than a mock of `NotificationCoordinator`: that is
/// the entire reason [NotificationLifecycle] exists — `AuthBloc` must be
/// testable without standing up Firebase, a Drift DAO and three repositories.
class _RecordingNotifications implements NotificationLifecycle {
  final List<String> calls = [];

  @override
  Future<void> onSignedIn() async => calls.add('signedIn');

  @override
  Future<void> onSigningOut() async => calls.add('signingOut');
}

void main() {
  const logger = ConsoleAppLogger(verbose: false);

  late _MockLogin login;
  late _MockLogout logout;
  late _MockGetCurrentUser getCurrentUser;
  late SessionManager session;
  late _MockAuthRepository repository;
  late AppRestartController restart;
  late _RecordingStore store;
  late _RecordingNotifications notifications;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const LogoutParams());
  });

  AuthBloc build() => AuthBloc(
        login: login,
        logout: logout,
        getCurrentUser: getCurrentUser,
        sessionManager: session,
        sessionReset: SessionResetService([store], logger),
        appRestart: restart,
        repository: repository,
        logger: logger,
        notifications: notifications,
      );

  setUp(() {
    notifications = _RecordingNotifications();
    login = _MockLogin();
    logout = _MockLogout();
    getCurrentUser = _MockGetCurrentUser();
    session = SessionManager();
    repository = _MockAuthRepository();
    restart = AppRestartController();
    store = _RecordingStore();
    when(() => logout(any())).thenAnswer((_) async => const Success(null));
  });

  Future<void> signOut(AuthBloc bloc) async {
    bloc.add(const LogoutRequested());
    // One turn of the event loop is enough: every awaited call in the handler
    // is already-completed test doubles.
    await Future<void>.delayed(Duration.zero);
  }

  test('the device is deregistered before the token is discarded', () async {
    // `docs/features/notification-mobile.md` §4.4, and the ordering is the whole
    // point: deregistration is an authenticated call, so it has to happen while
    // the bearer token is still valid. Skipping it — or running it after — leaves
    // the platform pushing one rep's notifications at a handset that has since
    // been handed to somebody else.
    final order = <String>[];
    notifications.calls.clear();
    when(() => logout(any())).thenAnswer((_) async {
      order.add('logout');
      return const Success(null);
    });

    final bloc = build();
    addTearDown(bloc.close);

    await signOut(bloc);
    order.insertAll(0, notifications.calls);

    expect(order, ['signingOut', 'logout']);
  });

  test('a failing deregistration does not block sign-out', () async {
    // A rep who cannot sign out because a deregistration failed is worse than a
    // stale registration — which the backend deactivates on its own once FCM
    // reports the token dead.
    final bloc = AuthBloc(
      login: login,
      logout: logout,
      getCurrentUser: getCurrentUser,
      sessionManager: session,
      sessionReset: SessionResetService([store], logger),
      appRestart: restart,
      repository: repository,
      logger: logger,
      notifications: _ThrowingNotifications(),
    );
    addTearDown(bloc.close);

    await signOut(bloc);

    verify(() => logout(any())).called(1);
    expect(session.isAuthenticated, isFalse);
    expect(bloc.state, isA<AuthGuestState>());
  });

  test('sign-out clears tokens, feature stores and the session', () async {
    final bloc = build();
    addTearDown(bloc.close);

    await signOut(bloc);

    verify(() => logout(any())).called(1);
    expect(store.cleared, isTrue);
    expect(session.isAuthenticated, isFalse);
    expect(bloc.state, isA<AuthGuestState>());
  });

  test('sign-out restarts the app', () async {
    final bloc = build();
    addTearDown(bloc.close);
    final before = restart.value;

    await signOut(bloc);

    expect(restart.value, greaterThan(before));
  });

  test('sign-out restarts even when the state is already guest', () async {
    // The bug this pins down: `AuthGuestState` is an Equatable with no props,
    // so bloc suppresses the emit when guest is already the current state.
    // Anything keyed off that emission — as the first fix was — waits forever
    // and the app never restarts. The restart must not depend on it.
    final bloc = build();
    addTearDown(bloc.close);

    bloc.add(const AuthGuestRequested());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state, isA<AuthGuestState>());

    final before = restart.value;
    await signOut(bloc);

    expect(restart.value, greaterThan(before),
        reason: 'restart must not be gated on a state change that bloc '
            'legitimately suppresses');
    expect(store.cleared, isTrue);
  });

  test('a signed-in session is torn down on sign-out', () async {
    final bloc = build();
    addTearDown(bloc.close);
    session.setUser(_user());
    expect(session.isAuthenticated, isTrue);

    await signOut(bloc);

    expect(session.isAuthenticated, isFalse);
    expect(session.currentUser, isNull);
  });
}

User _user() => const User(
      id: 'u1',
      email: 'rep@isigroup.com.kh',
      fullName: 'Rep One',
      roles: {UserRole.salesRep},
    );
