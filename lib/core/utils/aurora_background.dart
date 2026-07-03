import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

/// Flat, bright background for the enterprise CRM theme. Kept as its own
/// widget (rather than inlining `Vibe.bg` everywhere) so screens that used
/// to layer content over the old dark "aurora" glow keep working unchanged.
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Vibe.bgSoft);
  }
}
