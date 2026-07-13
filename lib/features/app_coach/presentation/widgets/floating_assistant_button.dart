import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';

/// The small floating assistant shown while the coach is paused. Tapping it
/// resumes the walkthrough; it stays clear of the bottom inset and is fully
/// labelled for screen readers.
class FloatingAssistantButton extends StatelessWidget {
  const FloatingAssistantButton({super.key, required this.onResume});

  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // Self-positioning within a full-size parent so the host can drop it in
    // without a Stack wrapper.
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: EdgeInsets.only(right: 16.w, bottom: 16.h + bottomInset),
        child: Semantics(
          button: true,
          label: 'coach.resume_hint'.tr,
          child: Material(
            color: scheme.primary,
            shape: const CircleBorder(),
            elevation: 6,
            shadowColor: scheme.primary.withValues(alpha: 0.5),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onResume,
              child: Padding(
                padding: EdgeInsets.all(14.r),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: scheme.onPrimary,
                  size: 24.r,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
