import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

/// A 3D-embossed call-to-action card infused with traditional golden motifs,
/// featuring corner frame flourishes, central Lottie animation, and a tactile button.
/// Fully responsive to Light and Dark themes.
class GuestCtaCard extends StatelessWidget {
  const GuestCtaCard({super.key, required this.onAuthenticate});

  final VoidCallback onAuthenticate;

  // Traditional Gold Palette Constants
  static const Color goldDark = Color(0xFFB8860B);
  static const Color goldMedium = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF3E5AB);
  static const Color warmParchment = Color(0xFFFFFDF8);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final appColors = context.appColors;
    final isDark = theme.brightness == Brightness.dark;

    // Theme-aware surface & accent palette
    final cardBgColors = isDark
        ? [appColors.card, appColors.surfaceSoft]
        : [warmParchment, const Color(0xFFFAF5E8)];

    final cornerColor = isDark ? goldLight.withValues(alpha: 0.6) : goldMedium;
    final innerBorderColor =
        (isDark ? goldLight : goldMedium).withValues(alpha: isDark ? 0.2 : 0.3);

    return Container(
      width: double.infinity,
      // Layered 3D drop shadow for realistic elevation
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          // Ambient soft glow
          BoxShadow(
            color: (isDark ? goldMedium : goldDark)
                .withValues(alpha: isDark ? 0.08 : 0.12),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          // Deep sharp 3D base shadow
          BoxShadow(
            color:
                appColors.shadowColor.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        // Outer Traditional Gold Metallic Frame
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    goldLight.withValues(alpha: 0.8),
                    goldMedium,
                    goldDark.withValues(alpha: 0.7),
                  ]
                : const [goldLight, goldMedium, goldDark],
          ),
        ),
        padding: const EdgeInsets.all(2.5), // Frame border thickness
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: cardBgColors,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Stack(
              children: [
                // --- Traditional Corner Flourishes (Top-Left) ---
                Positioned(
                  top: 0,
                  left: 0,
                  child: CustomPaint(
                    size: const Size(70, 70),
                    painter: TraditionalCornerPainter(color: cornerColor),
                  ),
                ),

                // --- Traditional Corner Flourishes (Bottom-Right) ---
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Transform.rotate(
                    angle: math.pi,
                    child: CustomPaint(
                      size: const Size(70, 70),
                      painter: TraditionalCornerPainter(color: cornerColor),
                    ),
                  ),
                ),

                // --- Inner Traditional Border Accent ---
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: innerBorderColor,
                        width: 1,
                      ),
                    ),
                  ),
                ),

                // --- Main Card Content ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Centered Lottie Animation with subtle 3D shadow frame
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? goldLight : goldDark)
                                  .withValues(alpha: isDark ? 0.05 : 0.1),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Lottie.asset(
                          'assets/lotties/Welcome.json',
                          height: 160,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // --- 3D Raised Action Button ---
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          // 3D Shadow underneath the button
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withValues(
                                alpha: isDark ? 0.5 : 0.35,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                            BoxShadow(
                              color: goldDark.withValues(
                                alpha: isDark ? 0.3 : 0.2,
                              ),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          // 3D Beveled Gradient for primary button
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              scheme.primary,
                              Color.lerp(scheme.primary, Colors.black, 0.15) ??
                                  scheme.primary,
                            ],
                          ),
                          border: Border.all(
                            color: goldLight.withValues(
                              alpha: isDark ? 0.4 : 0.6,
                            ),
                            width: 1.2,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onAuthenticate,
                            borderRadius: BorderRadius.circular(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.login_rounded,
                                  size: 20,
                                  color: scheme.onPrimary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'auth.login_btn'.tr,
                                  style: TextStyle(
                                    color: scheme.onPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black38,
                                        offset: Offset(0, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter rendering traditional ornamental corner flourishes
class TraditionalCornerPainter extends CustomPainter {
  final Color color;

  TraditionalCornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Traditional outer arc
    final outerPath = Path()
      ..moveTo(0, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.2,
        size.height * 0.2,
        size.width * 0.8,
        0,
      );
    canvas.drawPath(outerPath, paint);

    // Inner ornamental accent circle
    canvas.drawCircle(
        Offset(size.width * 0.25, size.height * 0.25), 6, fillPaint);
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.25), 6, paint);

    // Subtle inner arc accent
    final innerPath = Path()
      ..moveTo(0, size.height * 0.45)
      ..quadraticBezierTo(
        size.width * 0.1,
        size.height * 0.1,
        size.width * 0.45,
        0,
      );
    canvas.drawPath(innerPath, paint);
  }

  @override
  bool shouldRepaint(covariant TraditionalCornerPainter oldDelegate) =>
      oldDelegate.color != color;
}
