import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Vibe.radius);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          color: Vibe.surface,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: Vibe.stroke),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
