import 'package:flutter/material.dart';

/// Minimal, self-contained root. It imports NOTHING from your features, so
/// it always compiles. Point [home] at a real screen only after you've
/// confirmed that screen (and everything it imports) exists in the project.
class ISISteelSalesApp extends StatelessWidget {
  const ISISteelSalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISI Steel Sales',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C4DFF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0D0B1F),
      ),

      // ── Switch the home to your real entry, ONE at a time ────────────
      // Uncomment the import at the top of this file first, then set home.
      //
      // import 'package:isi_steel_sales_mobile/features/shell/presentation/main_shell.dart';
      //   home: const MainShell(),
      //
      // import 'package:isi_steel_sales_mobile/features/authentication/presentation/screens/login_screen.dart';
      //   home: const LoginScreen(),
      home: const _BootOk(),
    );
  }
}

/// Temporary landing so you can confirm the app builds and boots.
class _BootOk extends StatelessWidget {
  const _BootOk();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('✅', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('It compiles & runs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            SizedBox(height: 6),
            Text('Now wire home: to your real screen.',
                style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}