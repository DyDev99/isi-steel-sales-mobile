import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/session/app_restart_controller.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/core/session/session_scoped_store.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/usecases/get_current_user.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/usecases/login.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/usecases/logout.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_event.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_state.dart';

/// Orchestrates auth use cases and keeps the app-wide [SessionManager] in sync
/// so guards, role checks, and sync scopes have a single, synchronous source
/// of truth for "who is signed in right now".
///
/// Holds no business logic itself — it only maps events to use-case calls and
/// their [Result] into states (+ the matching session mutation).
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required Login login,
    required Logout logout,
    required GetCurrentUser getCurrentUser,
    required SessionManager sessionManager,
    required SessionResetService sessionReset,
    required AppRestartController appRestart,
  })  : _login = login,
        _logout = logout,
        _getCurrentUser = getCurrentUser,
        _session = sessionManager,
        _sessionReset = sessionReset,
        _appRestart = appRestart,
        super(const AuthInitialState()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthGuestRequested>(_onGuest);
    // `droppable` guards against double-submits: extra taps while a login
    // is in flight are ignored rather than queued.
    on<LoginSubmittedEvent>(_onLogin, transformer: droppable());
    // `droppable` for the same reason as login: sign-out is idempotent but not
    // free — each run clears the stores again and bumps the restart
    // generation, so a double-tap would tear the whole app down twice.
    on<LogoutRequested>(_onLogout, transformer: droppable());
  }

  final Login _login;
  final Logout _logout;
  final GetCurrentUser _getCurrentUser;
  final SessionManager _session;
  final SessionResetService _sessionReset;
  final AppRestartController _appRestart;

  /// Session restore on boot. A cached session promotes to [AuthenticatedState];
  /// its absence is *not* an error here — the user simply continues as a guest,
  /// free to browse until they hit a protected feature.
  Future<void> _onCheck(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    final result = await _getCurrentUser(const NoParams());
    emit(result.when(
      success: (user) {
        _session.setUser(user);
        return AuthenticatedState(user);
      },
      failure: (_) {
        _session.clear();
        return const AuthGuestState();
      },
    ));
  }

  void _onGuest(AuthGuestRequested event, Emitter<AuthState> emit) {
    _session.clear();
    emit(const AuthGuestState());
  }

  Future<void> _onLogin(
    LoginSubmittedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    final result = await _login(
      LoginParams(email: event.email, password: event.password),
    );
    emit(result.when(
      success: (user) {
        _session.setUser(user);
        return AuthenticatedState(user);
      },
      failure: (f) => AuthFailureState(f.message),
    ));
  }

  /// Signing out drops the token store, every session-scoped feature store,
  /// and the in-memory session, in that order.
  ///
  /// Ordering matters: tokens go first so a request racing the sign-out cannot
  /// be authorized, and [SessionManager.clear] goes last because it is what
  /// notifies listeners the session ended — anything reacting to that must
  /// find the underlying stores already empty rather than half-cleared.
  ///
  /// The emitted state is [AuthGuestState] rather than a dedicated
  /// "logged out" one: this app is guest-first, so "signed out" and "browsing
  /// as a guest" are genuinely the same authorization level. Where the user
  /// *lands* is the caller's decision, not this bloc's.
  /// Restarting the app is part of signing out, not something the caller has
  /// to remember to do afterwards.
  ///
  /// It cannot be driven off the emitted state either: [AuthGuestState] is an
  /// `Equatable` with no props, so every instance compares equal and bloc
  /// suppresses the emit whenever guest was already the current state. A
  /// screen waiting for that state to arrive waits forever — which is exactly
  /// why the first version of this appeared to do nothing. Restarting here
  /// makes it unconditional, and gives every future sign-out entry point the
  /// same behaviour for free.
  Future<void> _onLogout(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _logout(const NoParams());
    await _sessionReset.clearAll();
    _session.clear();
    emit(const AuthGuestState());

    // Last, so the rebuilt tree reads an already-cleared session.
    _appRestart.restart();
  }
}
