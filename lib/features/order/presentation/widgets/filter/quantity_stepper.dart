import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

/// A `[-]  n  [+]` quantity stepper with press-and-hold auto-repeat.
///
/// Presentational and controlled: the parent owns [value] and receives every
/// change through [onChanged], clamped to [min]…[max]. Holding a button starts
/// a repeating increment/decrement that accelerates slightly, and the minus
/// button auto-disables at [min] (same for plus at [max]).
class QuantityStepper extends StatefulWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 9999,
    this.step = 1,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;

  @override
  State<QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<QuantityStepper> {
  Timer? _repeatTimer;

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  void _apply(int delta) {
    final next = (widget.value + delta).clamp(widget.min, widget.max);
    if (next != widget.value) {
      HapticFeedback.selectionClick();
      widget.onChanged(next);
    }
  }

  void _startRepeat(int delta) {
    _apply(delta);
    _repeatTimer?.cancel();
    // Initial hold delay, then a steady fast repeat.
    _repeatTimer = Timer(const Duration(milliseconds: 350), () {
      _repeatTimer = Timer.periodic(
        const Duration(milliseconds: 80),
        (_) => _apply(delta),
      );
    });
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final canDecrement = widget.value > widget.min;
    final canIncrement = widget.value < widget.max;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Vibe.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Vibe.stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            enabled: canDecrement,
            onTap: () => _apply(-widget.step),
            onHoldStart: () => _startRepeat(-widget.step),
            onHoldEnd: _stopRepeat,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 46),
            alignment: Alignment.center,
            child: Text(
              '${widget.value}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Vibe.text,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            enabled: canIncrement,
            onTap: () => _apply(widget.step),
            onHoldStart: () => _startRepeat(widget.step),
            onHoldEnd: _stopRepeat,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.onHoldStart,
    required this.onHoldEnd,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: enabled ? (_) => onHoldStart() : null,
      onLongPressEnd: enabled ? (_) => onHoldEnd() : null,
      onLongPressCancel: enabled ? onHoldEnd : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              size: 20,
              color: enabled ? Vibe.violet : Vibe.disabledText,
            ),
          ),
        ),
      ),
    );
  }
}
