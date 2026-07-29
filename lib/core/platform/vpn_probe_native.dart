import 'dart:io';

/// Android/iOS: scan active network interfaces for common VPN tunnel naming
/// patterns (`tun`, `ppp`, `utun` on iOS). Selected by the conditional export
/// in `vpn_probe.dart`.
Future<bool> probeVpnInterfaces() async {
  final interfaces = await NetworkInterface.list();
  return interfaces.any((i) {
    final name = i.name.toLowerCase();
    return name.startsWith('tun') ||
        name.startsWith('ppp') ||
        name.startsWith('utun');
  });
}
