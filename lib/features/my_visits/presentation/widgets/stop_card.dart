import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_text_context.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/models/today_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/navigation/open_quotation.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

/// Cleaned Material 3 stop card with streamlined metadata, dynamic status enum styling,
/// direct quotation action button, and a bottom-right animated "Skip Stop" dialog popup.
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
        customerName: context.localized(customer.displayName),
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
      padding: EdgeInsets.only(bottom: context.rh(12)),
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
              borderRadius: BorderRadius.circular(context.rr(16)),
              border: Border.all(
                color: isCheckInActive
                    ? statusConfig.color.withValues(alpha: 0.5)
                    : colors.border,
                width: isCheckInActive ? context.rw(1.5) : context.rw(1),
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
              borderRadius: BorderRadius.circular(context.rr(16)),
              child: Stack(
                children: [
                  // Accent Bar on the left side indicating status
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: context.rw(4),
                      color: statusConfig.color,
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.fromLTRB(context.rw(16), context.rh(12), context.rw(14), context.rh(12)),
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
                                    context.localized(customer.displayName),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: context.rsp(15),
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  SizedBox(height: context.rh(2)),
                                  Text(
                                    customer.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: context.rsp(11.5),
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(width: context.rw(8)),

                            // Animated Status Pill
                            _StatusPill(
                              label: statusConfig.label,
                              color: statusConfig.color,
                              icon: statusConfig.icon,
                              isPulsing: isCheckInActive,
                            ),

                            // Quick Quotation Basket Icon for Completed Stops
                            if (isCompleted) ...[
                              SizedBox(width: context.rw(8)),
                              _QuotationButton(
                                onTap: () => _handleQuotationTap(context),
                              ),
                            ],
                          ],
                        ),

                        SizedBox(height: context.rh(10)),

                        // Bottom Streamlined Metadata Row
                        Padding(
                          padding: EdgeInsets.only(right: _canSkip ? context.rw(32) : 0),
                          child: Row(
                            children: [
                              // Time Schedule Chip
                              _MetaChip(
                                icon: Icons.schedule_rounded,
                                label:
                                    '${timeFmt.format(widget.todayStop.stop.plannedArrival)}–${timeFmt.format(widget.todayStop.stop.plannedDeparture)}',
                              ),

                              SizedBox(width: context.rw(6)),

                              // High Priority Tag (if applicable)
                              if (_highPriority) ...[
                                _MetaChip(
                                  icon: Icons.error_outline_rounded,
                                  label:
                                      'my_visits.route_info.priority_high'.tr,
                                  color: colors.warning,
                                  isBold: true,
                                ),
                                SizedBox(width: context.rw(6)),
                              ],

                              const Spacer(),

                              // Distance & ETA badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.rw(8),
                                  vertical: context.rh(4),
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(context.rr(8)),
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
                                      size: context.rw(11),
                                      color: scheme.primary,
                                    ),
                                    SizedBox(width: context.rw(4)),
                                    Text(
                                      _distanceLabel(),
                                      style: TextStyle(
                                        color: scheme.primary,
                                        fontSize: context.rsp(11),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
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
                      bottom: context.rh(8),
                      right: context.rw(8),
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
          padding: EdgeInsets.all(context.rr(6)),
          decoration: BoxDecoration(
            color: scheme.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: scheme.error.withValues(alpha: 0.3),
              width: context.rw(1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4.r,
                offset: Offset(0, context.rh(2)),
              ),
            ],
          ),
          child: Icon(
            Icons.skip_next_rounded,
            size: context.rsp(15),
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
        borderRadius: BorderRadius.circular(context.rr(24)),
      ),
      elevation: 12,
      backgroundColor: scheme.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(context.rw(18), context.rh(20), context.rw(18), context.rh(16)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Icon & Title
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(context.rr(8)),
                    decoration: BoxDecoration(
                      color: scheme.error.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.do_not_disturb_on_outlined,
                      size: context.rsp(20),
                      color: scheme.error,
                    ),
                  ),
                  SizedBox(width: context.rw(10)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Skip Stop Reason',
                          style: TextStyle(
                            fontSize: context.rsp(16),
                            fontWeight: FontWeight.w900,
                            color: colors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: context.rh(2)),
                        Text(
                          'Please select or enter why you want to skip this stop.',
                          style: TextStyle(
                            fontSize: context.rsp(11.5),
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: context.rh(16)),

              // Reason Chips
              Wrap(
                spacing: context.rw(8),
                runSpacing: context.rh(8),
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
                      fontSize: context.rsp(12),
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? scheme.primary : colors.textPrimary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.rr(10)),
                    ),
                  );
                }).toList(),
              ),

              // Custom Note TextField for 'Other'
              if (_selectedReason == 'Other') ...[
                SizedBox(height: context.rh(12)),
                TextField(
                  controller: _customNoteController,
                  maxLines: 2,
                  onChanged: (_) => setState(() {}),
                  style:
                      TextStyle(fontSize: context.rsp(12.5), color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Provide details for skipping...',
                    hintStyle: TextStyle(
                      fontSize: context.rsp(12),
                      color: colors.textSecondary.withValues(alpha: 0.6),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: context.rw(12), vertical: context.rh(10)),
                    filled: true,
                    fillColor: colors.border.withValues(alpha: 0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.rr(12)),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(context.rr(12)),
                      borderSide: BorderSide(color: scheme.primary, width: 1.5),
                    ),
                  ),
                ),
              ],

              SizedBox(height: context.rh(20)),

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
                        fontSize: context.rsp(12.5),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: context.rw(8)),
                  FilledButton(
                    onPressed: isSubmitEnabled ? _submit : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      disabledBackgroundColor:
                          scheme.error.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(context.rr(10)),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: context.rw(18),
                        vertical: context.rh(10),
                      ),
                    ),
                    child: Text(
                      'Confirm Skip',
                      style: TextStyle(
                        fontSize: context.rsp(12.5),
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
          padding: EdgeInsets.all(context.rw(7)),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.3),
              width: context.rw(1),
            ),
          ),
          child: Icon(
            Icons.shopping_basket_rounded,
            size: context.rw(15),
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
          padding: EdgeInsets.symmetric(horizontal: context.rw(10), vertical: context.rh(5)),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(context.rr(20)),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.25),
              width: context.rw(0.8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: context.rw(11),
                color: widget.color,
              ),
              SizedBox(width: context.rw(4)),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.color,
                  fontSize: context.rsp(10.5),
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
      padding: EdgeInsets.symmetric(horizontal: context.rw(8), vertical: context.rh(4)),
      decoration: BoxDecoration(
        color: (color ?? colors.border)
            .withValues(alpha: color != null ? 0.1 : 0.4),
        borderRadius: BorderRadius.circular(context.rr(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.rw(12), color: fg),
          SizedBox(width: context.rw(4)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontSize: context.rsp(11),
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
