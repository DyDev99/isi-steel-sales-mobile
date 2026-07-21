import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:isi_steel_sales_mobile/core/config/env.dart';

/// Reproduces the app's SAP network path outside Flutter, so a transport
/// failure can be diagnosed in seconds instead of via an emulator round-trip.
///
/// Run with: `dart run tool/sap_tls_probe.dart`
///
/// Deliberately mirrors `DioFactory._applyTls` exactly — same pin source
/// ([Env.sapCertSha256]), same base64-SHA-256-of-DER comparison, same
/// fail-closed behaviour — so a result here is a result for the app. It sends
/// an empty JSON body, never credentials: the server answers `400` to that,
/// which is enough to prove the whole path works end to end.
///
/// This is a diagnostic tool, not a test: it performs real network I/O against
/// an IP-allowlisted host and therefore cannot run in CI.
Future<void> main() async {
  final target = Env.sapBaseUrlPrimary;
  final uri = Uri.parse('$target/api/Auth/Login');

  stdout.writeln('target        : $uri');
  stdout.writeln('pin configured: ${Env.sapCertSha256.isNotEmpty}');
  stdout.writeln('pin length    : ${Env.sapCertSha256.length}');
  stdout.writeln('');

  final client = HttpClient()
    ..badCertificateCallback = (cert, host, port) {
      final presented = base64.encode(sha256.convert(cert.der).bytes);
      final matches = presented == Env.sapCertSha256;
      stdout.writeln('badCertificateCallback fired for $host:$port');
      stdout.writeln('  presented : $presented');
      stdout.writeln('  expected  : ${Env.sapCertSha256}');
      stdout.writeln('  MATCH     : $matches');
      stdout.writeln('');
      return matches;
    };

  // Several scenarios, because *which* of them fails localises the server-side
  // cause: renegotiation requested for the whole binding, or only for the path
  // that has optional client-certificate negotiation enabled.
  await _attempt(client, 'GET  /swagger/index.html', () async {
    return (await client.getUrl(Uri.parse('$target/swagger/index.html')))
        .close();
  });

  await _attempt(client, 'POST /api/Auth/Login', () async {
    final r = await client.postUrl(uri);
    r.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    r.headers.set(HttpHeaders.acceptHeader, '*/*');
    r.write(jsonEncode(const <String, String>{}));
    return r.close();
  });

  await _attempt(client, 'POST /api/Auth/Login (Connection: close)', () async {
    final r = await client.postUrl(uri);
    r.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    r.headers.set(HttpHeaders.acceptHeader, '*/*');
    // Forces a fresh connection per request. If keep-alive reuse is what
    // triggers the renegotiation, this is a legitimate client-side fix.
    r.headers.set(HttpHeaders.connectionHeader, 'close');
    r.write(jsonEncode(const <String, String>{}));
    return r.close();
  });

  client.close(force: true);
}

Future<void> _attempt(
  HttpClient client,
  String label,
  Future<HttpClientResponse> Function() send,
) async {
  try {
    final response = await send();
    final body = await response.transform(utf8.decoder).join();
    stdout.writeln('$label -> HTTP ${response.statusCode}  '
        '(${body.length} bytes)');
  } catch (e) {
    stdout.writeln('$label -> ${e.runtimeType}');
    final text = e.toString().replaceAll('\n', ' ').trim();
    stdout.writeln(
      '    ${text.length > 160 ? '${text.substring(0, 160)}…' : text}',
    );
  }
}
