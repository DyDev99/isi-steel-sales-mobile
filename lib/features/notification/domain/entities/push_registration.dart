import 'package:equatable/equatable.dart';

/// Which platform a registration belongs to
/// (`docs/feature/notification/README.md` §4.2).
///
/// The backend stores an unrecognised value as `Unknown` rather than rejecting
/// it, so this is a display/routing hint on the server side, never a gate.
enum PushPlatform {
  android('Android'),
  ios('IOS'),
  web('Web');

  const PushPlatform(this.code);

  final String code;
}

/// Whether the OS will let us draw a notification.
///
/// [notDetermined] is a distinct, load-bearing state: §14 forbids requesting
/// the permission on first launch, so "we have not asked yet" must be
/// distinguishable from "the rep said no". iOS gives exactly one prompt ever,
/// and spending it on a cold user is how an app ends up permanently silent.
enum PushPermissionStatus {
  /// Never asked. The explainer card is due.
  notDetermined,

  /// Granted — full alerts.
  granted,

  /// Granted, but delivered quietly (iOS provisional / Android channel muted).
  /// Counts as granted for registration purposes: the notification still
  /// arrives, and the backend only needs to know whether to include this
  /// device in the push audience.
  provisional,

  /// The rep declined. Register anyway with `pushPermissionGranted: false` so
  /// the inbox keeps syncing and the delivery log reads `NO_DEVICE` instead of
  /// a run of failures.
  denied,

  /// No push transport in this build at all — the web target. Not an error.
  unsupported;

  /// True when the backend should include this installation in the push
  /// audience.
  bool get allowsPush => this == granted || this == provisional;

  /// True when the explainer may still be shown, i.e. asking could change the
  /// answer.
  bool get canPrompt => this == notDetermined;
}

/// What this installation tells `POST /mobile/devices/register` about itself.
///
/// ## `deviceId` is the upsert key
///
/// It identifies an **installation, not a person and not a token**. It must
/// survive restarts and may change on reinstall. §4.2 is blunt about the
/// failure mode: get it wrong and every launch creates a duplicate row.
///
/// **Never use the FCM token as `deviceId`** — tokens rotate, installations do
/// not. This app reuses the identifier `DeviceIdentity` already mints and keeps
/// in secure storage for `/auth/login` and `/auth/refresh`, so one installation
/// has one identity everywhere rather than two that drift apart.
class PushRegistration extends Equatable {
  const PushRegistration({
    required this.deviceId,
    required this.pushToken,
    required this.platform,
    required this.pushPermissionGranted,
    this.deviceName,
    this.appVersion,
    this.osVersion,
    this.locale,
    this.timeZone,
  });

  final String deviceId;

  /// From `FirebaseMessaging.getToken()`. Required by the endpoint — a missing
  /// one answers `400 Notification.PushTokenRequired`, which the error table
  /// says to fix by retrying `getToken()`, not by sending an empty string.
  final String pushToken;

  final PushPlatform platform;

  /// Send `false` when the rep declined. The registration is *kept* — the inbox
  /// still syncs — and simply excluded from the push audience.
  final bool pushPermissionGranted;

  /// Shown to support in the device registry, so it should read like a handset
  /// rather than a GUID.
  final String? deviceName;

  final String? appVersion;
  final String? osVersion;

  /// BCP 47. Decides which language future notifications render in.
  final String? locale;

  /// **IANA zone** (`Asia/Phnom_Penh`), not an abbreviation.
  ///
  /// Quiet hours and digests are wall-clock facts. Without this the backend has
  /// to assume UTC, and a rep's 22:00 quiet window then starts at 05:00 local —
  /// which looks like the feature is simply broken.
  final String? timeZone;

  @override
  List<Object?> get props => [
        deviceId,
        pushToken,
        platform,
        pushPermissionGranted,
        deviceName,
        appVersion,
        osVersion,
        locale,
        timeZone,
      ];
}

/// What the backend echoes back after a successful registration (§4.3).
///
/// A registration the backend had previously deactivated — because FCM reported
/// the token dead — is **revived** by the call, so [isActive] coming back true
/// after a period of silence is the expected outcome, not a surprise. A rep
/// never needs an administrator to start receiving notifications again.
class PushRegistrationResult extends Equatable {
  const PushRegistrationResult({
    required this.id,
    required this.deviceId,
    required this.isActive,
    required this.pushPermissionGranted,
    this.lastSeenAt,
  });

  final String id;
  final String deviceId;
  final bool isActive;
  final bool pushPermissionGranted;
  final DateTime? lastSeenAt;

  @override
  List<Object?> get props =>
      [id, deviceId, isActive, pushPermissionGranted, lastSeenAt];
}
