import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/auth_vibe.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding =
      const EdgeInsets.all(22)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Vibe.radius + 6),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Vibe.surface,
            borderRadius: BorderRadius.circular(Vibe.radius + 6),
            border: Border.all(color: Vibe.stroke),
          ),
          child: child,
        ),
      ),
    );
  }
}
