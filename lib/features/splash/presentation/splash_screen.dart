import 'dart:async';
import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/storage/hive/app_preferences.dart';
import 'package:isi_steel_sales_mobile/core/utils/version.dart';
import 'package:isi_steel_sales_mobile/routes/app_routes.dart';

/// Splash: ISI Steel logo fades + scales in, then forwards based on onboarding
/// status — the single decision point for the boot flow:
///
///   • onboarding **not** complete -> language selection (the onboarding step)
///   • onboarding complete         -> main shell (auth is resolved in the
///                                     background; guests and signed-in users
///                                     both land on the shell)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    // Start animation immediately on first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());

    // After a short brand hold, forward based on onboarding status. First-time
    // users go through language selection (onboarding); everyone else drops
    // straight into the app shell as a guest or signed-in user.
    _navTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      final onboarded = sl<AppPreferences>().isOnboardingComplete;
      Navigator.of(context).pushReplacementNamed(
        onboarded ? Static.main : Static.chooseLanguage,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Changed background to white
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 2. Remove or hide this, as it is likely a dark-mode glow background
          // const Positioned.fill(child: AuroraBackground()),

          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/logos/isi_steel_logo.png',
                      width: 360,
                      height: 360,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                          // ... your existing code
                          ),
                    ),
                    const SizedBox(height: 20),

                    // 3. IMPORTANT: Update the text color here
                    // If Vibe.cta is a light-colored gradient, it won't show on white.
                    // Change the color/gradient to something dark (e.g., Colors.black)
                    const Text(
                      'ISI STEEL',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: Colors.black, // Explicitly set to black
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sales Mobile',
                      style: TextStyle(
                        color: Colors.grey, // Changed from Vibe.muted
                        fontSize: 13,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  // Change this to a dark color if necessary
                  color: Colors.blueAccent,
                ),
              ),
            ),
          ),

          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(child: VersionFooter()),
          ),
        ],
      ),
    );
  }
}
