import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/auth_vibe.dart';

/// Builds the "Label *" rich-text used as an [InputDecoration.label] so the
/// asterisk can be styled in [Vibe.danger] while the rest of the label stays
/// [Vibe.muted]. Shared by [VibeField] and any other Vibe-styled input
/// (e.g. the phone half of `IdentifierField`) so required-field styling
/// stays consistent across the form.
Widget vibeFieldLabel(String label, {bool required = false}) {
  if (!required) return Text(label, style: const TextStyle(color: Vibe.muted));
  return RichText(
    text: TextSpan(
      style: const TextStyle(color: Vibe.muted, fontSize: 16),
      children: [
        TextSpan(text: label),
        const TextSpan(
          text: ' *',
          style: TextStyle(color: Vibe.danger, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

/// Shared enabled/focused/error border builder for Vibe-styled inputs.
OutlineInputBorder vibeFieldBorder(Color c, [double w = 1]) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(Vibe.radius),
      borderSide: BorderSide(color: c, width: w),
    );

/// Shared base decoration (fill, borders, padding) for Vibe-styled inputs,
/// so fields like the phone input in `IdentifierField` render identically
/// to [VibeField] without duplicating the styling.
InputDecoration vibeFieldDecoration({
  required String label,
  bool required = false,
  IconData? icon,
  Widget? suffix,
}) {
  return InputDecoration(
    label: vibeFieldLabel(label, required: required),
    prefixIcon: icon == null ? null : Icon(icon, color: Vibe.muted, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: Vibe.surfaceStrong,
    enabledBorder: vibeFieldBorder(Vibe.stroke),
    focusedBorder: vibeFieldBorder(Vibe.pink, 1.6),
    errorBorder: vibeFieldBorder(Vibe.danger),
    focusedErrorBorder: vibeFieldBorder(Vibe.danger, 1.6),
    errorStyle: const TextStyle(color: Vibe.danger),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
  );
}

class VibeField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;

  /// Shows a red asterisk next to the label when true.
  final bool required;

  /// Optional key for the *inner* TextFormField's FormFieldState — separate
  /// from this widget's own [key] — so a parent composite field (like
  /// `IdentifierField`) can call `.validate()` on it directly without going
  /// through an ancestor `Form`.
  final Key? formFieldKey;

  const VibeField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.suffix,
    this.onSubmitted,
    this.validator,
    this.required = false,
    this.formFieldKey,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: formFieldKey,
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: const TextStyle(color: Vibe.text, fontSize: 15),
      cursorColor: Vibe.pink,
      decoration: vibeFieldDecoration(
        label: label,
        required: required,
        icon: icon,
        suffix: suffix,
      ),
    );
  }
}