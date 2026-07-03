import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/auth_vibe.dart';

/// Flat, bright background for the login screen — matches the app-wide
/// Blue & White enterprise theme.
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Vibe.bg);
  }
}
