import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

class CatalogSearchBar extends StatelessWidget {
  const CatalogSearchBar({
    super.key,
    required this.onSearchChanged,
    required this.onFilterTap,
    required this.hasActiveFilters,
    required this.onVoiceTap,
    required this.onImageTap,
    this.controller,
  });

  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterTap;
  final bool hasActiveFilters;
  final VoidCallback onVoiceTap;
  final VoidCallback onImageTap;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final appColors = context.appColors;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: appColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded,
                    color: scheme.onSurface.withValues(alpha: 0.5), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onSearchChanged,
                    textInputAction: TextInputAction.search,
                    onSubmitted: onSearchChanged,
                    style: TextStyle(color: scheme.onSurface, fontSize: 13.5),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'orders.catalog.search_hint'.tr,
                      hintStyle: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.4),
                          fontSize: 13.5),
                    ),
                  ),
                ),
                _InlineIcon(
                    icon: Icons.mic_none_rounded,
                    tooltip: 'orders.voice.tooltip'.tr,
                    onTap: onVoiceTap),
                _InlineIcon(
                    icon: Icons.photo_camera_back_outlined,
                    tooltip: 'orders.catalog.search_by_photo'.tr,
                    onTap: onImageTap),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _SquareButton(
            icon: Icons.tune_rounded,
            highlighted: hasActiveFilters,
            onTap: onFilterTap),
      ],
    );
  }
}

class _InlineIcon extends StatelessWidget {
  const _InlineIcon(
      {required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Tooltip(
          message: tooltip,
          child: Icon(icon,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
              size: 20),
        ),
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton(
      {required this.icon, required this.onTap, this.highlighted = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: highlighted
              ? scheme.primary.withValues(alpha: 0.15)
              : scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: highlighted ? scheme.primary : context.appColors.border),
        ),
        child: Icon(icon,
            color: highlighted ? scheme.primary : scheme.onSurface, size: 20),
      ),
    );
  }
}
