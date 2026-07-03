import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/services/barcode_scanner_service.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/barcode_scan_screen.dart';
import 'package:isi_steel_sales_mobile/routes/app_routes.dart';

/// The real `mobile_scanner`-backed implementation. Pushes via the app's
/// global [navigatorKey] rather than requiring a `BuildContext` on the
/// domain-facing interface, so [BarcodeScannerService] itself stays UI-free.
class MobileBarcodeScannerService implements BarcodeScannerService {
  const MobileBarcodeScannerService();

  @override
  Future<String?> scan() async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return null;
    return navigator.push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScanScreen()),
    );
  }
}
