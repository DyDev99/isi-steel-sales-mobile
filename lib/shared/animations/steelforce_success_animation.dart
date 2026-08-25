import 'dart:math' as math;

import 'package:flutter/material.dart';

/// SteelForce's success mark — the confirmation shown when an important action
/// lands: a visit completed, a quotation saved, a customer added.
///
/// ## What it draws, and what it deliberately does not
///
/// Modelled on the SteelForce success artwork: a glowing blue check badge over
/// a stack of steel, ringed with energy arcs, with a brief burst of particles.
/// The mascot, flag and skyline in that render are **not** attempted. A robot
/// approximated in vector shapes reads as a worse drawing rather than a simpler
/// one, and a reusable success component has no business carrying a background
/// illustration. The check is the hero; everything else is secondary.
///
/// ## Plays once, then breathes
///
/// A celebration that loops stops being one — the third repeat of a burst is
/// noise on a screen the user is trying to read. The sequence runs a single
/// time; afterwards a slow glow keeps the mark alive without asking for
/// attention again. Set [loop] only for a demo surface.
///
/// ## Presentation only
///
/// No business logic, no BLoC dependency. Trigger it from a success state:
///
/// ```dart
/// final _success = GlobalKey<SteelForceSuccessAnimationState>();
/// ...
/// BlocListener<OrderBloc, OrderState>(
///   listener: (context, state) {
///     if (state is OrderSubmitted) _success.currentState?.play();
///   },
///   child: SteelForceSuccessAnimation(key: _success, autoPlay: false),
/// )
/// ```
class SteelForceSuccessAnimation extends StatefulWidget {
  const SteelForceSuccessAnimation({
    super.key,
    this.size = 140,
    this.autoPlay = true,
    this.duration = const Duration(milliseconds: 2000),
    this.onCompleted,
    this.loop = false,
    this.primaryColor,
    this.checkColor = Colors.white,
    this.showParticles = true,
    this.showGlow = true,
    this.particleCount = 16,
    this.semanticLabel,
  });

  final double size;

  /// Start on first frame. False when a BLoC state will call [play].
  final bool autoPlay;
  final Duration duration;

  /// Fired once the sequence settles. Not called for each pass when [loop].
  final VoidCallback? onCompleted;
  final bool loop;

  /// Defaults to the app's `colorScheme.primary`, so the mark belongs to
  /// whatever theme hosts it rather than hardcoding a blue that fights it.
  final Color? primaryColor;
  final Color checkColor;
  final bool showParticles;
  final bool showGlow;

  /// Restrained on purpose. Past roughly twenty this reads as a party popper
  /// rather than a job done, and every extra piece costs a frame budget on the
  /// low-end Androids a field team actually carries.
  final int particleCount;

  final String? semanticLabel;

  @override
  State<SteelForceSuccessAnimation> createState() =>
      SteelForceSuccessAnimationState();
}

class SteelForceSuccessAnimationState extends State<SteelForceSuccessAnimation>
    with TickerProviderStateMixin {
  /// The one-shot arrival: badge, ring, check, shockwave, particles.
  late final AnimationController _sequence;

  /// The idle afterwards — a slow breath on the glow only. Kept separate so it
  /// can run forever without the arrival restarting with it.
  late final AnimationController _breathe;

  bool _notified = false;

  @override
  void initState() {
    super.initState();
    _sequence = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener(_onStatus);
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    // Scheduled rather than started inline so the first painted frame is frame
    // zero of the arrival, not a frame of the finished state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _breathe.repeat(reverse: true);
      if (widget.autoPlay) play();
    });
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (widget.loop) {
      _sequence.forward(from: 0);
      return;
    }
    // Once only: a rebuild must not re-fire the caller's completion handler.
    if (_notified) return;
    _notified = true;
    widget.onCompleted?.call();
  }

  /// Restarts the sequence from the beginning.
  void play() {
    _notified = false;
    _sequence.forward(from: 0);
  }

  /// Returns to the empty state without animating.
  void reset() {
    _notified = false;
    _sequence.value = 0;
  }

  @override
  void dispose() {
    _sequence
      ..removeStatusListener(_onStatus)
      ..dispose();
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final accent = widget.primaryColor ?? Theme.of(context).colorScheme.primary;

    return Semantics(
      label: widget.semanticLabel,
      // Decorative unless labelled: a screen reader should hear the heading
      // that follows this, not "image" ahead of it.
      excludeSemantics: widget.semanticLabel == null,
      child: RepaintBoundary(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: Listenable.merge([_sequence, _breathe]),
            builder: (context, _) => CustomPaint(
              painter: _SuccessPainter(
                // Reduced motion gets the settled mark: badge, ring and check,
                // no burst and no shockwave. The picture carries the meaning;
                // only the movement is optional.
                t: reduceMotion ? _settledFrame : _sequence.value,
                breath: reduceMotion ? 0.5 : _breathe.value,
                accent: accent,
                checkColor: widget.checkColor,
                showGlow: widget.showGlow,
                particleCount: (reduceMotion || !widget.showParticles)
                    ? 0
                    : widget.particleCount,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Past every arrival beat and after the particles have cleared.
  static const double _settledFrame = 0.86;
}

// ── Palette for the secondary industrial elements ───────────────────────────
const _steel = Color(0xFF94A3B8);
const _steelDark = Color(0xFF64748B);

double _u(double v) => v.isNaN ? 0.0 : v.clamp(0.0, 1.0);

double _phase(double t, double a, double b, [Curve c = Curves.easeOutCubic]) =>
    b <= a ? 0 : c.transform(_u((t - a) / (b - a)));

class _SuccessPainter extends CustomPainter {
  _SuccessPainter({
    required this.t,
    required this.breath,
    required this.accent,
    required this.checkColor,
    required this.showGlow,
    required this.particleCount,
  });

  final double t;
  final double breath;
  final Color accent;
  final Color checkColor;
  final bool showGlow;
  final int particleCount;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100.0;
    final c = Offset(size.width * 0.5, size.height * 0.46);

    _paintSteel(canvas, s, size);
    _paintRipple(canvas, s, c);
    _paintArcs(canvas, s, c);
    _paintBadge(canvas, s, c);
    _paintShockwave(canvas, s, c);
    // Particles last so the burst passes *in front of* the badge. Painted
    // underneath, its first third is hidden behind the very thing it is
    // celebrating, and the pieces only appear once already clear of it — which
    // reads as debris drifting in rather than as a burst.
    _paintParticles(canvas, s, size, c);
  }

  /// Scale bump at impact: 1.0 → 1.08 → 1.0.
  double get _impactScale {
    final k = _phase(t, 0.54, 0.72, Curves.linear);
    return k <= 0 || k >= 1 ? 1.0 : 1 + 0.08 * math.sin(k * math.pi);
  }

  /// A small stack of bar ends — the steel the action was about. Rises under
  /// the badge rather than with it, so the eye reads the badge first.
  void _paintSteel(Canvas canvas, double s, Size size) {
    final rise = _phase(t, 0.10, 0.40);
    if (rise <= 0) return;

    canvas.save();
    canvas.translate(0, (1 - rise) * 14 * s);
    final baseY = size.height * 0.90;
    final cx = size.width * 0.5;

    for (var row = 0; row < 2; row++) {
      final count = row == 0 ? 4 : 3;
      final w = 11.0 * s, h = 7.0 * s;
      final y = baseY - row * (h + 1.4 * s);
      final startX = cx - (count * w + (count - 1) * 1.6 * s) / 2;
      for (var i = 0; i < count; i++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(startX + i * (w + 1.6 * s), y - h, w, h),
            Radius.circular(1.8 * s),
          ),
          Paint()
            ..color =
                (row == 0 ? _steelDark : _steel).withValues(alpha: 0.55 * rise),
        );
      }
    }
    canvas.restore();
  }

  /// Soft radial ripple on arrival — the energy expanding outward.
  void _paintRipple(Canvas canvas, double s, Offset c) {
    final r = _phase(t, 0.04, 0.42);
    if (r <= 0 || r >= 1) return;
    canvas.drawCircle(
      c,
      (18 + 30 * r) * s,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * s
        ..color = accent.withValues(alpha: 0.30 * (1 - r)),
    );
  }

  /// Two thin orbital arcs — the energy swooshes from the reference, kept
  /// secondary so they never compete with the check.
  void _paintArcs(Canvas canvas, double s, Offset c) {
    final show = _phase(t, 0.16, 0.52);
    if (show <= 0) return;
    // Drift slowly forever, so the settled mark still has life in it.
    final spin = breath * math.pi * 0.5;

    for (var i = 0; i < 2; i++) {
      final radius = (32 + i * 5.5) * s;
      final start = spin + i * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: radius),
        start,
        math.pi * 0.55 * show,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 * s
          ..strokeCap = StrokeCap.round
          ..color = accent.withValues(alpha: 0.30 * show),
      );
    }
  }

  void _paintBadge(Canvas canvas, double s, Offset c) {
    // 0.5 → 1.1 → 1.0, via easeOutBack's own overshoot.
    final pop = _phase(t, 0.00, 0.34, Curves.easeOutBack);
    if (pop <= 0) return;
    final r = 21 * s * (0.5 + 0.5 * pop) * _impactScale;

    if (showGlow) {
      // Brightens at impact, then settles into a slow breath.
      final impact = _phase(t, 0.54, 0.66, Curves.linear);
      final glow = 0.18 + 0.10 * breath + 0.22 * math.sin(impact * math.pi);
      canvas.drawCircle(
        c,
        r * 1.55,
        Paint()
          ..color = accent.withValues(alpha: (glow * pop).clamp(0.0, 1.0))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }

    canvas.drawCircle(c, r, Paint()..color = accent);

    final ring = _phase(t, 0.12, 0.52);
    if (ring > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r + 7 * s),
        -math.pi / 2,
        math.pi * 2 * ring,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6 * s
          ..strokeCap = StrokeCap.round
          ..color = accent.withValues(alpha: 0.55),
      );
    }

    _paintCheck(canvas, s, c, r);
  }

  /// Drawn with `PathMetric`, not faded in — the stroke travelling left to
  /// right is what makes it read as confirmation rather than a stamp.
  void _paintCheck(Canvas canvas, double s, Offset c, double r) {
    final tick = _phase(t, 0.26, 0.58);
    if (tick <= 0) return;

    final path = Path()
      ..moveTo(c.dx - r * 0.44, c.dy + r * 0.02)
      ..lineTo(c.dx - r * 0.10, c.dy + r * 0.34)
      ..lineTo(c.dx + r * 0.46, c.dy - r * 0.30);

    final segs = path.computeMetrics().toList();
    final total = segs.fold<double>(0, (a, b) => a + b.length);
    final drawn = Path();
    var left = tick * total;
    for (final seg in segs) {
      if (left <= 0) break;
      drawn.addPath(
          seg.extractPath(0, math.min(left, seg.length)), Offset.zero);
      left -= seg.length;
    }
    canvas.drawPath(
      drawn,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.2 * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = checkColor,
    );
  }

  /// A single expanding ring at the moment the check completes.
  void _paintShockwave(Canvas canvas, double s, Offset c) {
    final w = _phase(t, 0.56, 0.80);
    if (w <= 0 || w >= 1) return;
    canvas.drawCircle(
      c,
      (24 + 40 * w) * s,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0 * s * (1 - w)
        ..color = accent.withValues(alpha: 0.45 * (1 - w)),
    );
  }

  /// Deterministic burst: angles and speeds come from the index, not a
  /// `Random`, so the animation is identical on every run and a golden of a
  /// screen containing it is stable.
  void _paintParticles(Canvas canvas, double s, Size size, Offset c) {
    if (particleCount == 0) return;
    final launch = _phase(t, 0.52, 1.00, Curves.linear);
    if (launch <= 0) return;

    final palette = [
      accent,
      _steel,
      Colors.white,
      Color.lerp(accent, Colors.white, 0.45)!,
    ];

    for (var i = 0; i < particleCount; i++) {
      // Nudged per index so the spread does not read as a clock face.
      final angle = (i / particleCount) * math.pi * 2 + (i % 3) * 0.22;
      final speed = 52 + (i % 5) * 11.0;
      // Launched from the badge rim: a particle starting inside the badge has
      // to travel through it before it exists.
      const rim = 22.0;

      // Eased travel against squared gravity — that mismatch is what makes it
      // read as thrown rather than scaled.
      final out = rim * s + Curves.easeOutCubic.transform(launch) * speed * s;
      final drop = launch * launch * 58 * s;

      final p = Offset(
        c.dx + math.cos(angle) * out,
        c.dy + math.sin(angle) * out * 0.75 + drop,
      );
      if (p.dy > size.height + 8 * s) continue;

      // Gone well before the end, so the settled screen is the mark alone.
      final fade = 1 - _phase(t, 0.66, 0.92, Curves.easeIn);
      if (fade <= 0) continue;

      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(angle + launch * 5.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 3.4 * s, height: 5.2 * s),
          Radius.circular(0.8 * s),
        ),
        Paint()..color = palette[i % palette.length].withValues(alpha: fade),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SuccessPainter old) =>
      old.t != t ||
      old.breath != breath ||
      old.accent != accent ||
      old.checkColor != checkColor ||
      old.particleCount != particleCount ||
      old.showGlow != showGlow;
}
