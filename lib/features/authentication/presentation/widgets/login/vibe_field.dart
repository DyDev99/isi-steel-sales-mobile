import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/utils/colors.dart';

Widget vibeFieldLabel(
  BuildContext context,
  String label, {
  bool required = false,
}) {
  final muted = context.appColors.textSecondary;
  if (!required) {
    return Text(label, style: TextStyle(color: muted, fontSize: context.rsp(15)));
  }
  return RichText(
    text: TextSpan(
      style: TextStyle(color: muted, fontSize: context.rsp(15)),
      children: [
        TextSpan(text: label),
        TextSpan(
          text: ' *',
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

OutlineInputBorder vibeFieldBorder(BuildContext context, Color c, [double w = 1]) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(context.rr(AppColors.radius)),
      borderSide: BorderSide(color: c, width: w),
    );

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
        : Icon(icon, color: colors.textSecondary, size: context.rr(20)),
    suffixIcon: suffix,
    filled: true,
    fillColor: colors.surfaceStrong,
    enabledBorder: vibeFieldBorder(context, colors.border),
    focusedBorder: vibeFieldBorder(context, scheme.secondary, 1.6),
    errorBorder: vibeFieldBorder(context, scheme.error),
    focusedErrorBorder: vibeFieldBorder(context, scheme.error, 1.6),
    errorStyle: TextStyle(color: scheme.error, fontSize: context.rsp(12)),
    contentPadding: EdgeInsets.symmetric(
      horizontal: context.rw(16),
      vertical: context.rh(18),
    ),
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
  final bool required;
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
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: context.rsp(15),
      ),
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