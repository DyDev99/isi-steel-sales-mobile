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

class _RecordingStore implements SessionScopedStore {
  bool cleared = false;

  @override
  String get debugName => 'test.store';

  @override
  Future<void> clearForSignOut() async => cleared = true;
}

void main() {
  const logger = ConsoleAppLogger(verbose: false);

  late _MockLogin login;
  late _MockLogout logout;
  late _MockGetCurrentUser getCurrentUser;
  late SessionManager session;
  late AppRestartController restart;
  late _RecordingStore store;

  setUpAll(() => registerFallbackValue(const NoParams()));

  AuthBloc build() => AuthBloc(
        login: login,
        logout: logout,
        getCurrentUser: getCurrentUser,
        sessionManager: session,
        sessionReset: SessionResetService([store], logger),
        appRestart: restart,
      );

  setUp(() {
    login = _MockLogin();
    logout = _MockLogout();
    getCurrentUser = _MockGetCurrentUser();
    session = SessionManager();
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
