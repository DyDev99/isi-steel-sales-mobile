import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/auth_vibe.dart';

class GlassCard extends StatelessWidget {
  const GlassCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(22)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Vibe.radius + 6);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Vibe.surface,
        borderRadius: radius,
        border: Border.all(color: Vibe.stroke),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F2937).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
