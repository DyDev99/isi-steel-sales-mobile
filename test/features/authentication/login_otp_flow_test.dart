import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/logging/app_logger.dart';
import 'package:isi_steel_sales_mobile/core/session/app_restart_controller.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/core/session/session_scoped_store.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/auth_profile.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/otp_challenge.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/repositories/auth_repository.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/usecases/get_current_user.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/usecases/login.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/usecases/logout.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/notification_lifecycle.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_event.dart';
import 'package:isi_steel_sales_mobile/features/authentication/presentation/bloc/auth_state.dart';
import 'package:mocktail/mocktail.dart';

const _logger = ConsoleAppLogger(verbose: false);

const _profile = AuthProfile(
  id: 'u-1',
  employeeId: 'EMP000202',
  email: 'rep@isigroup.com.kh',
  fullName: 'Sok Dara',
  permissions: {'outlets.read'},
);

/// Non-default values on purpose: the screen must take these from the server
/// rather than hard-coding 6 and 300.
const _challenge = OtpChallenge(
  verificationId: '019ffa68-ff2a-78f1-98ad-b356bc325fb6',
  expiresIn: 120,
  otpLength: 4,
);

class _MockLogin extends Mock implements Login {}

class _MockLogout extends Mock implements Logout {}

class _MockGetCurrentUser extends Mock implements GetCurrentUser {}

class _MockRepo extends Mock implements AuthRepository {}

class _NoopStore implements SessionScopedStore {
  @override
  String get debugName => 'noop';
  @override
  Future<void> clearForSignOut() async {}
}

/// The sales app signs in with **phone + password + OTP** — three requests:
/// `send-otp` checks the password and returns a `verificationId`, `verify-otp`
/// confirms the code and issues *no token*, and `mobile/auth/login` exchanges
/// the verified attempt for the pair.
/// The notification hooks are irrelevant to the OTP flow, but `AuthBloc`
/// requires them — see [NotificationLifecycle] for why the dependency is an
/// interface rather than the coordinator itself.
class _NoopNotifications implements NotificationLifecycle {
  const _NoopNotifications();

  @override
  Future<void> onSignedIn() async {}

  @override
  Future<void> onSigningOut() async {}
}

void main() {
  late _MockRepo repo;
  late SessionManager session;

  setUpAll(() => registerFallbackValue(const LogoutParams()));

  AuthBloc build() => AuthBloc(
        login: _MockLogin(),
        logout: _MockLogout(),
        getCurrentUser: _MockGetCurrentUser(),
        sessionManager: session,
        sessionReset: SessionResetService([_NoopStore()], _logger),
        appRestart: AppRestartController(),
        repository: repo,
        logger: _logger,
        notifications: const _NoopNotifications(),
      );

  setUp(() {
    repo = _MockRepo();
    session = SessionManager();

    when(() => repo.sendOtp(
          phoneNumber: any(named: 'phoneNumber'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => const Success(_challenge));
    when(() => repo.verifyOtp(
          verificationId: any(named: 'verificationId'),
          otp: any(named: 'otp'),
        )).thenAnswer((_) async => const Success(null));
    when(() => repo.completePhoneLogin(
            verificationId: any(named: 'verificationId')))
        .thenAnswer((_) async => const Success(_profile));
  });

  tearDown(() => session.dispose());

  Future<AuthBloc> atCodeScreen() async {
    final bloc = build();
    bloc.add(const PhoneLoginSubmitted(
        phoneNumber: '012 345 201', password: 'secret'));
    await bloc.stream.firstWhere((s) => s is AuthOtpRequiredState);
    return bloc;
  }

  group('step 1 — send-otp', () {
    test('the phone number is sent exactly as typed', () async {
      // The server matches on digits, so `012 345 201` and `+855 12 345 201`
      // resolve to the same account. Reformatting here could only break a form
      // the server already accepts.
      final bloc = await atCodeScreen();

      verify(() => repo.sendOtp(
            phoneNumber: '012 345 201',
            password: 'secret',
          )).called(1);
      await bloc.close();
    });

    test('no session exists while the code is outstanding', () async {
      // Step 3 has not run, so there is no token at all — not merely an
      // uncommitted one. Every gated feature must stay shut.
      final bloc = await atCodeScreen();

      expect(session.isAuthenticated, isFalse);
      expect(session.canCallProtectedApi, isFalse);
      await bloc.close();
    });

    test('the screen is sized from the server, not from constants', () async {
      final bloc = await atCodeScreen();
      final state = bloc.state as AuthOtpRequiredState;

      expect(state.challenge.otpLength, 4);
      expect(state.challenge.window, const Duration(seconds: 120));
      await bloc.close();
    });

    test('a wrong password never reaches the code screen', () async {
      when(() => repo.sendOtp(
            phoneNumber: any(named: 'phoneNumber'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => const Failed(AuthenticationFailure(
            message: 'bad',
            code: 'Auth.InvalidCredentials',
          )));
      final bloc = build();

      bloc.add(const PhoneLoginSubmitted(
          phoneNumber: '012345201', password: 'wrong'));
      await expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoadingState>(), isA<AuthFailureState>()]),
      );
      await bloc.close();
    });
  });

  group('steps 2 and 3 — verify then exchange', () {
    test('the right code verifies then exchanges, in that order', () async {
      final bloc = await atCodeScreen();

      bloc.add(const OtpSubmitted('1234'));
      await bloc.stream.firstWhere((s) => s is AuthenticatedState);

      verifyInOrder([
        () => repo.verifyOtp(
            verificationId: _challenge.verificationId, otp: '1234'),
        () =>
            repo.completePhoneLogin(verificationId: _challenge.verificationId),
      ]);
      expect(session.isAuthenticated, isTrue);
      await bloc.close();
    });

    test('a plain wrong code keeps the attempt alive', () async {
      when(() => repo.verifyOtp(
            verificationId: any(named: 'verificationId'),
            otp: any(named: 'otp'),
          )).thenAnswer((_) async => const Failed(AuthenticationFailure(
            message: 'wrong',
            code: 'Auth.InvalidVerificationCode',
          )));
      final bloc = await atCodeScreen();

      bloc.add(const OtpSubmitted('0000'));
      final state = await bloc.stream.firstWhere(
          (s) => s is AuthOtpFailureState) as AuthOtpFailureState;

      expect(state.attemptDead, isFalse, reason: 'they may try again');
      // Never exchange an unverified attempt — that is the client bug the API
      // reports as Auth.VerificationNotCompleted.
      verifyNever(() => repo.completePhoneLogin(
          verificationId: any(named: 'verificationId')));
      await bloc.close();
    });

    test('five wrong codes kill the attempt', () async {
      // The fifth returns Auth.VerificationBlocked and the attempt is dead —
      // the correct code will not rescue it.
      when(() => repo.verifyOtp(
            verificationId: any(named: 'verificationId'),
            otp: any(named: 'otp'),
          )).thenAnswer((_) async => const Failed(AuthenticationFailure(
            message: 'blocked',
            code: 'Auth.VerificationBlocked',
          )));
      final bloc = await atCodeScreen();

      bloc.add(const OtpSubmitted('0000'));
      final state = await bloc.stream.firstWhere(
          (s) => s is AuthOtpFailureState) as AuthOtpFailureState;

      expect(state.attemptDead, isTrue);

      // The id is dropped, so a later submit cannot resurrect it.
      bloc.add(const OtpSubmitted('1234'));
      await bloc.stream.firstWhere((s) => s is AuthGuestState);
      await bloc.close();
    });

    test('an expired window is also fatal to the attempt', () async {
      when(() => repo.verifyOtp(
            verificationId: any(named: 'verificationId'),
            otp: any(named: 'otp'),
          )).thenAnswer((_) async => const Failed(AuthenticationFailure(
            message: 'expired',
            code: 'Auth.VerificationExpired',
          )));
      final bloc = await atCodeScreen();

      bloc.add(const OtpSubmitted('1234'));
      final state = await bloc.stream.firstWhere(
          (s) => s is AuthOtpFailureState) as AuthOtpFailureState;

      expect(state.attemptDead, isTrue);
      await bloc.close();
    });
  });

  group('resend', () {
    test('a fresh challenge replaces the spent one', () async {
      const fresh = OtpChallenge(
        verificationId: 'new-id',
        expiresIn: 300,
        otpLength: 4,
      );
      when(() => repo.resendOtp(verificationId: any(named: 'verificationId')))
          .thenAnswer((_) async => const Success(fresh));
      final bloc = await atCodeScreen();

      bloc.add(const OtpResendRequested());
      final state = await bloc.stream.firstWhere(
          (s) => s is AuthOtpRequiredState) as AuthOtpRequiredState;

      expect(state.challenge.verificationId, 'new-id');

      // Subsequent verification uses the new id, not the old one.
      bloc.add(const OtpSubmitted('1234'));
      await bloc.stream.firstWhere((s) => s is AuthenticatedState);
      verify(() => repo.verifyOtp(verificationId: 'new-id', otp: '1234'))
          .called(1);
      await bloc.close();
    });

    test('the send budget running out kills the attempt', () async {
      when(() => repo.resendOtp(verificationId: any(named: 'verificationId')))
          .thenAnswer((_) async => const Failed(AuthenticationFailure(
                message: 'no more',
                code: 'Auth.ResendLimitReached',
              )));
      final bloc = await atCodeScreen();

      bloc.add(const OtpResendRequested());
      final state = await bloc.stream.firstWhere(
          (s) => s is AuthOtpFailureState) as AuthOtpFailureState;

      // "Resend" must disappear and the user start again from step 1.
      expect(state.attemptDead, isTrue);
      await bloc.close();
    });
  });

  test('abandoning leaves no credential behind', () async {
    // No token was ever issued — step 3 never ran — so there is nothing to
    // revoke. This is why the phone flow is safer than issuing tokens up front.
    final bloc = await atCodeScreen();

    bloc.add(const OtpAbandoned());
    await bloc.stream.firstWhere((s) => s is AuthGuestState);

    expect(session.state, AuthenticationState.guest);
    verifyNever(() => repo.completePhoneLogin(
        verificationId: any(named: 'verificationId')));
    await bloc.close();
  });
}
