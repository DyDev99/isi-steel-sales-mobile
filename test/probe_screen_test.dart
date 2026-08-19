import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/inventory_visible/inventory_visible_screen.dart';

void main() {
  testWidgets('probe', (tester) async {
    await LocalizationService.instance.load('en');
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: InventoryVisibilityScreen(depotName: 'D', onSubmit: () {}),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    final ex = tester.takeException();
    print('EXCEPTION: $ex');
    final texts = tester.widgetList<Text>(find.byType(Text))
        .map((t) => t.data).where((d) => d != null).toList();
    print('TEXTS(${texts.length}): $texts');
  });
}
