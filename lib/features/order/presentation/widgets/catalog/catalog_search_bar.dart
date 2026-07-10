import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';

/// Multi-modal catalog search header: type, speak 🎤, scan 📷 or upload a photo.
/// The four discovery inputs all feed the same catalog query pipeline; the
/// [controller] lets voice/image results be echoed back into the field.
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
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Vibe.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Vibe.stroke),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: Vibe.muted, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onSearchChanged,
                    textInputAction: TextInputAction.search,
                    onSubmitted: onSearchChanged,
                    style: const TextStyle(color: Vibe.text, fontSize: 13.5),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'orders.catalog.search_hint'.tr,
                      hintStyle:
                          const TextStyle(color: Vibe.muted, fontSize: 13.5),
                    ),
                  ),
                ),
                _InlineIcon(
                    icon: Icons.mic_none_rounded,
                    tooltip: 'Voice search',
                    onTap: onVoiceTap),
                _InlineIcon(
                    icon: Icons.photo_camera_back_outlined,
                    tooltip: 'Search by photo',
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
          child: Icon(icon, color: Vibe.muted, size: 20),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color:
              highlighted ? Vibe.violet.withValues(alpha: 0.18) : Vibe.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: highlighted ? Vibe.violet : Vibe.stroke),
        ),
        child:
            Icon(icon, color: highlighted ? Vibe.violet : Vibe.text, size: 20),
      ),
    );
  }
}
