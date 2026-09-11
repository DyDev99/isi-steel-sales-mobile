import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_text_context.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/location_tracking_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/location_tracking_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/models/check_in_gps_phase.dart';

/// What the rep chose in [CheckInConfirmationDialog].
enum CheckInConfirmation {
  /// Inside the area (or the outlet has no pin) — proceed with the check-in.
  confirmed,

  /// Outside the area, or inside it on a fix too coarse to judge. The caller
  /// must collect a written reason before dispatching.
  withReason,

  /// No position could be found at all after a full search. The caller must
  /// collect a written reason; the check-in is recorded as **unverified**.
  withoutGps,
}

/// Live location verification, shown before a check-in is dispatched.
///
/// ## What changed, and why it fixes "cannot check in"
///
/// This dialog used to receive a verdict computed **once**, at the moment the
/// rep tapped the button. If there was no fix at that instant it rendered
/// "Locating You — Waiting for a GPS fix" with a single **Cancel** button, and
/// nothing on it could ever change: no fix arriving later reached it, no
/// retry existed, and the only way forward was to cancel and hope. On a
/// handset indoors that was a permanent dead end — while the bloc underneath
/// would actually have accepted the check-in as unverified.
///
/// Now it is **live**. It listens to [LocationTrackingCubit] and re-verifies on
/// every fix, so it moves from *searching* to *within* on its own the moment a
/// position lands. It asks for a fresh fix when it opens. And every state has
/// a way forward:
///
/// | phase               | primary action                               |
/// |---------------------|----------------------------------------------|
/// | searching           | (waits, with progress)                       |
/// | within / no pin     | Confirm Check-In                             |
/// | weak signal/outside | Continue with reason                         |
/// | Location off        | Turn on location                             |
/// | permission refused  | Allow / Open settings                        |
/// | no fix after 15 s   | Check in without GPS (reason required)       |
///
/// None of these fabricate a position. "Without GPS" is recorded unverified
/// with the rep's reason on the row, exactly the evidence api.md §8.2 expects.
///
/// Returns null when the rep cancelled.
class CheckInConfirmationDialog extends StatefulWidget {
  const CheckInConfirmationDialog({
    super.key,
    required this.outletName,
    required this.locationCubit,
    required this.read,
  });

  final String outletName;
  final LocationTrackingCubit locationCubit;

  /// Turns a tracker state into the verdict for this stop. Supplied by the
  /// screen so the dialog and the screen use the same outlet and radius.
  final CheckInReading Function(LocationTrackingState state) read;

  static Future<CheckInConfirmation?> show(
    BuildContext context, {
    required String outletName,
    required LocationTrackingCubit locationCubit,
    required CheckInReading Function(LocationTrackingState state) read,
  }) =>
      showGeneralDialog<CheckInConfirmation>(
        context: context,
        // The rep must answer it: this decides whether a durable record is
        // written, and a dialog dismissed by a stray tap on the scrim leaves
        // them unsure whether they checked in.
        barrierDismissible: false,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        transitionDuration: const Duration(milliseconds: 340),
        pageBuilder: (_, __, ___) => CheckInConfirmationDialog(
          outletName: outletName,
          locationCubit: locationCubit,
          read: read,
        ),
        // Scale-and-fade with a gentle overshoot on the way in, a quick plain
        // fade on the way out. No backdrop blur: animating a blur every frame
        // is what makes dialogs stutter on mid-range Android.
        transitionBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      );

  @override
  State<CheckInConfirmationDialog> createState() =>
      _CheckInConfirmationDialogState();
}

class _CheckInConfirmationDialogState extends State<CheckInConfirmationDialog> {
  Timer? _ticker;
  CheckInGpsPhase? _lastPhase;

  @override
  void initState() {
    super.initState();
    // Ask for a position *now*. A stationary handset's last stream sample may
    // be minutes old; the rep is agreeing to the distance on this dialog, so it
    // should be about where they stand at this moment.
    unawaited(widget.locationCubit.refreshFix());
    // One tick a second, for the elapsed counter and rotating tips. Cheap: it
    // rebuilds one small dialog, and stops with it.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _onPhase(CheckInGpsPhase phase) {
    final previous = _lastPhase;
    _lastPhase = phase;
    if (previous == null || previous == phase) return;
    // Felt, not just seen: a light tick when a fix lands, a firmer one for the
    // states that need the rep to do something.
    try {
      if (phase == CheckInGpsPhase.within) {
        HapticFeedback.lightImpact();
      } else if (phase.isBlockedBySetting ||
          phase == CheckInGpsPhase.unavailable) {
        HapticFeedback.mediumImpact();
      } else if (phase.isMeasured && !previous.isMeasured) {
        HapticFeedback.selectionClick();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationTrackingCubit, LocationTrackingState>(
      bloc: widget.locationCubit,
      builder: (context, trackerState) {
        final reading = widget.read(trackerState);
        _onPhase(reading.phase);
        return _DialogCard(
          outletName: widget.outletName,
          reading: reading,
          onCancel: () => Navigator.of(context).pop(),
          onConfirm: () =>
              Navigator.of(context).pop(CheckInConfirmation.confirmed),
          onWithReason: () =>
              Navigator.of(context).pop(CheckInConfirmation.withReason),
          onWithoutGps: () =>
              Navigator.of(context).pop(CheckInConfirmation.withoutGps),
          onRetry: () => unawaited(widget.locationCubit.retryFix()),
          onOpenSettings: () =>
              unawaited(widget.locationCubit.openSettingsForStatus()),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Copy
// ═════════════════════════════════════════════════════════════════════════════

/// TODO(i18n): move to en/km. Literals on purpose, same as
/// `RemoteCheckInSheet`: a missing `.tr` key renders the key itself on a rep's
/// screen, which is worse than untranslated English. Strings that already had
/// keys still use them.
abstract final class _Copy {
  static const searchingBody =
      'Getting your position. This usually takes a few seconds.';
  static const servicesOffTitle = 'Location is off';
  static const servicesOffBody =
      'Turn on Location to verify your check-in. We will pick it up '
      'automatically when you come back.';
  static const deniedTitle = 'Location permission needed';
  static const deniedBody =
      'Allow location access so your check-in can be verified.';
  static const deniedForeverBody =
      'Location access is blocked for this app. Enable it in Settings → '
      'Permissions → Location.';
  static const unavailableTitle = 'No GPS signal here';
  static const unavailableBody =
      'We could not get a position after a full search. You can try again, '
      'or check in without GPS — you will be asked for a short reason and '
      'the visit is marked unverified.';
  static const weakTitle = 'Weak GPS signal';
  static const weakBody =
      'You look close enough, but the signal is too coarse to be sure. It '
      'is still improving — wait a moment, or continue with a reason.';
  static const accuracy = 'Accuracy';
  static const strong = 'Strong';
  static const fair = 'Fair';
  static const weak = 'Weak';
  static const searchingFor = 'Searching';
  static const takingLonger = 'Taking longer than usual…';
  static const tryAgain = 'Try again';
  static const refresh = 'Refresh';
  static const withoutGps = 'Check in without GPS';
  static const turnOn = 'Turn on location';
  static const allow = 'Allow location';
  static const openSettings = 'Open settings';
  static const locating = 'Locating…';
  static const outlet = 'Outlet';
  static const tips = <String>[
    'Tip: step near a window or doorway.',
    'Tip: keep Wi-Fi switched on — it speeds up location, even offline.',
    'Tip: hold the phone still for a moment.',
  ];
}

// ═════════════════════════════════════════════════════════════════════════════
// Card
// ═════════════════════════════════════════════════════════════════════════════

class _DialogCard extends StatelessWidget {
  const _DialogCard({
    required this.outletName,
    required this.reading,
    required this.onCancel,
    required this.onConfirm,
    required this.onWithReason,
    required this.onWithoutGps,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final String outletName;
  final CheckInReading reading;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final VoidCallback onWithReason;
  final VoidCallback onWithoutGps;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  static const _switchDuration = Duration(milliseconds: 320);

  Color _accent(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return switch (reading.phase) {
      CheckInGpsPhase.within || CheckInGpsPhase.noOutlet => colors.success,
      CheckInGpsPhase.searching => scheme.primary,
      // Amber, not red. The rep has done nothing wrong — they are standing
      // somewhere the rule does not cover, and red reads as a fault.
      _ => colors.warning,
    };
  }

  (String title, String body) _texts() => switch (reading.phase) {
        CheckInGpsPhase.searching => (
            'my_visits.check_in_verification.no_fix_title'.tr,
            _Copy.searchingBody,
          ),
        CheckInGpsPhase.servicesDisabled => (
            _Copy.servicesOffTitle,
            _Copy.servicesOffBody,
          ),
        CheckInGpsPhase.permissionDenied => (
            _Copy.deniedTitle,
            _Copy.deniedBody,
          ),
        CheckInGpsPhase.permissionDeniedForever => (
            _Copy.deniedTitle,
            _Copy.deniedForeverBody,
          ),
        CheckInGpsPhase.unavailable => (
            _Copy.unavailableTitle,
            _Copy.unavailableBody,
          ),
        CheckInGpsPhase.noOutlet => (
            'my_visits.check_in_verification.no_outlet_title'.tr,
            'my_visits.check_in_verification.no_outlet_body'.tr,
          ),
        CheckInGpsPhase.within => (
            'my_visits.check_in_verification.within_title'.tr,
            'my_visits.check_in_verification.within_body'.tr,
          ),
        CheckInGpsPhase.weakSignal => (_Copy.weakTitle, _Copy.weakBody),
        CheckInGpsPhase.outside => (
            'my_visits.check_in_verification.outside_title'.tr,
            'my_visits.check_in_verification.outside_body'.tr,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = _accent(context);
    final (title, body) = _texts();

    // The Dialog itself is transparent; the card is the Container, so the
    // accent-tinted shadow sits *behind* it rather than over its face.
    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: context.rw(24)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(context.rr(24)),
          // Soft, accent-tinted shadow instead of Material elevation grey.
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.18),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              context.rw(20), context.rh(20), context.rw(20), context.rh(14)),
          child: AnimatedSize(
            duration: _switchDuration,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LocatorBeacon(phase: reading.phase, accent: accent),
                SizedBox(height: context.rh(8)),
                Text(
                  'my_visits.check_in_verification.title'.tr.toUpperCase(),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: context.rsp(10.5),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(height: context.rh(8)),
                _FadeSwap(
                  swapKey: title,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: context.rsp(18),
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                SizedBox(height: context.rh(4)),
                Text(
                  outletName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: context.rsp(12.5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: context.rh(14)),
                _FadeSwap(
                  swapKey: _contentKind(reading.phase),
                  child: _content(context, accent),
                ),
                SizedBox(height: context.rh(12)),
                _FadeSwap(
                  swapKey: body,
                  child: Text(
                    body,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: context.rsp(12.5),
                      height: 1.45,
                    ),
                  ),
                ),
                SizedBox(height: context.rh(18)),
                _FadeSwap(
                  swapKey: reading.phase,
                  child: _Actions(
                    phase: reading.phase,
                    accent: accent,
                    onCancel: onCancel,
                    onConfirm: onConfirm,
                    onWithReason: onWithReason,
                    onWithoutGps: onWithoutGps,
                    onRetry: onRetry,
                    onOpenSettings: onOpenSettings,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _contentKind(CheckInGpsPhase phase) => switch (phase) {
        CheckInGpsPhase.searching => 'searching',
        CheckInGpsPhase.within ||
        CheckInGpsPhase.weakSignal ||
        CheckInGpsPhase.outside =>
          'measured',
        _ => 'none',
      };

  Widget _content(BuildContext context, Color accent) =>
      switch (reading.phase) {
        CheckInGpsPhase.searching =>
          _SearchProgress(startedAt: reading.searchStartedAt),
        CheckInGpsPhase.within ||
        CheckInGpsPhase.weakSignal ||
        CheckInGpsPhase.outside =>
          _ProximityCard(reading: reading, accent: accent),
        CheckInGpsPhase.servicesDisabled ||
        CheckInGpsPhase.permissionDenied ||
        CheckInGpsPhase.permissionDeniedForever ||
        CheckInGpsPhase.unavailable ||
        CheckInGpsPhase.noOutlet =>
          const SizedBox(width: double.infinity),
      };
}

/// Cross-fades and lifts content when [swapKey] changes. The one transition
/// used everywhere in the dialog, so every change moves the same way.
class _FadeSwap extends StatelessWidget {
  const _FadeSwap({required this.swapKey, required this.child});

  final Object swapKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.12),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey<Object>(swapKey), child: child),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Beacon — radar rings while searching, a settled badge once measured
// ═════════════════════════════════════════════════════════════════════════════

class _LocatorBeacon extends StatefulWidget {
  const _LocatorBeacon({required this.phase, required this.accent});

  final CheckInGpsPhase phase;
  final Color accent;

  @override
  State<_LocatorBeacon> createState() => _LocatorBeaconState();
}

class _LocatorBeaconState extends State<_LocatorBeacon>
    with TickerProviderStateMixin {
  late final AnimationController _radar = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  bool get _searching => widget.phase == CheckInGpsPhase.searching;

  @override
  void initState() {
    super.initState();
    if (_searching) {
      _radar.repeat();
    } else {
      // Parked at the end: no rings, same as arriving here from a search.
      _radar.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant _LocatorBeacon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_searching && !_radar.isAnimating) {
      _radar.repeat();
    } else if (!_searching && _radar.isAnimating) {
      // Let the current ring finish rather than snapping it away.
      _radar.animateTo(1, duration: const Duration(milliseconds: 400));
    }
    if (widget.phase != oldWidget.phase &&
        (widget.phase == CheckInGpsPhase.within ||
            widget.phase == CheckInGpsPhase.noOutlet)) {
      _burst.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _radar.dispose();
    _burst.dispose();
    super.dispose();
  }

  IconData get _icon => switch (widget.phase) {
        CheckInGpsPhase.searching => Icons.gps_not_fixed_rounded,
        CheckInGpsPhase.within => Icons.where_to_vote_rounded,
        CheckInGpsPhase.noOutlet => Icons.add_location_alt_rounded,
        CheckInGpsPhase.weakSignal => Icons.gps_not_fixed_rounded,
        CheckInGpsPhase.outside => Icons.wrong_location_rounded,
        CheckInGpsPhase.servicesDisabled => Icons.location_disabled_rounded,
        CheckInGpsPhase.permissionDenied ||
        CheckInGpsPhase.permissionDeniedForever =>
          Icons.lock_outline_rounded,
        CheckInGpsPhase.unavailable => Icons.gps_off_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final size = context.rr(96);
    final core = context.rr(58);
    final accent = widget.accent;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rings are painted, not rebuilt: `repaint:` drives the painter
          // straight off the controller, so the widget tree is untouched at
          // 60 fps.
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _BeaconPainter(
                  radar: _radar,
                  burst: _burst,
                  color: accent,
                  coreRadius: core / 2,
                ),
              ),
            ),
          ),
          TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: accent),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            builder: (context, color, child) {
              final c = color ?? accent;
              return Container(
                width: core,
                height: core,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      c.withValues(alpha: 0.22),
                      c.withValues(alpha: 0.10),
                    ],
                  ),
                  border: Border.all(color: c.withValues(alpha: 0.25)),
                ),
                alignment: Alignment.center,
                child: child,
              );
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              switchInCurve: Curves.elasticOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: Tween<double>(begin: 0.4, end: 1).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: _searching
                  // A slow turn of the crosshair while searching: motion that
                  // says "working" without the urgency of a spinner.
                  ? RotationTransition(
                      key: const ValueKey('searching'),
                      turns: _radar,
                      child: Icon(_icon, color: accent, size: context.rr(28)),
                    )
                  : Icon(
                      _icon,
                      key: ValueKey(_icon),
                      color: accent,
                      size: context.rr(28),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BeaconPainter extends CustomPainter {
  _BeaconPainter({
    required this.radar,
    required this.burst,
    required this.color,
    required this.coreRadius,
  }) : super(repaint: Listenable.merge([radar, burst]));

  final Animation<double> radar;
  final Animation<double> burst;
  final Color color;
  final double coreRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;
    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // Three staggered rings, each easing outward and fading as it goes.
    if (radar.isAnimating || radar.value < 1) {
      for (var i = 0; i < 3; i++) {
        final t = (radar.value + i / 3) % 1.0;
        final eased = Curves.easeOut.transform(t);
        final r = coreRadius + (maxRadius - coreRadius) * eased;
        final alpha = (1 - t) * (radar.isAnimating ? 1 : 0.4);
        canvas.drawCircle(
            center, r, fill..color = color.withValues(alpha: 0.10 * alpha));
        canvas.drawCircle(
            center, r, stroke..color = color.withValues(alpha: 0.30 * alpha));
      }
    }

    // A single celebratory ring when the rep lands inside the area.
    if (burst.value > 0 && burst.value < 1) {
      final t = Curves.easeOutCubic.transform(burst.value);
      final r = coreRadius + (maxRadius - coreRadius) * t;
      canvas.drawCircle(
        center,
        r,
        stroke
          ..strokeWidth = 2.4 * (1 - t) + 0.6
          ..color = color.withValues(alpha: 0.55 * (1 - t)),
      );
    }
  }

  @override
  bool shouldRepaint(_BeaconPainter old) =>
      old.color != color || old.coreRadius != coreRadius;
}

// ═════════════════════════════════════════════════════════════════════════════
// Searching — progress, elapsed time, rotating tips
// ═════════════════════════════════════════════════════════════════════════════

class _SearchProgress extends StatelessWidget {
  const _SearchProgress({required this.startedAt});

  final DateTime? startedAt;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final total = LocationTrackingCubit.fixSearchTimeout;
    final elapsed = startedAt == null
        ? Duration.zero
        : DateTime.now().difference(startedAt!);
    final int seconds = elapsed.inSeconds.clamp(0, total.inSeconds).toInt();
    final progress = (elapsed.inMilliseconds / total.inMilliseconds)
        .clamp(0.0, 1.0)
        .toDouble();
    final tip = _Copy.tips[(seconds ~/ 4) % _Copy.tips.length];
    final slow = seconds >= total.inSeconds * 0.55;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: context.rw(14), vertical: context.rh(12)),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(context.rr(14)),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                slow ? _Copy.takingLonger : _Copy.searchingFor,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: context.rsp(12),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '${seconds}s',
                style: TextStyle(
                  color: scheme.primary,
                  fontSize: context.rsp(12),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: context.rh(8)),
          // Tweened between the one-second ticks so the bar glides instead of
          // stepping.
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: progress),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.linear,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 5,
                backgroundColor: scheme.primary.withValues(alpha: 0.10),
                valueColor: AlwaysStoppedAnimation(scheme.primary),
              ),
            ),
          ),
          SizedBox(height: context.rh(10)),
          _FadeSwap(
            swapKey: tip,
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded,
                    size: context.rr(14), color: colors.textSecondary),
                SizedBox(width: context.rw(6)),
                Expanded(
                  child: Text(
                    tip,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: context.rsp(11),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Measured — distance, radius, proximity track, signal quality
// ═════════════════════════════════════════════════════════════════════════════

class _ProximityCard extends StatelessWidget {
  const _ProximityCard({required this.reading, required this.accent});

  final CheckInReading reading;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // Whole metres, through intl: a rep does not need centimetres, and the
    // separator is locale-dependent once the figure passes a thousand.
    final format = NumberFormat.decimalPattern(context.languageCode)
      ..maximumFractionDigits = 0;
    String metres(double v) => 'my_visits.check_in_verification.meters'
        .trParams({'value': format.format(v)});

    final radius = reading.radiusMeters;
    final span = math.max(radius * 2, 1.0);
    final position = (reading.distanceMeters / span).clamp(0.0, 1.0).toDouble();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          context.rw(14), context.rh(12), context.rw(14), context.rh(12)),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(context.rr(14)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _Metric(
                  label: 'my_visits.check_in_verification.distance_label'.tr,
                  // Counts to the new figure rather than jumping to it.
                  value: TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: reading.distanceMeters),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => Text(
                      metres(v),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accent,
                        fontSize: context.rsp(20),
                        fontWeight: FontWeight.w900,
                            ),
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: context.rh(34),
                color: colors.border,
                margin: EdgeInsets.symmetric(horizontal: context.rw(12)),
              ),
              Expanded(
                child: _Metric(
                  label: 'my_visits.check_in_verification.radius_label'.tr,
                  value: Text(
                    metres(radius),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: context.rsp(15),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.rh(14)),
          _ProximityTrack(position: position, accent: accent),
          SizedBox(height: context.rh(4)),
          Row(
            children: [
              Text(_Copy.outlet, style: _trackLabel(context)),
              const Spacer(),
              Text(metres(radius), style: _trackLabel(context)),
              const Spacer(),
              Text('${metres(span)}+', style: _trackLabel(context)),
            ],
          ),
          SizedBox(height: context.rh(10)),
          _SignalRow(
            accuracyMeters: reading.accuracyMeters,
            maxAccuracyMeters: reading.maxAccuracyMeters,
          ),
        ],
      ),
    );
  }

  TextStyle _trackLabel(BuildContext context) => TextStyle(
        color: context.appColors.textSecondary,
        fontSize: context.rsp(9.5),
        fontWeight: FontWeight.w600,
      );
}

/// A bar from the outlet (left) to twice the radius (right), with the allowed
/// zone shaded and the rep's marker gliding to their distance.
class _ProximityTrack extends StatelessWidget {
  const _ProximityTrack({required this.position, required this.accent});

  /// 0 = on the pin, 0.5 = on the radius edge, 1 = twice the radius or more.
  final double position;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final marker = context.rr(16);

    return SizedBox(
      height: marker,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Container(
                width: width / 2,
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    colors.success.withValues(alpha: 0.55),
                    colors.success.withValues(alpha: 0.25),
                  ]),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(end: position),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, v, child) => Positioned(
                  left: (width - marker) * v,
                  child: child!,
                ),
                child: Container(
                  width: marker,
                  height: marker,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.45),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SignalRow extends StatelessWidget {
  const _SignalRow({
    required this.accuracyMeters,
    required this.maxAccuracyMeters,
  });

  final double accuracyMeters;
  final double maxAccuracyMeters;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final level = signalLevelFor(accuracyMeters, maxAccuracyMeters);
    final (label, color) = switch (level) {
      >= 3 => (_Copy.strong, colors.success),
      2 => (_Copy.fair, colors.success),
      _ => (_Copy.weak, colors.warning),
    };

    return Row(
      children: [
        SignalBars(level: level, color: color),
        SizedBox(width: context.rw(8)),
        Text(
          '${_Copy.accuracy} ±${accuracyMeters.round()} m',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: context.rsp(11),
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: context.rsp(10.5),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

/// 1–4 bars from a fix's accuracy radius, relative to the policy ceiling.
int signalLevelFor(double accuracyMeters, double maxAccuracyMeters) {
  if (accuracyMeters <= 0) return 4; // static/debug position
  if (accuracyMeters <= maxAccuracyMeters * 0.3) return 4;
  if (accuracyMeters <= maxAccuracyMeters * 0.6) return 3;
  if (accuracyMeters <= maxAccuracyMeters) return 2;
  return 1;
}

/// Four rising bars, filled to [level]. Heights and colours animate, so a fix
/// improving from Weak to Strong visibly climbs.
class SignalBars extends StatelessWidget {
  const SignalBars({super.key, required this.level, required this.color});

  final int level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 1; i <= 4; i++) ...[
          AnimatedContainer(
            duration: Duration(milliseconds: 250 + i * 60),
            curve: Curves.easeOutCubic,
            width: 3.5,
            height: 4.0 + i * 3,
            decoration: BoxDecoration(
              color: i <= level ? color : colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (i < 4) const SizedBox(width: 2),
        ],
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 2,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: context.rsp(10.5),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: context.rh(3)),
        value,
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Actions
// ═════════════════════════════════════════════════════════════════════════════

class _Actions extends StatelessWidget {
  const _Actions({
    required this.phase,
    required this.accent,
    required this.onCancel,
    required this.onConfirm,
    required this.onWithReason,
    required this.onWithoutGps,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final CheckInGpsPhase phase;
  final Color accent;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final VoidCallback onWithReason;
  final VoidCallback onWithoutGps;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    // (label, icon, onTap, colour) for the full-width primary; null → a
    // disabled "Locating…" placeholder that keeps the layout from jumping.
    final (String, IconData, VoidCallback, Color)? primary = switch (phase) {
      CheckInGpsPhase.searching => null,
      CheckInGpsPhase.within || CheckInGpsPhase.noOutlet => (
          'my_visits.check_in_verification.confirm'.tr,
          Icons.check_rounded,
          onConfirm,
          colors.success,
        ),
      CheckInGpsPhase.weakSignal || CheckInGpsPhase.outside => (
          'my_visits.check_in_verification.continue_with_reason'.tr,
          Icons.edit_note_rounded,
          onWithReason,
          accent,
        ),
      CheckInGpsPhase.unavailable => (
          _Copy.withoutGps,
          Icons.edit_location_alt_rounded,
          onWithoutGps,
          accent,
        ),
      CheckInGpsPhase.servicesDisabled => (
          _Copy.turnOn,
          Icons.location_on_rounded,
          onOpenSettings,
          scheme.primary,
        ),
      CheckInGpsPhase.permissionDenied => (
          _Copy.allow,
          Icons.my_location_rounded,
          onOpenSettings,
          scheme.primary,
        ),
      CheckInGpsPhase.permissionDeniedForever => (
          _Copy.openSettings,
          Icons.settings_rounded,
          onOpenSettings,
          scheme.primary,
        ),
    };

    final String? secondaryLabel = switch (phase) {
      CheckInGpsPhase.unavailable => _Copy.tryAgain,
      CheckInGpsPhase.outside || CheckInGpsPhase.weakSignal => _Copy.refresh,
      _ => null,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PressableScale(
          enabled: primary != null,
          child: SizedBox(
            height: context.rh(50),
            child: ElevatedButton(
              onPressed: primary?.$3,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary?.$4 ?? scheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: scheme.primary.withValues(alpha: 0.10),
                disabledForegroundColor: scheme.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.rr(14)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (primary == null)
                    SizedBox(
                      width: context.rr(16),
                      height: context.rr(16),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: scheme.primary,
                      ),
                    )
                  else
                    Icon(primary.$2, size: context.rr(19)),
                  SizedBox(width: context.rw(8)),
                  Flexible(
                    child: Text(
                      primary?.$1 ?? _Copy.locating,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.rsp(14.5),
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: context.rh(6)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                foregroundColor: colors.textSecondary,
                padding: EdgeInsets.symmetric(
                    horizontal: context.rw(18), vertical: context.rh(10)),
              ),
              child: Text('common.cancel'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            if (secondaryLabel != null) ...[
              Container(
                width: 1,
                height: context.rh(16),
                color: colors.border,
              ),
              TextButton.icon(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: scheme.primary,
                  padding: EdgeInsets.symmetric(
                      horizontal: context.rw(18), vertical: context.rh(10)),
                ),
                icon: Icon(Icons.refresh_rounded, size: context.rr(17)),
                label: Text(secondaryLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Shrinks slightly under the finger and springs back — the tactile cue that
/// a tap registered, before the dialog closes.
class _PressableScale extends StatefulWidget {
  const _PressableScale({required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _down = false;

  void _set(bool down) {
    if (!widget.enabled || _down == down) return;
    setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
