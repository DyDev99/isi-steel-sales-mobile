import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

/// A single counter row: SKU name + subtitle, a big centred count, and ±
/// steppers. Tap = ±1, long-press = repeat ±10 while held. Presentational — the
/// count and its mutation live in the owning cubit.
class StockCountRow extends StatelessWidget {
  const StockCountRow({
    super.key,
    required this.name,
    required this.subtitle,
    required this.count,
    required this.onStep,
    this.highlightWhenZero = true,
  });

  final String name;
  final String subtitle;
  final int count;
  final ValueChanged<int> onStep;
  final bool highlightWhenZero;

  @override
  Widget build(BuildContext context) {
    final isOut = highlightWhenZero && count == 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Vibe.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isOut ? Vibe.amber.withValues(alpha: 0.5) : Vibe.stroke),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Vibe.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: isOut ? Vibe.amber : Vibe.muted,
                          fontSize: 11)),
                ],
              ],
            ),
          ),
          StockStepButton(
              icon: Icons.remove_rounded, sign: -1, onDelta: onStep),
          Container(
            width: 46,
            alignment: Alignment.center,
            child: Text('$count',
                style: const TextStyle(
                    color: Vibe.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
          ),
          StockStepButton(icon: Icons.add_rounded, sign: 1, onDelta: onStep),
        ],
      ),
    );
  }
}

/// Large hit-target stepper. Tap = ±1, long-press = repeat ±10 while held so a
/// rep can rack up big counts without hundreds of taps.
class StockStepButton extends StatefulWidget {
  const StockStepButton({
    super.key,
    required this.icon,
    required this.sign,
    required this.onDelta,
  });

  final IconData icon;
  final int sign;
  final ValueChanged<int> onDelta;

  @override
  State<StockStepButton> createState() => _StockStepButtonState();
}

class _StockStepButtonState extends State<StockStepButton> {
  Timer? _timer;

  void _startHold() {
    HapticFeedback.selectionClick();
    widget.onDelta(widget.sign * 10);
    _timer = Timer.periodic(const Duration(milliseconds: 220), (_) {
      HapticFeedback.selectionClick();
      widget.onDelta(widget.sign * 10);
    });
  }

  void _endHold() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onDelta(widget.sign),
      onLongPressStart: (_) => _startHold(),
      onLongPressEnd: (_) => _endHold(),
      onLongPressCancel: _endHold,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Vibe.violet.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(widget.icon, color: Vibe.violet, size: 24),
      ),
    );
  }
}
