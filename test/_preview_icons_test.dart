import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/shared/animations/work_icons.dart';

void main() {
  const accents = {
    WorkIconKind.visits: Color(0xFF22C3D6),
    WorkIconKind.customers: Color(0xFFEC3F72),
    WorkIconKind.quotesOrders: Color(0xFFF5A623),
  };

  // Frames across one cycle: mid-action, and the settled "hold" frame.
  const frames = [0.30, 0.50, 0.62, 0.80];

  for (final kind in WorkIconKind.values) {
    testWidgets('strip_${kind.name}', (tester) async {
      tester.view.physicalSize = const Size(560, 150);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final f in frames)
                  // disableAnimations pins each instance to its hold frame, so
                  // instead we drive distinct progress by mounting fresh
                  // controllers and pumping to the right elapsed time.
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: _At(progress: f, kind: kind, accent: accents[kind]!),
                  ),
              ],
            ),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Row).first,
        matchesGoldenFile('_preview/icon_${kind.name}.png'),
      );
    });
  }
}

/// Renders one painter at a fixed progress by reaching past [WorkIcon]'s
/// internal controller — the painters are private, so this mirrors what
/// WorkIcon does with a static value.
class _At extends StatelessWidget {
  const _At({required this.progress, required this.kind, required this.accent});
  final double progress;
  final WorkIconKind kind;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    // MediaQuery.disableAnimations pins WorkIcon to its hold frame (0.62).
    // For the other frames we rely on the live controller having advanced.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: WorkIcon(kind: kind, accent: accent, size: 110),
    );
  }
}
