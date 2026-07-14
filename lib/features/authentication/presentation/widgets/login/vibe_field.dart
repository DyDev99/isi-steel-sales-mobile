import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/utils/colors.dart';

/// Builds the "Label *" rich-text used as an [InputDecoration.label] so the
/// asterisk can be styled in the error color while the rest of the label stays
/// muted. Shared by [VibeField] and any other themed input (e.g. the phone
/// half of `IdentifierField`) so required-field styling stays consistent
/// across the form. Takes [context] so the colors track the active theme.
Widget vibeFieldLabel(BuildContext context, String label,
    {bool required = false}) {
  final muted = context.appColors.textSecondary;
  if (!required) return Text(label, style: TextStyle(color: muted));
  return RichText(
    text: TextSpan(
      style: TextStyle(color: muted, fontSize: 16),
      children: [
        TextSpan(text: label),
        TextSpan(
          text: ' *',
          style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

/// Shared enabled/focused/error border builder for themed inputs.
OutlineInputBorder vibeFieldBorder(Color c, [double w = 1]) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppColors.radius),
      borderSide: BorderSide(color: c, width: w),
    );

/// Shared base decoration (fill, borders, padding) for themed inputs, so
/// fields like the phone input in `IdentifierField` render identically to
/// [VibeField] without duplicating the styling.
InputDecoration vibeFieldDecoration(
  BuildContext context, {
  required String label,
  bool required = false,
  IconData? icon,
  Widget? suffix,
}) {
  final scheme = Theme.of(context).colorScheme;
  final colors = context.appColors;
  return InputDecoration(
    label: vibeFieldLabel(context, label, required: required),
    prefixIcon: icon == null
        ? null
        : Icon(icon, color: colors.textSecondary, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: colors.surfaceStrong,
    enabledBorder: vibeFieldBorder(colors.border),
    focusedBorder: vibeFieldBorder(scheme.secondary, 1.6),
    errorBorder: vibeFieldBorder(scheme.error),
    focusedErrorBorder: vibeFieldBorder(scheme.error, 1.6),
    errorStyle: TextStyle(color: scheme.error),
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
      style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface, fontSize: 15),
      cursorColor: Theme.of(context).colorScheme.secondary,
      decoration: vibeFieldDecoration(
        context,
        label: label,
        required: required,
        icon: icon,
        suffix: suffix,
      ),
    );
  }
}