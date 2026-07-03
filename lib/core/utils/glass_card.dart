import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

/// The app's standard card: white background, soft shadow, thin border,
/// rounded corners — the enterprise-CRM flat-card look (no blur/glass).
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
    return Container(
      decoration: BoxDecoration(
        color: Vibe.surface,
        borderRadius: radius,
        border: Border.all(color: Vibe.stroke),
        boxShadow: Vibe.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: Vibe.primaryLight.withValues(alpha: 0.35),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
