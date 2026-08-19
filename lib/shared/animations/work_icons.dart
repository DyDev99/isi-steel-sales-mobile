import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Hand-drawn, gently animated icons for the My Work grid.
///
/// ## Why these are drawn rather than rendered artwork
///
/// The reference sheet's illustrations came with their colour baked into a
/// tile, and separating figure from ground broke them wherever the two shared
/// a hue. Drawing them means the background is transparent by construction,
/// every colour is a brand token, they stay crisp at any size, and — the part
/// artwork cannot do — they can *move*.
///
/// ## The motion is deliberately slow
///
/// Each icon runs a ~5 second cycle in which the action occupies barely two
/// seconds and the rest is stillness. Three looping animations sit on the home
/// screen permanently; anything brisker turns a work screen into a fairground.
/// The action reads once, then rests, which is what "calm" means in a tool
/// somebody opens forty times a day.
///
/// Every icon honours `MediaQuery.disableAnimations` by holding its finished
/// frame — the drawing carries the meaning, only the movement is optional.
enum WorkIconKind { visits, customers, quotesOrders }

class WorkIcon extends StatefulWidget {
  const WorkIcon({
    super.key,
    required this.kind,
    required this.accent,
    required this.size,
  });

  final WorkIconKind kind;
  final Color accent;
  final double size;

  @override
  State<WorkIcon> createState() => _WorkIconState();
}

class _WorkIconState extends State<WorkIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _loop,
          builder: (context, _) {
            // The frame every icon has finished on but none has begun to fade
            // from. It must sit after the *last* thing any of them draws —
            // the orders tick completes at 0.78 — and before the cycle fades
            // out at 0.90. Picking 0.62 (the moment the pin lands) left the
            // approval tick unstarted, so reduce-motion users saw a blank
            // green disc where the confirmation should be.
            final t = reduceMotion ? 0.84 : _loop.value;
            return CustomPaint(
              painter: switch (widget.kind) {
                WorkIconKind.visits =>
                  _VisitsPainter(t: t, accent: widget.accent),
                WorkIconKind.customers =>
                  _CustomersPainter(t: t, accent: widget.accent),
                WorkIconKind.quotesOrders =>
                  _OrdersPainter(t: t, accent: widget.accent),
              },
            );
          },
        ),
      ),
    );
  }
}

// ── Shared drawing helpers ──────────────────────────────────────────────────

const _ink = Color(0xFF334155); // outlines
const _paper = Color(0xFFFFFFFF); // fills that must read as "surface"
const _shade = Color(0xFFE2E8F0); // soft secondary fill
const _go = Color(0xFF22C55E); // confirmation green

double _u(double v) => v.isNaN ? 0.0 : v.clamp(0.0, 1.0);

/// Eases a value in over [start]..[end] of the loop.
double _phase(double t, double start, double end,
    [Curve curve = Curves.easeInOutCubic]) {
  if (end <= start) return 0;
  return curve.transform(_u((t - start) / (end - start)));
}

/// The whole icon fades down at the very end of the cycle and back up at the
/// start, so a loop never reads as a hard cut.
double _cycleOpacity(double t) {
  final out = 1 - _phase(t, 0.90, 1.00, Curves.easeIn);
  final into = _phase(t, 0.00, 0.06, Curves.easeOut);
  return (out * into).clamp(0.0, 1.0);
}

// ── My Visits ───────────────────────────────────────────────────────────────

/// A route drawing itself out to a shopfront, then a pin arriving on it.
///
/// This is the one icon whose meaning the reference sheet could not supply:
/// "see the outlet and start the visit" needs a route and a storefront, and
/// the sheet had neither. Drawn here, it says exactly that — you leave, you
/// travel, you arrive at a shop.
class _VisitsPainter extends CustomPainter {
  _VisitsPainter({required this.t, required this.accent});

  final double t;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100.0;
    final o = _cycleOpacity(t);
    if (o <= 0.01) return;
    canvas.saveLayer(
        Offset.zero & size, Paint()..color = Colors.white.withValues(alpha: o));

    // ── The outlet: a small storefront, top-right ──────────────────────────
    final shopIn = _phase(t, 0.02, 0.22, Curves.easeOutBack);
    if (shopIn > 0) {
      canvas.save();
      canvas.translate(70 * s, 30 * s);
      canvas.scale(shopIn);
      canvas.translate(-70 * s, -30 * s);

      // body
      final body = RRect.fromRectAndRadius(
        Rect.fromLTWH(56 * s, 24 * s, 30 * s, 24 * s),
        Radius.circular(3 * s),
      );
      canvas.drawRRect(body, Paint()..color = _paper);
      canvas.drawRRect(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4 * s
          ..color = _ink,
      );
      // awning
      final awning = RRect.fromRectAndRadius(
        Rect.fromLTWH(53 * s, 17 * s, 36 * s, 8 * s),
        Radius.circular(3 * s),
      );
      canvas.drawRRect(awning, Paint()..color = accent);
      // door
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(66 * s, 34 * s, 10 * s, 14 * s),
          Radius.circular(1.5 * s),
        ),
        Paint()..color = _shade,
      );
      canvas.restore();
    }

    // ── The route ─────────────────────────────────────────────────────────
    final path = Path()
      ..moveTo(16 * s, 84 * s)
      ..cubicTo(14 * s, 66 * s, 34 * s, 64 * s, 38 * s, 52 * s)
      ..cubicTo(42 * s, 40 * s, 58 * s, 54 * s, 62 * s, 44 * s);

    final metric = path.computeMetrics().first;

    // The full route sits faint underneath: a rep is shown where they are
    // going, not only where they have been.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 * s
        ..strokeCap = StrokeCap.round
        ..color = accent.withValues(alpha: 0.18),
    );

    final travelled = _phase(t, 0.18, 0.56);
    if (travelled > 0) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * travelled),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 * s
          ..strokeCap = StrokeCap.round
          ..color = accent,
      );
    }

    // origin dot
    canvas.drawCircle(Offset(16 * s, 84 * s), 4.5 * s, Paint()..color = _paper);
    canvas.drawCircle(
      Offset(16 * s, 84 * s),
      4.5 * s,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * s
        ..color = _ink,
    );

    // ── The pin: rides the route, then settles on the shop ────────────────
    if (travelled > 0.02) {
      final at =
          metric.getTangentForOffset(metric.length * travelled)!.position;
      final landed = _phase(t, 0.52, 0.62, Curves.easeOutBack);
      // A gentle hop as it arrives, rather than a drop from off-screen: the
      // brief asked for natural and calm, and gravity here would read as
      // urgency.
      final lift = -6 * s * math.sin(landed * math.pi);
      final centre = Offset(at.dx, at.dy + lift);

      // arrival pulse
      if (landed > 0) {
        final ring = _phase(t, 0.58, 0.80, Curves.easeOut);
        if (ring > 0 && ring < 1) {
          canvas.drawCircle(
            centre,
            (6 + 16 * ring) * s,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2 * s
              ..color = accent.withValues(alpha: 0.45 * (1 - ring)),
          );
        }
      }
      _drawPin(canvas, centre, 9 * s, accent);
    }

    canvas.restore();
  }

  void _drawPin(Canvas canvas, Offset c, double r, Color color) {
    // Teardrop: a circle with a point beneath it.
    final p = Path()
      ..addOval(Rect.fromCircle(center: c, radius: r))
      ..moveTo(c.dx - r * 0.62, c.dy + r * 0.62)
      ..lineTo(c.dx, c.dy + r * 1.9)
      ..lineTo(c.dx + r * 0.62, c.dy + r * 0.62)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
    canvas.drawCircle(c, r * 0.38, Paint()..color = _paper);
  }

  @override
  bool shouldRepaint(_VisitsPainter old) => old.t != t || old.accent != accent;
}

// ── My Customers ────────────────────────────────────────────────────────────

/// Three figures gathering, then a contact card settling in front.
class _CustomersPainter extends CustomPainter {
  _CustomersPainter({required this.t, required this.accent});

  final double t;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100.0;
    final o = _cycleOpacity(t);
    if (o <= 0.01) return;
    canvas.saveLayer(
        Offset.zero & size, Paint()..color = Colors.white.withValues(alpha: o));

    // Back figures first, staggered — a small crowd assembling, not popping.
    _figure(canvas, s, Offset(28 * s, 44 * s), 9 * s,
        accent.withValues(alpha: 0.45), _phase(t, 0.06, 0.30, Curves.easeOut));
    _figure(canvas, s, Offset(72 * s, 44 * s), 9 * s,
        accent.withValues(alpha: 0.30), _phase(t, 0.12, 0.36, Curves.easeOut));
    // The main customer, front and centre.
    _figure(canvas, s, Offset(50 * s, 38 * s), 13 * s, accent,
        _phase(t, 0.00, 0.26, Curves.easeOutBack));

    // ── Contact card ──────────────────────────────────────────────────────
    final card = _phase(t, 0.34, 0.56, Curves.easeOutBack);
    if (card > 0) {
      canvas.save();
      // Rises into place rather than fading: it reads as being handed over.
      canvas.translate(0, (1 - card) * 10 * s);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(24 * s, 66 * s, 52 * s, 24 * s),
        Radius.circular(5 * s),
      );
      canvas.drawRRect(rect, Paint()..color = _paper);
      canvas.drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4 * s
          ..color = _ink,
      );
      // avatar chip
      canvas.drawCircle(
          Offset(36 * s, 78 * s), 5.5 * s, Paint()..color = accent);
      // two detail lines, drawn left to right
      final lines = _phase(t, 0.44, 0.66);
      for (var i = 0; i < 2; i++) {
        final w = (20 - i * 6) * s * lines;
        if (w <= 0) continue;
        canvas.drawLine(
          Offset(47 * s, (74 + i * 8) * s),
          Offset(47 * s + w, (74 + i * 8) * s),
          Paint()
            ..strokeWidth = 3 * s
            ..strokeCap = StrokeCap.round
            ..color = _shade,
        );
      }
      canvas.restore();
    }

    canvas.restore();
  }

  void _figure(
      Canvas canvas, double s, Offset head, double r, Color color, double in_) {
    if (in_ <= 0) return;
    canvas.save();
    canvas.translate(head.dx, head.dy);
    canvas.scale(in_);
    canvas.translate(-head.dx, -head.dy);
    canvas.drawCircle(head, r, Paint()..color = color);
    // shoulders
    final body =
        Rect.fromLTWH(head.dx - r * 1.5, head.dy + r * 0.7, r * 3, r * 2.4);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        body,
        topLeft: Radius.circular(r * 1.5),
        topRight: Radius.circular(r * 1.5),
      ),
      Paint()..color = color,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CustomersPainter old) =>
      old.t != t || old.accent != accent;
}

// ── My Quotes & Orders ──────────────────────────────────────────────────────

/// A quotation writing itself, then being approved.
class _OrdersPainter extends CustomPainter {
  _OrdersPainter({required this.t, required this.accent});

  final double t;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100.0;
    final o = _cycleOpacity(t);
    if (o <= 0.01) return;
    canvas.saveLayer(
        Offset.zero & size, Paint()..color = Colors.white.withValues(alpha: o));

    // ── The sheet ─────────────────────────────────────────────────────────
    final sheetIn = _phase(t, 0.00, 0.20, Curves.easeOutBack);
    if (sheetIn > 0) {
      canvas.save();
      canvas.translate(50 * s, 50 * s);
      canvas.scale(sheetIn);
      canvas.translate(-50 * s, -50 * s);

      final sheet = RRect.fromRectAndRadius(
        Rect.fromLTWH(22 * s, 12 * s, 50 * s, 66 * s),
        Radius.circular(6 * s),
      );
      canvas.drawRRect(sheet, Paint()..color = _paper);
      canvas.drawRRect(
        sheet,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6 * s
          ..color = _ink,
      );
      // header band — the quotation's title block
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(30 * s, 21 * s, 26 * s, 6 * s),
          Radius.circular(3 * s),
        ),
        Paint()..color = accent,
      );
      canvas.restore();
    }

    // ── Line items, written one at a time ─────────────────────────────────
    // Sequential rather than simultaneous: a quotation is built up line by
    // line, and staggering is what makes the icon read as *composing* one.
    const widths = [30.0, 24.0, 27.0];
    for (var i = 0; i < widths.length; i++) {
      final start = 0.22 + i * 0.09;
      final w = widths[i] * s * _phase(t, start, start + 0.12);
      if (w <= 0) continue;
      canvas.drawLine(
        Offset(30 * s, (37 + i * 10) * s),
        Offset(30 * s + w, (37 + i * 10) * s),
        Paint()
          ..strokeWidth = 3.4 * s
          ..strokeCap = StrokeCap.round
          ..color = _shade,
      );
    }

    // ── Approval ──────────────────────────────────────────────────────────
    final stamp = _phase(t, 0.56, 0.70, Curves.easeOutBack);
    if (stamp > 0) {
      final c = Offset(70 * s, 70 * s);
      canvas.drawCircle(c, 17 * s * stamp, Paint()..color = _paper);
      canvas.drawCircle(c, 15 * s * stamp, Paint()..color = _go);

      // The tick draws rather than appears — the moment of approval, not a
      // sticker dropped on top.
      final tick = _phase(t, 0.62, 0.78);
      if (tick > 0) {
        final p = Path()
          ..moveTo(c.dx - 7 * s, c.dy)
          ..lineTo(c.dx - 2 * s, c.dy + 5.5 * s)
          ..lineTo(c.dx + 7.5 * s, c.dy - 5.5 * s);
        final segs = p.computeMetrics().toList();
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
            ..strokeWidth = 3.6 * s
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = _paper,
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_OrdersPainter old) => old.t != t || old.accent != accent;
}
