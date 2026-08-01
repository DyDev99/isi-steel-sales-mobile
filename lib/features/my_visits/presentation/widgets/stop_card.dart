import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/models/today_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/navigation/open_quotation.dart';

/// Modern animated Material 3 stop card with tactile feedback, split-unit
/// distance formatting, dynamic status enum styling, direct quotation action button,
/// and a bottom-right animated "Skip Stop" reason dialog popup.
class StopCard extends StatefulWidget {
  const StopCard({
    super.key,
    required this.todayStop,
    required this.onTap,
    this.onQuotationTap,
    this.onSkipSubmitted,
  });

  final TodayStop todayStop;
  final VoidCallback onTap;
  final VoidCallback? onQuotationTap;
  final void Function(String reason)? onSkipSubmitted;

  @override
  State<StopCard> createState() => _StopCardState();
}

class _StopCardState extends State<StopCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  VisitStatus get _status => widget.todayStop.stop.status;

  /// Complete enum mapping for dynamic UI representation
  ({Color color, IconData icon, String label}) _statusStyle(
      BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    switch (_status) {
      case VisitStatus.checkedOut:
        return (
          color: colors.success,
          icon: Icons.check_circle_rounded,
          label: 'my_visits.status.completed'.tr,
        );
      case VisitStatus.checkedIn:
        return (
          color: colors.warning,
          icon: Icons.directions_run_rounded,
          label: 'my_visits.status.in_progress'.tr,
        );
      case VisitStatus.missed:
        return (
          color: scheme.error,
          icon: Icons.cancel_rounded,
          label: 'my_visits.status.missed'.tr,
        );
      case VisitStatus.pending:
      default:
        return (
          color: colors.textSecondary,
          icon: Icons.access_time_filled_rounded,
          label: 'my_visits.status.pending'.tr,
        );
    }
  }

  /// Formats distance into split units e.g. "4km - 30m"
  String _distanceLabel() {
    final meters = widget.todayStop.distanceMeters;
    if (meters == null) return 'my_visits.route_info.distance_unknown'.tr;

    final totalMeters = meters.round();
    if (totalMeters < 1000) {
      return '${totalMeters}m';
    }

    final km = totalMeters ~/ 1000;
    final remainingMeters = totalMeters % 1000;

    if (remainingMeters == 0) {
      return '${km}km';
    }

    return '${km}km - ${remainingMeters}m';
  }

  bool get _highPriority =>
      _status != VisitStatus.checkedOut &&
      _status != VisitStatus.missed &&
      widget.todayStop.stop.plannedArrival.isBefore(DateTime.now());

  bool get _canSkip =>
      _status != VisitStatus.checkedOut && _status != VisitStatus.missed;

  void _handleQuotationTap(BuildContext context) {
    if (widget.onQuotationTap != null) {
      widget.onQuotationTap!();
    } else {
      final customer = widget.todayStop.stop.customer;
      openQuotationForCustomer(
        context,
        customerId: customer.id,
        customerName: customer.name,
      );
    }
  }

  Future<void> _handleSkipTap(BuildContext context) async {
    final reason = await _showSkipReasonDialog(context);
    if (reason != null && reason.trim().isNotEmpty) {
      widget.onSkipSubmitted?.call(reason.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final statusConfig = _statusStyle(context);
    final customer = widget.todayStop.stop.customer;
    final eta = widget.todayStop.etaMinutes;
    final timeFmt = DateFormat('h:mm a');

    final isCheckInActive = _status == VisitStatus.checkedIn;
    final isCompleted = _status == VisitStatus.checkedOut;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.decelerate,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isCheckInActive
                    ? statusConfig.color.withValues(alpha: 0.5)
                    : colors.border,
                width: isCheckInActive ? 1.5.w : 1.w,
              ),
              boxShadow: _isPressed
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : colors.cardShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: Stack(
                children: [
                  // Accent Bar on the left side indicating status / active stop
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 4.w,
                      color: statusConfig.color,
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 14.w, 14.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Section: Customer info, Status Pill & Direct Quotation Action
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Customer Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  SizedBox(height: 3.h),
                                  Text(
                                    customer.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 11.5.sp,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(width: 8.w),

                            // Animated Status Pill
                            _StatusPill(
                              label: statusConfig.label,
                              color: statusConfig.color,
                              icon: statusConfig.icon,
                              isPulsing: isCheckInActive,
                            ),

                            // Quick Quotation Basket Icon for Completed Stops
                            if (isCompleted) ...[
                              SizedBox(width: 8.w),
                              _QuotationButton(
                                onTap: () => _handleQuotationTap(context),
                              ),
                            ],
                          ],
                        ),

                        SizedBox(height: 12.h),

                        // Bottom Section: Metadata Chips (Extra right padding when skip button is visible)
                        Padding(
                          padding: EdgeInsets.only(right: _canSkip ? 36.w : 0),
                          child: Wrap(
                            spacing: 8.w,
                            runSpacing: 6.h,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _MetaChip(
                                icon: Icons.alt_route_rounded,
                                label: widget.todayStop.routeName,
                              ),
                              _MetaChip(
                                icon: Icons.schedule_rounded,
                                label:
                                    '${timeFmt.format(widget.todayStop.stop.plannedArrival)}–${timeFmt.format(widget.todayStop.stop.plannedDeparture)}',
                              ),
                              if (customer.code.isNotEmpty)
                                _MetaChip(
                                  icon: Icons.tag_rounded,
                                  label: customer.code,
                                ),
                              if (_highPriority)
                                _MetaChip(
                                  icon: Icons.error_outline_rounded,
                                  label:
                                      'my_visits.route_info.priority_high'.tr,
                                  color: colors.warning,
                                  isBold: true,
                                ),

                              // Distance & ETA badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color:
                                        scheme.primary.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.near_me_rounded,
                                      size: 11.w,
                                      color: scheme.primary,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      _distanceLabel(),
                                      style: TextStyle(
                                        color: scheme.primary,
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (eta != null) ...[
                                      SizedBox(width: 4.w),
                                      Text(
                                        '• ~$eta min',
                                        style: TextStyle(
                                          color: scheme.primary
                                              .withValues(alpha: 0.8),
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom-Right Skip Action Button
                  if (_canSkip)
                    Positioned(
                      bottom: 10.h,
                      right: 10.w,
                      child: _SkipButton(
                        onTap: () => _handleSkipTap(context),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tactile Floating Skip Button on bottom right of the card
class _SkipButton extends StatefulWidget {
  const _SkipButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<_SkipButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: EdgeInsets.all(7.r),
          decoration: BoxDecoration(
            color: scheme.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: scheme.error.withValues(alpha: 0.3),
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Icon(
            Icons.skip_next_rounded,
            size: 16.sp,
            color: scheme.error,
          ),
        ),
      ),
    );
  }
}

/// Opens the animated skip reason dialog with a smooth scale-fade transition
Future<String?> _showSkipReasonDialog(BuildContext context) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
    transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );

      return ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(curved),
        child: FadeTransition(
          opacity: animation,
          child: const _SkipReasonDialogContent(),
        ),
      );
    },
  );
}

/// Custom Animated Skip Reason Dialog Widget
class _SkipReasonDialogContent extends StatefulWidget {
  const _SkipReasonDialogContent();

  @override
  State<_SkipReasonDialogContent> createState() =>
      _SkipReasonDialogContentState();
}

class _SkipReasonDialogContentState extends State<_SkipReasonDialogContent> {
  final TextEditingController _customNoteController = TextEditingController();
  String? _selectedReason;

  final List<String> _predefinedReasons = [
    'Store Closed',
    'Customer Postponed',
    'Traffic / Unreachable',
    'Other',
  ];

  @override
  void dispose() {
    _customNoteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedReason == null) return;
    String finalReason = _selectedReason!;
    if (_selectedReason == 'Other' &&
        _customNoteController.text.trim().isNotEmpty) {
      finalReason = 'Other: ${_customNoteController.text.trim()}';
    }
    Navigator.of(context).pop(finalReason);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    final isSubmitEnabled = _selectedReason != null &&
        (_selectedReason != 'Other' ||
            _customNoteController.text.trim().isNotEmpty);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
      ),
      elevation: 12,
      backgroundColor: scheme.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 16.h),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Icon & Title
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: scheme.error.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.do_not_disturb_on_outlined,
                      size: 20.sp,
                      color: scheme.error,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Skip Stop Reason',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w900,
                            color: colors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Please select or enter why you want to skip this stop.',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // Reason Chips
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: _predefinedReasons.map((reason) {
                  final isSelected = _selectedReason == reason;
                  return ChoiceChip(
                    label: Text(reason),
                    selected: isSelected,
                    onSelected: (selected) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedReason = selected ? reason : null;
                      });
                    },
                    selectedColor: scheme.primary.withValues(alpha: 0.15),
                    backgroundColor: colors.border.withValues(alpha: 0.3),
                    side: BorderSide(
                      color: isSelected
                          ? scheme.primary
                          : colors.border.withValues(alpha: 0.5),
                    ),
                    labelStyle: TextStyle(
                      fontSize: 12.sp,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? scheme.primary : colors.textPrimary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  );
                }).toList(),
              ),

              // Custom Note TextField for 'Other'
              if (_selectedReason == 'Other') ...[
                SizedBox(height: 12.h),
                TextField(
                  controller: _customNoteController,
                  maxLines: 2,
                  onChanged: (_) => setState(() {}),
                  style:
                      TextStyle(fontSize: 12.5.sp, color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Provide details for skipping...',
                    hintStyle: TextStyle(
                      fontSize: 12.sp,
                      color: colors.textSecondary.withValues(alpha: 0.6),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    filled: true,
                    fillColor: colors.border.withValues(alpha: 0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: scheme.primary, width: 1.5),
                    ),
                  ),
                ),
              ],

              SizedBox(height: 20.h),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  FilledButton(
                    onPressed: isSubmitEnabled ? _submit : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      disabledBackgroundColor:
                          scheme.error.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 10.h,
                      ),
                    ),
                    child: Text(
                      'Confirm Skip',
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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

/// Interactive Basket Button for creating quotation on completed stops
class _QuotationButton extends StatefulWidget {
  const _QuotationButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_QuotationButton> createState() => _QuotationButtonState();
}

class _QuotationButtonState extends State<_QuotationButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: EdgeInsets.all(7.w),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.3),
              width: 1.w,
            ),
          ),
          child: Icon(
            Icons.shopping_basket_rounded,
            size: 15.w,
            color: scheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Dynamic status pill with support for pulse animation during active states
class _StatusPill extends StatefulWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.icon,
    this.isPulsing = false,
  });

  final String label;
  final Color color;
  final IconData icon;
  final bool isPulsing;

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isPulsing) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _StatusPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing != oldWidget.isPulsing) {
      if (widget.isPulsing) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final opacity =
            widget.isPulsing ? 0.12 + (_pulseController.value * 0.12) : 0.12;

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.25),
              width: 0.8.w,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 11.w,
                color: widget.color,
              ),
              SizedBox(width: 4.w),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Metadata item chip with soft pill background
class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.color,
    this.isBold = false,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fg = color ?? colors.textSecondary;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: (color ?? colors.border)
            .withValues(alpha: color != null ? 0.1 : 0.4),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.w, color: fg),
          SizedBox(width: 4.w),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontSize: 11.sp,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
