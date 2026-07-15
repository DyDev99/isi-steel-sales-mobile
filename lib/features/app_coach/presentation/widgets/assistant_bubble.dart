import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          padding: EdgeInsets.fromLTRB(18.w, 16.h, 16.w, 16.h),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.10)),
            boxShadow: [
              // Tight contact shadow for definition against the scrim...
              BoxShadow(
                color: colors.shadowColor.withValues(alpha: 0.14),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
              // ...plus a soft ambient shadow for lift.
              BoxShadow(
                color: colors.shadowColor.withValues(alpha: 0.20),
                blurRadius: 32,
                offset: const Offset(0, 16),
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
                  SizedBox(width: 12.w),
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
                            fontSize: 15.5.sp,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                            letterSpacing: -0.3,
                            height: 1.15,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          step.messageKey.tr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            height: 1.35,
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
              SizedBox(height: 14.h),
              _ProgressBar(
                value: progress,
                stepNumber: stepNumber,
                total: totalSteps,
                trackColor: colors.surfaceStrong,
                fillColor: scheme.primary,
              ),
              SizedBox(height: 14.h),
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
        width: 38.r,
        height: 38.r,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.24),
              color.withValues(alpha: 0.10),
            ],
          ),
          borderRadius: BorderRadius.circular(13.r),
          border: Border.all(color: color.withValues(alpha: 0.18)),
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
  });

  final double value;
  final int stepNumber;
  final int total;
  final Color trackColor;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Container(
              height: 6.h,
              color: trackColor,
              alignment: Alignment.centerLeft,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: v,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      gradient: LinearGradient(
                        colors: [
                          fillColor.withValues(alpha: 0.70),
                          fillColor,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        _StepPill(stepNumber: stepNumber, total: total, color: fillColor),
      ],
    );
  }
}

/// Tinted pill badge for "n/total" — reads as a status chip rather than a
/// plain caption, and keeps the same accent as the progress fill.
class _StepPill extends StatelessWidget {
  const _StepPill({
    required this.stepNumber,
    required this.total,
    required this.color,
  });

  final int stepNumber;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          '$stepNumber/$total',
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      );
}

class _PrimaryButton extends StatefulWidget {
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
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14.r),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.background,
                Color.lerp(widget.background, Colors.black, 0.14) ??
                    widget.background,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.background.withValues(alpha: 0.32),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14.r),
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onTap();
            },
            onHighlightChanged: (v) => setState(() => _pressed = v),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 11.h),
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: widget.foreground,
                  letterSpacing: -0.1,
                ),
              ),
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
        borderRadius: BorderRadius.circular(10.r),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w700,
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
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          onPressed: onTap,
          tooltip: tooltip,
          visualDensity: VisualDensity.compact,
          constraints: BoxConstraints.tight(Size(32.r, 32.r)),
          padding: EdgeInsets.zero,
          icon: Icon(icon, size: 16.r, color: color),
        ),
      );
}