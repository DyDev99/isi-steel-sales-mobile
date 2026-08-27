import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';

/// The postal code, derived where possible and typeable where not.
///
/// ## Why it is not simply read-only
///
/// The spec asks for a locked field, and for 1,547 of 1,646 communes that is
/// exactly what this renders. The other 99 have no code in the postal source,
/// and a permanently locked field would leave a rep with a required, empty,
/// uneditable input and no way forward. So the lock follows the data: derived →
/// locked with a lock icon; underived → an ordinary six-digit input with a hint
/// explaining why they are being asked.
class PostalCodeField extends StatefulWidget {
  const PostalCodeField({
    super.key,
    required this.value,
    required this.isDerived,
    required this.isEditable,
    required this.onChanged,
    this.errorText,
    this.isRequired = true,
  });

  /// The effective code — the commune's, or what the rep typed.
  final String? value;

  /// True when [value] came from the gazetteer.
  final bool isDerived;

  /// True when a commune is selected but carries no code.
  final bool isEditable;

  final ValueChanged<String> onChanged;
  final String? errorText;
  final bool isRequired;

  @override
  State<PostalCodeField> createState() => _PostalCodeFieldState();
}

class _PostalCodeFieldState extends State<PostalCodeField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value ?? '');

  @override
  void didUpdateWidget(PostalCodeField old) {
    super.didUpdateWidget(old);
    // Only push a derived value into the controller. Overwriting on every
    // rebuild would fight the rep's cursor while they type the manual case,
    // and the bloc already holds what they typed.
    final incoming = widget.value ?? '';
    if (widget.isDerived && _controller.text != incoming) {
      _controller.text = incoming;
    }
    // A commune change that clears the code has to clear the box too, or the
    // previous commune's code stays visible under the new selection (§8).
    if (!widget.isDerived && incoming.isEmpty && old.value != null) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: RichText(
            text: TextSpan(
              text: 'geo.postal_code'.tr,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              children: [
                if (widget.isRequired)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
              ],
            ),
          ),
        ),
        TextField(
          controller: _controller,
          readOnly: !widget.isEditable,
          enabled: widget.isEditable || widget.isDerived,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            // Cambodia Post's codes are six digits. The legacy five-digit
            // Phnom Penh codes the app used to hardcode are a different,
            // superseded scheme — see docs/features/geo-location/api.md.
            LengthLimitingTextInputFormatter(6),
          ],
          onChanged: widget.onChanged,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: widget.isDerived
                ? theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.4)
                : theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.15),
            hintText: widget.isEditable ? 'geo.postal_hint'.tr : '—',
            errorText: widget.errorText,
            helperText:
                widget.isEditable ? 'geo.postal_manual_notice'.tr : null,
            helperMaxLines: 2,
            suffixIcon: Icon(
              widget.isDerived ? Icons.lock_outline : Icons.edit_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
