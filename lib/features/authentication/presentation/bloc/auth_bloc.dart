import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/usecases/get_current_user.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/usecases/login.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/usecases/logout.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_event.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_state.dart';

/// Orchestrates auth use cases. Holds no business logic itself — it only
/// maps events to use-case calls and their [Result] into states.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required Login login,
    required Logout logout,
    required GetCurrentUser getCurrentUser,
  })  : _login = login,
        _logout = logout,
        _getCurrentUser = getCurrentUser,
        super(const AuthInitialState()) {
    on<AuthCheckRequested>(_onCheck);
    // `droppable` guards against double-submits: extra taps while a login
    // is in flight are ignored rather than queued.
    on<LoginSubmittedEvent>(_onLogin, transformer: droppable());
    on<LogoutRequested>(_onLogout);
  }

  final Login _login;
  final Logout _logout;
  final GetCurrentUser _getCurrentUser;

  Future<void> _onCheck(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    final result = await _getCurrentUser(const NoParams());
    emit(result.when(
      success: (user) => AuthenticatedState(user),
      failure: (_) => const UnauthenticatedState(),
    ));
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
      success: (user) => AuthenticatedState(user),
      failure: (f) => AuthFailureState(f.message),
    ));
  }

  Future<void> _onLogout(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _logout(const NoParams());
    emit(const UnauthenticatedState());
  }
}
