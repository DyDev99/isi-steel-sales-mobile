import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

/// The quantity control that *is* the add-to-cart action.
///
/// There is no separate "Add" button anywhere in the product list: quantity
/// above zero means the line is in the quotation, zero means it isn't. That
/// removes a whole class of "I tapped add but nothing happened" confusion and
/// halves the taps for the common case of ordering several of one SKU.
///
/// Named [CartQuantityStepper] rather than `QuantityStepper` because the older
/// standalone `widgets/filter/quantity_stepper.dart` still exists; two widgets
/// with the same class name in one feature is a trap for the next person.
class CartQuantityStepper extends StatefulWidget {
  const CartQuantityStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.max,
    this.enabled = true,
  });

  final int quantity;

  /// Called with the new quantity on every change, including zero — the caller
  /// treats zero as "remove this line".
  final ValueChanged<int> onChanged;

  /// Upper bound (available stock). Null means unbounded.
  final int? max;

  final bool enabled;

  @override
  State<CartQuantityStepper> createState() => _CartQuantityStepperState();
}

class _CartQuantityStepperState extends State<CartQuantityStepper> {
  Timer? _repeat;

  @override
  void dispose() {
    _repeat?.cancel();
    super.dispose();
  }

  bool get _canDecrease => widget.enabled && widget.quantity > 0;
  bool get _canIncrease =>
      widget.enabled && (widget.max == null || widget.quantity < widget.max!);

  void _step(int delta) {
    final next = widget.quantity + delta;
    if (next < 0) return;
    if (widget.max != null && next > widget.max!) return;
    HapticFeedback.selectionClick();
    widget.onChanged(next);
  }

  /// Long press ramps up: slow at first so a held thumb doesn't overshoot by
  /// twenty, then faster once the intent is obvious.
  void _startRepeat(int delta) {
    _repeat?.cancel();
    var elapsed = 0;
    _repeat = Timer.periodic(const Duration(milliseconds: 90), (timer) {
      elapsed += 90;
      final fast = elapsed > 900;
      if (!fast && elapsed % 180 != 0) return;
      if (delta > 0 ? !_canIncrease : !_canDecrease) {
        timer.cancel();
        return;
      }
      _step(delta);
    });
  }

  void _stopRepeat() {
    _repeat?.cancel();
    _repeat = null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final inCart = widget.quantity > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: inCart
            ? scheme.primary.withValues(alpha: 0.10)
            : colors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: inCart ? scheme.primary : colors.border,
          width: inCart ? 1.4 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            enabled: _canDecrease,
            onTap: () => _step(-1),
            onLongPressStart: () => _startRepeat(-1),
            onLongPressEnd: _stopRepeat,
          ),
          SizedBox(
            width: 34,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: Text(
                '${widget.quantity}',
                key: ValueKey(widget.quantity),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: inCart ? scheme.primary : colors.textSecondary,
                  fontSize: context.rsp(14),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            enabled: _canIncrease,
            onTap: () => _step(1),
            onLongPressStart: () => _startRepeat(1),
            onLongPressEnd: _stopRepeat,
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
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onLongPressStart: enabled ? (_) => onLongPressStart() : null,
      onLongPressEnd: enabled ? (_) => onLongPressEnd() : null,
      onLongPressCancel: enabled ? onLongPressEnd : null,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: enabled ? 1 : 0.3,
            child: Icon(icon, size: context.rr(17), color: colors.textPrimary),
          ),
        ),
      ),
    );
  }
}
