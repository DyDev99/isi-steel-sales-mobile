import 'package:flutter/foundation.dart';
import 'package:isi_steel_sales_mobile/core/config/app_config.dart';

/// How SAP requests leave the device.
///
/// `NO_RENEGOTIATION` is thrown by BoringSSL inside Dart's own TLS engine when
/// the server asks to renegotiate mid-connection — typically to request a
/// client certificate after the handshake completed. It fires below any Dart
/// callback, which is why `badCertificateCallback` cannot intercept it: the fix
/// must change the transport, not the trust decision.
enum SapTransport {
  /// `http://` — no TLS engine involved, so neither renegotiation nor
  /// certificate validation can fail. Requires the cleartext exemption in
  /// `res/xml/network_security_config.xml`. **Local development only.**
  cleartext,

  /// `https://` via Dart's BoringSSL, accepting the SAP host's self-signed
  /// cert in debug. This is the mode that throws `NO_RENEGOTIATION` against a
  /// renegotiating facade; it is fine against TLS 1.3, where renegotiation does
  /// not exist as a mechanism.
  dart,

  // TODO(transport): restore a `native` mode (Cronet / NSURLSession).
  // Blocked upstream: cronet_http 141.x ships cronet-api and cronet-shared
  // with the same declared `org.chromium.net` namespace, which AGP 8+ rejects
  // at :app:processDebugMainManifest.
}

/// Transport policy for the SAP host.
///
/// **This class deliberately owns no host or port.** Those live in `.env` and
/// are read through [SapConfig], which is what the DI graph and any other Dio
/// instance already use. An earlier version kept its own copy of the address,
/// and the two silently disagreed: the auth trace printed `http://` from here
/// while the socket dialled `https://` from `Env` — a log that contradicts the
/// connection is worse than no log at all.
///
/// The only thing rewritten below is the **scheme**. Host, port and path stay
/// exactly as configured.
abstract final class SapTransportConfig {
  const SapTransportConfig._();

  /// Set per-run so the committed default is never the wrong one:
  ///   flutter run --dart-define=SAP_TRANSPORT=cleartext
  static const String _override =
      String.fromEnvironment('SAP_TRANSPORT', defaultValue: '');

  static const SapTransport _debugDefault = SapTransport.cleartext;

  /// Release builds can never resolve to cleartext, whatever the define says.
  /// A stray `--dart-define` in CI must not be able to ship a plaintext
  /// credential POST (docs/SECURITY.md §6).
  static SapTransport get transport {
    if (kReleaseMode) return SapTransport.dart;
    return switch (_override) {
      'cleartext' => SapTransport.cleartext,
      'dart' => SapTransport.dart,
      _ => _debugDefault,
    };
  }

  static String get scheme =>
      transport == SapTransport.cleartext ? 'http' : 'https';

  /// [SapConfig.primaryBaseUrl] with the scheme forced to match [transport].
  ///
  /// Note this only governs Dio instances built by `createSapDio`. If the
  /// `.env` value itself says `https://` and some other registration reads
  /// `SapConfig` directly, that instance is unaffected — which is exactly the
  /// bug this comment exists to make findable. Change `.env` to be certain.
  static String get primaryBaseUrl => _withScheme(SapConfig.primaryBaseUrl);

  static String get fallbackBaseUrl => _withScheme(SapConfig.fallbackBaseUrl);

  /// Host only, for the debug `badCertificateCallback` allow-list.
  static String get host => Uri.parse(SapConfig.primaryBaseUrl).host;

  static String _withScheme(String url) {
    final uri = Uri.parse(url);
    // `replace` preserves an explicit port, so :4451 survives the rewrite.
    return uri.replace(scheme: scheme).toString();
  }

  /// Printed in the auth trace. Includes the raw configured value so a
  /// scheme rewrite is visible next to what `.env` actually says.
  static String get describe {
    final label = switch (transport) {
      SapTransport.cleartext => 'cleartext (no TLS engine)',
      SapTransport.dart => 'dart BoringSSL (renegotiating server WILL fail)',
    };
    return '$label — env=${SapConfig.primaryBaseUrl} '
        'effective=$primaryBaseUrl';
  }
}