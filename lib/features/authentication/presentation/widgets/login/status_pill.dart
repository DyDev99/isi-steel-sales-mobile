import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

enum AuthVibeStatus { idle, verifying, error, success }

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, this.message});

  final AuthVibeStatus status;
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (status == AuthVibeStatus.idle) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final (Color color, IconData? icon, String text) = switch (status) {
      AuthVibeStatus.verifying => (scheme.primary, null, 'Verifying…'),
      AuthVibeStatus.success => (
          colors.success,
          Icons.check_circle,
          "You're in ✨"
        ),
      AuthVibeStatus.error => (
          scheme.error,
          Icons.error_outline,
          message ?? 'Something went wrong'
        ),
      AuthVibeStatus.idle => (colors.textSecondary, null, ''),
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          if (status == AuthVibeStatus.verifying)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            )
          else if (icon != null)
            Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
