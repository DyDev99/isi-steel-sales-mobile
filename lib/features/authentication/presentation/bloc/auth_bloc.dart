import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/logging/app_logger.dart';
import 'package:isi_steel_sales_mobile/core/session/app_restart_controller.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/core/session/session_scoped_store.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/otp_challenge.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/repositories/auth_repository.dart';
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
    required AuthRepository repository,
    required AppLogger logger,
  })  : _repo = repository,
        _logger = logger,
        _login = login,
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
    on<PhoneLoginSubmitted>(_onPhoneLogin, transformer: droppable());
    on<OtpSubmitted>(_onOtpSubmitted, transformer: droppable());
    on<OtpResendRequested>(_onOtpResend, transformer: droppable());
    on<OtpAbandoned>(_onOtpAbandoned);
  }

  final Login _login;
  final Logout _logout;
  final GetCurrentUser _getCurrentUser;
  final SessionManager _session;
  final SessionResetService _sessionReset;
  final AppRestartController _appRestart;
  final AuthRepository _repo;
  final AppLogger _logger;

  /// The attempt in flight between step 1 and step 3.
  ///
  /// Holds only the opaque `verificationId` — **never the password**, which is
  /// spent at `send-otp` and must not survive it. Nothing is committed to
  /// [SessionManager] while this is set, so the protected-API gate stays shut
  /// for the whole challenge.
  OtpChallenge? _challenge;

  /// The number the code went to, for the verify screen's subtitle. Held
  /// alongside the challenge and cleared with it.
  String? _destination;

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
      success: (profile) {
        final user = profile.toUser();
        // Permissions travel with the restored session, so a feature gated on
        // `customers.read` knows the answer before its first request rather
        // than discovering it as a 403.
        _session.setUser(user,
            permissions: profile.permissions,
            territoryCode: profile.territoryCode);
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
    // Global lifecycle, separate from this bloc's presentation state: while a
    // sign-in is in flight the protected-API gate stays shut, so a feature
    // cannot fire a request against a session that does not exist yet.
    _session.beginAuthentication();
    final result = await _login(
      LoginParams(
        identifier: event.identifier,
        password: event.password,
        rememberDevice: event.rememberDevice,
      ),
    );
    // No code step here. `/auth/login` is the employee-ID / e-mail route used
    // by the admin portal and back office, and it is documented as a *single*
    // request returning the token pair. The OTP challenge belongs to the phone
    // flow — see [_onPhoneLogin].
    emit(result.when(
      // `login` resolves the full profile — permissions and feature flags
      // included — but the session only needs the narrower [User] shape that
      // guards and role checks read.
      success: (profile) {
        final user = profile.toUser();
        _session.setUser(user,
            permissions: profile.permissions,
            territoryCode: profile.territoryCode);
        return AuthenticatedState(user);
      },
      // Never retry a rejected password automatically: five failures lock the
      // account for fifteen minutes, and three background retries would spend
      // three of them.
      failure: (f) => AuthFailureState(_messageFor(f)),
    ));
  }

  /// Step 1 — phone + password. The only call that sees the password.
  Future<void> _onPhoneLogin(
    PhoneLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    _session.beginAuthentication();

    final result = await _repo.sendOtp(
      // Passed through untouched — the server matches on digits.
      phoneNumber: event.phoneNumber,
      password: event.password,
    );

    emit(result.when(
      success: (challenge) {
        _challenge = challenge;
        _destination = event.phoneNumber;
        return AuthOtpRequiredState(
          challenge: challenge,
          destination: event.phoneNumber,
        );
      },
      // An unknown number and a wrong password are reported identically, so
      // the endpoint cannot be used to discover which numbers belong to ISI
      // staff. One message covers both.
      failure: (f) {
        _session.clear();
        return AuthFailureState(_messageFor(f));
      },
    ));
  }

  /// Step 2 then step 3: confirm the code, then exchange the attempt for a
  /// session.
  ///
  /// They are one event because a verified attempt with no token is a dead end
  /// — the user has done everything asked of them, so the exchange follows
  /// immediately rather than waiting for another tap.
  Future<void> _onOtpSubmitted(
    OtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final challenge = _challenge;
    if (challenge == null) {
      // No attempt outstanding — nothing to verify against. Falling back to
      // guest is safer than assuming a session.
      emit(const AuthGuestState());
      return;
    }

    emit(const AuthLoadingState());

    final verified = await _repo.verifyOtp(
      verificationId: challenge.verificationId,
      otp: event.code,
    );

    final failure = verified.when(
      success: (_) => null,
      failure: (f) => f,
    );
    if (failure != null) {
      // Five wrong codes kill the attempt permanently: the correct code will
      // not rescue it, so the user is sent back to step 1 rather than left
      // typing into a dead form.
      final dead = failure.isAttemptDead;
      if (dead) _challenge = null;

      emit(AuthOtpFailureState(
        message: _messageFor(failure),
        attemptDead: dead,
      ));
      return;
    }

    // Step 3. The id is consumed here — a second exchange returns 400.
    final result = await _repo.completePhoneLogin(
        verificationId: challenge.verificationId);

    emit(result.when(
      success: (profile) {
        _challenge = null;
        final user = profile.toUser();
        _session.setUser(user,
            permissions: profile.permissions,
            territoryCode: profile.territoryCode);
        return AuthenticatedState(user);
      },
      failure: (f) {
        // The attempt cannot be retried from the code screen — the id is
        // either spent or stale, so restart from step 1.
        _challenge = null;
        return AuthOtpFailureState(message: _messageFor(f), attemptDead: true);
      },
    ));
  }

  Future<void> _onOtpResend(
    OtpResendRequested event,
    Emitter<AuthState> emit,
  ) async {
    final challenge = _challenge;
    if (challenge == null) return;

    final result =
        await _repo.resendOtp(verificationId: challenge.verificationId);

    emit(result.when(
      success: (fresh) {
        // A fresh window and a reset guess counter.
        _challenge = fresh;
        return AuthOtpRequiredState(
            challenge: fresh, destination: _destination);
      },
      failure: (f) => AuthOtpFailureState(
        message: _messageFor(f),
        // The send budget is spent — "Resend" must disappear and the user
        // start again.
        attemptDead: f.isAttemptDead,
      ),
    ));
  }

  /// Backing out of the code screen abandons the attempt.
  ///
  /// No token exists yet — step 3 never ran — so there is nothing to revoke;
  /// dropping the `verificationId` is the whole of it. This is why the phone
  /// flow is safer than issuing tokens up front: an abandoned challenge leaves
  /// no credential behind at all.
  Future<void> _onOtpAbandoned(
    OtpAbandoned event,
    Emitter<AuthState> emit,
  ) async {
    _challenge = null;
    _destination = null;
    _logger.info('auth.otp.abandoned');
    _session.clear();
    emit(const AuthGuestState());
  }

  /// The text to put in front of the user for [failure].
  ///
  /// Failures raised *by the client* carry English literals written for
  /// developers, and showing those verbatim is why a Khmer session displayed
  /// "No internet connection." in English. Those are translated here, in the
  /// presentation layer, where `.tr` belongs.
  ///
  /// Server failures keep [Failure.message] as-is: the API already localised
  /// it against the `Accept-Language` header this app sends on every request.
  String _messageFor(Failure failure) => switch (failure) {
        NetworkFailure() => 'common.no_connection'.tr,
        // Distinct from the above on purpose: the device *has* a network, so
        // telling the user to check their connection sends them hunting for a
        // problem that is not theirs.
        ServerUnreachableFailure() => 'common.server_unreachable'.tr,
        _ => failure.message,
      };

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
    await _logout(LogoutParams(allDevices: event.allDevices));
    await _sessionReset.clearAll();
    _session.clear();
    emit(const AuthGuestState());

    // Last, so the rebuilt tree reads an already-cleared session.
    _appRestart.restart();
  }
}
