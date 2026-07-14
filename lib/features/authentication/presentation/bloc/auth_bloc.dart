import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/storage/session/session_manager.dart';
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
  })  : _login = login,
        _logout = logout,
        _getCurrentUser = getCurrentUser,
        _session = sessionManager,
        super(const AuthInitialState()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthGuestRequested>(_onGuest);
    // `droppable` guards against double-submits: extra taps while a login
    // is in flight are ignored rather than queued.
    on<LoginSubmittedEvent>(_onLogin, transformer: droppable());
    on<LogoutRequested>(_onLogout);
  }

  final Login _login;
  final Logout _logout;
  final GetCurrentUser _getCurrentUser;
  final SessionManager _session;

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

  /// Signing out drops the token/session and returns the user to guest
  /// browsing — the app stays open and usable, matching the guest-first model.
  Future<void> _onLogout(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _logout(const NoParams());
    _session.clear();
    emit(const AuthGuestState());
  }
}
