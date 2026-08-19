import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/app_theme.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/bloc/home_cubit.dart';
import 'package:isi_steel_sales_mobile/features/shell/presentation/widgets/my_work_grid_section.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await LocalizationService.instance.load('en');
    for (final f in [
      'assets/fonts/ABCGinto-Regular.ttf',
      'assets/fonts/ABCGinto-Bold.ttf',
    ]) {
      final file = File(f);
      if (!file.existsSync()) continue;
      final loader = FontLoader('ABC Ginto')
        ..addFont(Future.value(file.readAsBytesSync().buffer.asByteData()));
      await loader.load();
    }
    if (!sl.isRegistered<ShellTabController>()) {
      sl.registerLazySingleton<ShellTabController>(() => ShellTabController());
    }
  });

  testWidgets('preview', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        theme: AppTheme.light('ABC Ginto'),
        home: MediaQuery(
          // Pin the icons to their settled frame so the still is representative.
          data: const MediaQueryData(
              size: Size(390, 844), disableAnimations: true),
          child: const Scaffold(
            body: SingleChildScrollView(child: MyWorkGridSection()),
          ),
        ),
      ),
    ));
    // Discrete frames: ShimmerLoading repeats forever, so pumpAndSettle hangs.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MyWorkGridSection),
      matchesGoldenFile('_preview/workgrid.png'),
    );
  });
}
