import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/config/env.dart';

/// Guards the shape of the SAP certificate pin as it arrives *in the binary*.
///
/// Base64 of a SHA-256 digest is 44 characters and ends in `=`. A `.env` parser
/// that splits a `KEY=VALUE` line on every `=` instead of only the first one
/// silently drops that trailing character, yielding a 43-character pin that can
/// never match — and the failure surfaces far away, as an unexplained TLS
/// handshake error at runtime rather than a config error at build time.
///
/// Asserts structure, not the literal value: the digest is infrastructure
/// detail that would go stale at every certificate renewal, and the invariant
/// is what actually protects us.
void main() {
  group('Env.sapCertSha256', () {
    test('is present — an empty pin fails closed and blocks every SAP call',
        () {
      expect(
        Env.sapCertSha256,
        isNotEmpty,
        reason: 'SAP_CERT_SHA256 is empty in the .env used for this build. '
            'ApiConfig treats that as fail-closed, so every SAP request is '
            'refused before it is sent.',
      );
    });

    test('survived .env parsing intact (44 chars, base64 padded)', () {
      expect(
        Env.sapCertSha256.length,
        44,
        reason: 'Expected 44 chars (base64 of a 32-byte SHA-256). A length of '
            '43 means the trailing "=" was lost while parsing the .env line.',
      );
      expect(
        Env.sapCertSha256.endsWith('='),
        isTrue,
        reason: 'Base64 of 32 bytes is always "=" padded. Its absence means '
            'the value was truncated on the way into the binary.',
      );
    });

    test('decodes to exactly 32 bytes — a real SHA-256 digest', () {
      final bytes = base64.decode(Env.sapCertSha256);
      expect(bytes.length, 32);
    });
  });
}
