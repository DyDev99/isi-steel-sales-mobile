import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/colors.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final disabled = loading || onPressed == null;
    return Opacity(
      opacity: disabled ? 0.7 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.ctaGradient,
          borderRadius: BorderRadius.circular(AppColors.radius),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context)
                  .colorScheme
                  .secondary
                  .withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppColors.radius),
            onTap: disabled ? null : onPressed,
            child: SizedBox(
              height: 56,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
