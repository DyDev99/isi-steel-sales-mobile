import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Severity of a log record. Ordered: [debug] is the most verbose.
enum LogLevel { debug, info, warning, error }

/// Structured, PII-free application logger.
///
/// Implements `docs/SECURITY.md` §10 (MASVS-PRIVACY / MASVS-CODE), which is a
/// **hard constraint on every logging call in the codebase**, not a guideline:
///
/// - **Never logged**: passwords, JWT/tokens, API keys, customer information,
///   phone numbers, emails, revenue data.
/// - **Allowed**: API endpoint, response code, error code, and — in development
///   builds only — exception stack traces (stripped from release per §11).
///
/// Callers pass an [event] name plus structured [fields] rather than an
/// interpolated sentence, so records stay greppable and machine-readable and so
/// every value can be run through [LogRedactor] before it is emitted. Defence in
/// depth: a caller that passes PII by mistake gets it redacted rather than
/// leaked, but callers are still expected not to pass it (§10).
///
/// This is deliberately the only logging surface in `core/` — see
/// `docs/ENGINEERING_STANDARD.md` §7: a `catch` block either rethrows a typed
/// `Failure` or logs through this logger. Silent `catch (_) {}` is not
/// acceptable in reviewed code.
abstract interface class AppLogger {
  /// Verbose diagnostics. Suppressed in release builds (`SECURITY.md` §11).
  void debug(String event, {Map<String, Object?>? fields});

  /// Notable lifecycle events (bootstrap steps, connectivity transitions).
  /// Suppressed in release builds (`SECURITY.md` §11).
  void info(String event, {Map<String, Object?>? fields});

  /// Recoverable problems worth surfacing. Retained in release builds.
  void warning(String event, {Map<String, Object?>? fields});

  /// Failures. Retained in release builds; [stackTrace] is emitted only in
  /// development builds (`SECURITY.md` §10, §11).
  void error(
    String event, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? fields,
  });
}

/// Default [AppLogger]: emits via `dart:developer` so records surface in the
/// IDE/DevTools without adding a third-party logging dependency (a new package
/// would need the maintenance/trust check in `docs/SECURITY.md` §14).
///
/// Release behaviour per `SECURITY.md` §11 ("verbose logging disabled"):
/// [debug] and [info] are dropped entirely; [warning]/[error] are kept without
/// stack traces so field failures remain diagnosable without leaking internals.
class ConsoleAppLogger implements AppLogger {
  const ConsoleAppLogger({
    LogRedactor redactor = const LogRedactor(),
    bool? verbose,
  })  : _redactor = redactor,
        _verbose = verbose ?? !kReleaseMode;

  final LogRedactor _redactor;

  /// When false, [debug]/[info] are dropped and stack traces are withheld.
  final bool _verbose;

  @override
  void debug(String event, {Map<String, Object?>? fields}) =>
      _emit(LogLevel.debug, event, fields);

  @override
  void info(String event, {Map<String, Object?>? fields}) =>
      _emit(LogLevel.info, event, fields);

  @override
  void warning(String event, {Map<String, Object?>? fields}) =>
      _emit(LogLevel.warning, event, fields);

  @override
  void error(
    String event, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? fields,
  }) =>
      _emit(
        LogLevel.error,
        event,
        fields,
        error: error,
        stackTrace: stackTrace,
      );

  void _emit(
    LogLevel level,
    String event,
    Map<String, Object?>? fields, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    // §11: no verbose logging in release builds.
    if (!_verbose && (level == LogLevel.debug || level == LogLevel.info)) {
      return;
    }

    final safeFields = _redactor.redact(fields);
    final buffer = StringBuffer(event);
    if (safeFields.isNotEmpty) {
      buffer.write(' ');
      buffer.write(
          safeFields.entries.map((e) => '${e.key}=${e.value}').join(' '));
    }

    // `developer.log` alone reaches DevTools and the `flutter run` console, but
    // **not** `adb logcat` — nothing it writes appears as an `I/flutter` line.
    // That made every structured log invisible to anyone debugging on-device
    // from logcat: a `connectivity.probe_failed` record explaining exactly why
    // the app was offline was being written to a channel the reader could not
    // see. `debugPrint` is the only sink that reaches logcat, so debug builds
    // emit to both. Release builds are unaffected — `_verbose` is false there,
    // and `debug`/`info` never reach this line at all.
    if (_verbose) {
      debugPrint('[isi.${level.name}] ${buffer.toString()}');
      if (error != null) {
        debugPrint('  error: ${_redactor.redactValue('error', error)}');
      }
    }

    developer.log(
      buffer.toString(),
      name: 'isi.${level.name}',
      level: _severity(level),
      // The exception *type* is diagnostic; its message may embed PII (a failed
      // request body, a customer name), so it is redacted like any other value.
      error: error == null ? null : _redactor.redactValue('error', error),
      // §10: stack traces are development-only.
      stackTrace: _verbose ? stackTrace : null,
    );
  }

  /// Maps to `dart:developer` levels, which follow `package:logging` values.
  int _severity(LogLevel level) => switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warning => 900,
        LogLevel.error => 1000,
      };
}

/// Redacts values that `docs/SECURITY.md` §10 forbids logging.
///
/// Two independent passes, because either alone is insufficient:
///  1. **Key-name matching** — catches `token`, `email`, `customerName`, …
///     regardless of the value's shape.
///  2. **Value-shape matching** — catches a JWT or an email address that
///     arrived under an innocuous key (e.g. `{'v': 'a.b.c'}`).
///
/// Bias is deliberately toward over-redaction: losing a debuggable value is
/// recoverable, leaking customer PII or a token into a log sink is not.
class LogRedactor {
  const LogRedactor();

  static const String placeholder = '***REDACTED***';

  /// Key fragments that imply a §10-forbidden value. Matched case-insensitively
  /// against the whole key, so `refreshToken` and `refresh_token` both hit.
  ///
  /// `code` is deliberately absent: §10 explicitly *allows* response and error
  /// codes, and they are the primary diagnostic signal for network failures.
  static final RegExp _sensitiveKey = RegExp(
    r'(pass|pwd|secret|token|jwt|bearer|auth|apikey|api_key|credential'
    r'|email|mail|phone|mobile|msisdn|contact'
    r'|customer|owner|shop|address|province|district'
    r'|revenue|price|amount|total|credit|balance|salary|discount'
    r'|lat|lng|longitude|latitude|geo|coord'
    r'|name|user|account|session|device_id|deviceid)',
    caseSensitive: false,
  );

  /// A three-segment dot-delimited base64url blob — i.e. a JWT.
  static final RegExp _jwtValue = RegExp(
    r'^[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}$',
  );

  static final RegExp _emailValue = RegExp(
    r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}',
  );

  /// Seven or more consecutive digits — a phone number, account number, or an
  /// MSISDN. Short digit runs (status codes, counts, attempts) are preserved.
  static final RegExp _longDigitRun = RegExp(r'\d{7,}');

  /// Returns a copy of [fields] safe to emit. Never returns null, so callers
  /// don't branch on emptiness.
  Map<String, Object?> redact(Map<String, Object?>? fields) {
    if (fields == null || fields.isEmpty) return const {};
    return {
      for (final entry in fields.entries)
        entry.key: redactValue(entry.key, entry.value),
    };
  }

  /// Redacts a single [value] given its [key]. Exposed so callers logging a
  /// bare exception object get the same value-shape protection.
  Object? redactValue(String key, Object? value) {
    if (value == null) return null;
    if (_sensitiveKey.hasMatch(key)) return placeholder;

    // Recurse so nested payloads can't smuggle PII past the key check.
    if (value is Map) {
      return {
        for (final entry in value.entries)
          '${entry.key}': redactValue('${entry.key}', entry.value),
      };
    }
    if (value is Iterable) {
      return value.map((e) => redactValue(key, e)).toList();
    }

    // Booleans and small numbers are shape-safe; a huge int could be an account
    // number, so it still goes through the string check below.
    if (value is bool) return value;

    final text = value.toString();
    if (_jwtValue.hasMatch(text)) return placeholder;
    if (_emailValue.hasMatch(text)) return placeholder;
    if (_longDigitRun.hasMatch(text)) return placeholder;
    return value;
  }
}
