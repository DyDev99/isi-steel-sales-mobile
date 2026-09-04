import 'package:isi_steel_sales_mobile/core/config/env.dart';

/// The effective runtime configuration: the compiled [Env] values, with an
/// optional launch-time override on top.
///
/// [Env] is baked in by Envied at build time, so repointing the app at a
/// different host normally means editing `.env` and re-running
/// `build_runner` — a slow round trip for a value that, with a Cloudflare
/// quick tunnel, changes on every restart of the backend. That friction is how
/// a stale host ends up compiled into a build nobody notices is wrong.
///
/// So both hosts also accept a `--dart-define`:
///
/// ```
/// flutter run --dart-define=API_BASE_URL=https://new-tunnel.trycloudflare.com
/// ```
///
/// The override is compile-time-constant (`String.fromEnvironment`), so it
/// costs nothing at runtime and is tree-shaken away when unused. **Everything
/// that talks to the API must read these getters rather than [Env] directly**,
/// or the override silently applies to some requests and not others — which is
/// worse than not having it at all.
///
/// Note this deliberately does *not* wrap `Env.dbSalt`: overriding the salt
/// from the command line would make the encrypted database unreadable on the
/// next launch without it, and that is not a thing to leave one flag away.
abstract final class AppConfig {
  const AppConfig._();

  static const String _apiBaseUrlOverride =
      String.fromEnvironment('API_BASE_URL');

  static const String _sapApiUrlOverride =
      String.fromEnvironment('SAP_API_URL');

  /// Root of the ISI API — scheme and host, no trailing slash and no
  /// `/api/v1`; `AppConstants.apiPrefix` supplies that.
  static String get apiBaseUrl =>
      _apiBaseUrlOverride.isNotEmpty ? _apiBaseUrlOverride : Env.apiBaseUrl;

  /// Target of the ADR-005 reachability probe.
  ///
  /// Falls back to [apiBaseUrl] rather than to `Env.sapApiUrl` when only
  /// `API_BASE_URL` is overridden: the two normally name the same host, and
  /// probing the *old* host to decide whether the *new* one is reachable would
  /// report the app offline while the API answers perfectly.
  static String get sapApiUrl {
    if (_sapApiUrlOverride.isNotEmpty) return _sapApiUrlOverride;
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    return Env.sapApiUrl;
  }

  /// True when a launch-time override is in play. Logged at startup so a build
  /// pointing somewhere unexpected explains itself in the console.
  static bool get hasOverride =>
      _apiBaseUrlOverride.isNotEmpty || _sapApiUrlOverride.isNotEmpty;
}
