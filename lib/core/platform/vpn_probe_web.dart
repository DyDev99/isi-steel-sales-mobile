/// Web: VPN detection is not possible from a browser.
///
/// The mobile heuristic enumerates network interfaces via `dart:io`'s
/// `NetworkInterface.list()`. Browsers deliberately expose no equivalent — the
/// local network topology is not reachable from page JavaScript, and that is a
/// privacy protection, not a gap to route around.
///
/// This returns `false` (meaning "no VPN detected"), which makes the web build
/// **permissive**: a rep using a VPN to spoof their apparent location would not
/// be flagged by this heuristic on web, whereas they might be on mobile.
///
/// That is a real, accepted weakening of an anti-fraud control on this platform,
/// not an oversight. It is tagged below so the release checklist catches it.
///
// TODO(release-gate): `SECURITY.md` §11 — the web build has no VPN detection.
// Decide before any web release whether that is acceptable for the surfaces web
// exposes, or whether location-sensitive actions (geofenced check-in, visit
// capture) must be mobile-only. Tracked in `docs/flutter-web.md` §"Open items".
Future<bool> probeVpnInterfaces() async => false;
