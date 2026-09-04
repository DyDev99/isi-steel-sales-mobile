import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/shared/animations/calendar_month_icon.dart';

/// Throwaway: renders a filmstrip of the cycle so the drawing can be eyeballed.
void main() {
  testWidgets('filmstrip', (tester) async {
    tester.view.physicalSize = const Size(960, 200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const frames = [0.05, 0.15, 0.25, 0.35, 0.45, 0.55, 0.65, 0.75, 0.85, 0.95];

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: const Color(0xFFF8FAFC),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final t in frames)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2563EB).withValues(alpha: 0.10),
                        border: Border.all(
                            color: const Color(0xFFD4AF37), width: 2),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: CustomPaint(
                            painter: CalendarMonthPainter(
                              t: t,
                              accent: const Color(0xFF2563EB),
                              ink: const Color(0xFF334155),
                              muted: const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('$t', style: const TextStyle(fontSize: 11)),
                  ],
                ),
            ],
          ),
        ),
      ),
    ));

    await expectLater(
        find.byType(Row), matchesGoldenFile('frames/zz_calendar_strip.png'));
  });
}
