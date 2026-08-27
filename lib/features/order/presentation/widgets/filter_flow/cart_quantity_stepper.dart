import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/material_availability.dart';

/// The quantity control that *is* the add-to-cart action.
///
/// There is no separate "Add" button anywhere in the product list: quantity
/// above zero means the line is in the quotation, zero means it isn't. That
/// removes a whole class of "I tapped add but nothing happened" confusion and
/// halves the taps for the common case of ordering several of one SKU.
///
/// The number is tappable. Steppers are for nudging; a rep entering 250 tonnes
/// should not be holding a `+`.
///
/// ## What gates `+`, and what deliberately does not
///
/// The `+` is gated on **[MaterialAvailability.canOrder] — the status — and
/// never on the band.**
///
/// There is no on-hand quantity anywhere in this API to bound against. The
/// stock endpoint answers `"High"` / `"Medium"` / `"Low"` / `"None"`, which
/// describes how much rather than capping what may be ordered. `Low` is a
/// warning, not a limit, and blocking on it would refuse orders SAP would
/// accept.
///
/// | Stock | `-` | `n` | `+` |
/// |---|---|---|---|
/// | never asked / `checking` / `unknown` | live | editable | live |
/// | `available` — `High` through `None` | live | editable | live |
/// | `unavailable` | **live** | locked | **blocked** |
///
/// `-` stays live through a refusal. A rep taking a line back down to zero must
/// not be stopped by the verdict that is stopping them adding to it.
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
    this.stock,
  });

  final int quantity;

  /// Called with the new quantity on every change, including zero — the caller
  /// treats zero as "remove this line".
  final ValueChanged<int> onChanged;

  /// A guard against a mistyped `999999`, **not a stock ceiling.** Nothing on
  /// the wire supplies an on-hand figure to bound this with; the band is not
  /// one. Null means unbounded.
  final int? max;

  final bool enabled;

  /// SAP's verdict for this material. Null means never asked, which leaves the
  /// stepper fully live — a rep is not blocked on a question that has not been
  /// answered.
  final MaterialAvailability? stock;

  @override
  State<CartQuantityStepper> createState() => _CartQuantityStepperState();
}

class _CartQuantityStepperState extends State<CartQuantityStepper> {
  Timer? _repeat;
  bool _editing = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// Only the status decides. See the class doc for why the band does not.
  bool get _canOrder => widget.stock?.canOrder ?? true;

  bool get _canDecrease => widget.enabled && widget.quantity > 0;
  bool get _canIncrease =>
      widget.enabled &&
      _canOrder &&
      (widget.max == null || widget.quantity < widget.max!);

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      // Tapping away commits rather than discards — the number on screen is
      // what the rep meant, whether or not they found the done key.
      if (!_focusNode.hasFocus && _editing) _commit();
    });
  }

  @override
  void dispose() {
    _repeat?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _beginEdit() {
    if (!widget.enabled || !_canOrder) return;
    _controller.text = '${widget.quantity}';
    _controller.selection =
        TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
    setState(() => _editing = true);
  }

  void _commit() {
    final parsed = int.tryParse(_controller.text.trim());
    setState(() => _editing = false);

    // An empty or unparseable field is not an instruction to remove the line.
    // It is a rep who cleared the box and tapped away, so nothing changes.
    if (parsed == null) return;

    var next = parsed < 0 ? 0 : parsed;
    if (widget.max != null && next > widget.max!) next = widget.max!;
    // A refused line cannot be raised by typing either. Leaving the keyboard as
    // a way past a blocked `+` would make the disabled button a decoration.
    if (!_canOrder && next > widget.quantity) next = widget.quantity;

    if (next != widget.quantity) widget.onChanged(next);
  }

  void _step(int delta) {
    if (delta > 0 && !_canOrder) return;
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
            // Wider while editing so a four-digit quantity is not typed into a
            // slot built for two.
            width: _editing ? 52 : 34,
            child: _editing
                ? TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(
                        signed: false, decimal: false),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _focusNode.unfocus(),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      if (widget.max != null)
                        LengthLimitingTextInputFormatter(
                            '${widget.max}'.length),
                    ],
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: context.rsp(14),
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                : GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _beginEdit,
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
                          color:
                              inCart ? scheme.primary : colors.textSecondary,
                          fontSize: context.rsp(14),
                          fontWeight: FontWeight.w800,
                        ),
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