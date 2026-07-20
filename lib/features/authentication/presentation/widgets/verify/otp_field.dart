import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/utils/colors.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';

/// A row of single-digit boxes for entering an OTP / verification code,
/// styled to match [VibeField]. Not a [FormField] itself (same reasoning as
/// `IdentifierField`) — grab a `GlobalKey<OtpFieldState>`, read `.value`,
/// and call `.validate()` before submitting.
class OtpField extends StatefulWidget {
  const OtpField({
    super.key,
    this.length = 6,
    this.autofocus = true,
    this.onCompleted,
  });

  final int length;
  final bool autofocus;

  /// Fired the moment every box has a digit — handy for auto-submitting.
  final ValueChanged<String>? onCompleted;

  @override
  State<OtpField> createState() => OtpFieldState();
}

class OtpFieldState extends State<OtpField> {
  late final List<TextEditingController> _controllers =
      List.generate(widget.length, (_) => TextEditingController());
  late final List<FocusNode> _nodes =
      List.generate(widget.length, (_) => FocusNode());

  String? _error;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  /// The full code currently entered (may be shorter than [length]).
  String get value => _controllers.map((c) => c.text).join();

  /// Validates that every box is filled. Call alongside the surrounding
  /// `Form`'s own `validate()` (if any) before submitting.
  bool validate() {
    final complete = value.length == widget.length;
    setState(() => _error = complete ? null : 'auth.otp_incomplete'.tr);
    return complete;
  }

  /// Clears every box and refocuses the first one — call this after a
  /// failed verification attempt.
  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    setState(() => _error = null);
    if (_nodes.isNotEmpty) _nodes.first.requestFocus();
  }

  void _handleChange(int index, String text) {
    if (text.length > 1) {
      // Pasted (or SMS-autofilled) content landed in one box — spread the
      // digits across this box and the following ones.
      final digits = text.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < digits.length && index + i < widget.length; i++) {
        _controllers[index + i].text = digits[i];
      }
      final next = (index + digits.length).clamp(0, widget.length - 1);
      _nodes[next].requestFocus();
    } else if (text.isNotEmpty) {
      if (index + 1 < widget.length) {
        _nodes[index + 1].requestFocus();
      } else {
        _nodes[index].unfocus();
      }
    }

    if (_error != null) setState(() => _error = null);
    if (value.length == widget.length) widget.onCompleted?.call(value);
  }

  void _handleBackspace(int index) {
    if (index > 0) {
      _nodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < widget.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _box(i)),
            ],
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _box(int index) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radius),
          borderSide: BorderSide(color: c, width: w),
        );

    final hasError = _error != null;

    return SizedBox(
      height: 54,
      child: Focus(
        // Wrapping (rather than owning) focus lets key events bubble up
        // from the TextField's own FocusNode to this ancestor, so we can
        // intercept backspace-on-empty without stealing focus ourselves.
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              _controllers[index].text.isEmpty) {
            _handleBackspace(index);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: _controllers[index],
          focusNode: _nodes[index],
          autofocus: widget.autofocus && index == 0,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          textInputAction: index == widget.length - 1
              ? TextInputAction.done
              : TextInputAction.next,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          // SMS autofill on Android typically targets the first box.
          autofillHints: index == 0 ? const [AutofillHints.oneTimeCode] : null,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          cursorColor: scheme.secondary,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: colors.surfaceStrong,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            enabledBorder: border(hasError ? scheme.error : colors.border),
            focusedBorder:
                border(hasError ? scheme.error : scheme.secondary, 1.6),
          ),
          onChanged: (text) => _handleChange(index, text),
        ),
      ),
    );
  }
}
