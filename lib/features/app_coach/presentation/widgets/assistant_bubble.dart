import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/app_coach/domain/entities/coach_step.dart';

/// The assistant tooltip: a compact card with an avatar, a short title + message
/// (≤ 2 lines), a slim progress bar, and one primary CTA (plus an optional
/// "Skip tour"). Const-friendly and theme-aware for light/dark.
class AssistantBubble extends StatelessWidget {
  const AssistantBubble({
    super.key,
    required this.step,
    required this.stepNumber,
    required this.totalSteps,
    required this.progress,
    required this.onCta,
    required this.onSkip,
    required this.onClose,
  });

  final CoachStep step;
  final int stepNumber;
  final int totalSteps;
  final double progress;
  final VoidCallback onCta;
  final VoidCallback onSkip;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      liveRegion: true,
      label: '${step.titleKey.tr}. ${step.messageKey.tr}',
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.shadowColor.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(color: scheme.primary),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          step.titleKey.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          step.messageKey.tr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            height: 1.3,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Dismiss → pause (surfaces the floating assistant to resume).
                  _IconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'coach.cta.dismiss'.tr,
                    color: colors.iconMuted,
                    onTap: onClose,
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _ProgressBar(
                value: progress,
                stepNumber: stepNumber,
                total: totalSteps,
                trackColor: colors.surfaceStrong,
                fillColor: scheme.primary,
                labelColor: colors.textHint,
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  if (step.canSkip)
                    _TextButton(
                      label: 'coach.cta.skip_tour'.tr,
                      color: colors.textHint,
                      onTap: onSkip,
                    ),
                  const Spacer(),
                  _PrimaryButton(
                    label: step.ctaKey.tr,
                    background: scheme.primary,
                    foreground: scheme.onPrimary,
                    onTap: onCta,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 36.r,
        height: 36.r,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(Icons.auto_awesome_rounded, size: 20.r, color: color),
      );
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.value,
    required this.stepNumber,
    required this.total,
    required this.trackColor,
    required this.fillColor,
    required this.labelColor,
  });

  final double value;
  final int stepNumber;
  final int total;
  final Color trackColor;
  final Color fillColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 5.h,
                backgroundColor: trackColor,
                valueColor: AlwaysStoppedAnimation(fillColor),
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Text(
          '$stepNumber/$total',
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: labelColor,
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: foreground,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _TextButton extends StatelessWidget {
  const _TextButton(
      {required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(8.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      );
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        constraints: BoxConstraints.tight(Size(32.r, 32.r)),
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18.r, color: color),
      );
}
