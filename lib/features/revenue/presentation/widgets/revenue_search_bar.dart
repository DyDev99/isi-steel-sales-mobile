import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

class RevenueSearchBar extends StatelessWidget {
  const RevenueSearchBar(
      {super.key, required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: colors.textPrimary, fontSize: 14), // Replaced Vibe.text
      decoration: InputDecoration(
        hintText: 'revenue.search_hint'.tr,
        hintStyle: TextStyle(color: colors.textSecondary, fontSize: 14), // Replaced Vibe.muted
        prefixIcon:
            Icon(Icons.search_rounded, color: colors.textSecondary, size: 20), // Replaced Vibe.muted
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close_rounded,
                    color: colors.textSecondary, size: 18), // Replaced Vibe.muted
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        filled: true,
        fillColor: colors.surfaceSoft, // Replaced Vibe.bgSoft
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border), // Replaced Vibe.stroke
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border), // Replaced Vibe.stroke
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.accentPurple), // Replaced Vibe.violet
        ),
      ),
    );
  }
}