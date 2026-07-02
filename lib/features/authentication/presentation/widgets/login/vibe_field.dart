import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/auth_vibe.dart';

class VibeField extends StatelessWidget {
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
  });

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

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(Vibe.radius),
          borderSide: BorderSide(color: c, width: w),
        );

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: const TextStyle(color: Vibe.text, fontSize: 15),
      cursorColor: Vibe.pink,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Vibe.muted),
        prefixIcon: Icon(icon, color: Vibe.muted, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Vibe.surfaceStrong,
        enabledBorder: border(Vibe.stroke),
        focusedBorder: border(Vibe.pink, 1.6),
        errorBorder: border(Vibe.danger),
        focusedErrorBorder: border(Vibe.danger, 1.6),
        errorStyle: const TextStyle(color: Vibe.danger),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}
