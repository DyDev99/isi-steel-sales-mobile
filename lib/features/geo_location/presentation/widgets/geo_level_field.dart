import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_text_context.dart';
import 'package:isi_steel_sales_mobile/features/geo_location/domain/entities/geo_unit.dart';
import 'package:isi_steel_sales_mobile/features/geo_location/presentation/bloc/geo_location_bloc.dart';

/// One level's field: a label, a tappable value, and whatever state it is in.
///
/// The five UI states of §11 are rendered here and nowhere else. The four
/// levels differ only in their label and their locked hint, both of which are
/// data — so `ProvinceSelector`, `DistrictSelector`, `CommuneSelector` and
/// `VillageSelector` would be four copies of this file differing by a string.
/// The named constructors give call sites the same readability without the
/// duplication.
class GeoLevelField extends StatelessWidget {
  const GeoLevelField({
    super.key,
    required this.level,
    required this.levelState,
    required this.selected,
    required this.onTap,
    this.errorText,
    this.isRequired = false,
  });

  final GeoLevel level;
  final GeoLevelState levelState;
  final GeoUnit? selected;
  final VoidCallback onTap;
  final String? errorText;
  final bool isRequired;

  bool get _isLocked => levelState.status == GeoLevelStatus.locked;
  bool get _isLoading => levelState.status == GeoLevelStatus.loading;
  bool get _hasFailed => levelState.status == GeoLevelStatus.failure;

  /// Disabled while locked or loading. Not while failed — a failed field must
  /// stay tappable, because the retry lives inside the sheet it opens.
  bool get _isEnabled => !_isLocked && !_isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: RichText(
            text: TextSpan(
              text: level.labelKey.tr,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              children: [
                if (isRequired)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
              ],
            ),
          ),
        ),
        Semantics(
          button: true,
          enabled: _isEnabled,
          // Spoken as "District, Chamkar Mon, button" rather than as a bare
          // "button" — the label is a sibling widget, so it is not announced
          // with the value unless it is repeated here.
          label: level.labelKey.tr,
          value: _valueLabel(context),
          child: InkWell(
            onTap: _isEnabled ? onTap : null,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              isEmpty: false,
              decoration: InputDecoration(
                enabled: _isEnabled,
                filled: true,
                fillColor: _isLocked
                    ? theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.4)
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.15),
                errorText: errorText,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _suffix(theme),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _valueLabel(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: selected != null
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: selected != null
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_hasFailed && !hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'geo.error.load_failed'.tr,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
      ],
    );
  }

  Widget _suffix(ThemeData theme) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_hasFailed) {
      return Icon(Icons.error_outline, color: theme.colorScheme.error);
    }
    if (selected != null) {
      return Icon(Icons.check_circle, color: theme.colorScheme.primary);
    }
    return Icon(
      Icons.keyboard_arrow_down,
      color: _isLocked
          ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
          : theme.colorScheme.onSurfaceVariant,
    );
  }

  /// The value, or the state-appropriate placeholder. A locked field says which
  /// level to fill in first rather than a generic "select" — that hint is the
  /// only thing telling a rep why the field will not open.
  String _valueLabel(BuildContext context) {
    if (selected != null) return context.localized(selected!.name);
    if (_isLoading) return 'geo.loading'.tr;
    if (_isLocked) {
      return switch (level) {
        GeoLevel.province => 'geo.locked.province',
        GeoLevel.district => 'geo.locked.district',
        GeoLevel.commune => 'geo.locked.commune',
        GeoLevel.village => 'geo.locked.village',
      }
          .tr;
    }
    return switch (level) {
      GeoLevel.province => 'geo.hint.province',
      GeoLevel.district => 'geo.hint.district',
      GeoLevel.commune => 'geo.hint.commune',
      GeoLevel.village => 'geo.hint.village',
    }
        .tr;
  }
}
