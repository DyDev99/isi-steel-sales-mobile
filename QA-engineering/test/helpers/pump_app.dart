import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

extension PumpApp on WidgetTester {
  /// Wraps [widget] in MaterialApp + Scaffold so it renders like in the app.
  /// Add your app theme, localization delegates and providers here.
  Future<void> pumpApp(Widget widget, {Size size = const Size(390, 844)}) async {
    view.physicalSize = size;
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);
    await pumpWidget(MaterialApp(home: Scaffold(body: widget)));
  }
}
