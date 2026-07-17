import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';

/// Per-stage colour + value helpers shared by the pipeline board widgets.
///
/// ## Why the design's hex palette isn't hardcoded here
///
/// The reference specifies literal colours (Lead `#3B82F6`, Opportunity
/// `#8B5CF6`, Won `#059669`, with tinted headers). Those are **light-mode**
/// values: baking them in would make the board unreadable in dark mode and
/// would violate the project rule that all colour comes from
/// `theme_extensions.dart`.
///
/// Instead each stage resolves to the theme token that already carries the
/// reference hue, so light mode matches the design and dark mode follows the
/// palette automatically:
///
/// | Stage | Reference | Token |
/// |---|---|---|
/// | Lead | blue `#3B82F6` | `ColorScheme.primary` |
/// | Opportunity | purple `#8B5CF6` | `AppThemeColors.accentPurple` |
/// | Won | green `#059669` | `AppThemeColors.success` |
///
/// Header/section tints are derived from the accent with alpha rather than
/// declared separately, so a theme change can never leave a header and its
/// accent disagreeing.
extension PipelineStageVisuals on PipelineStage {
  Color accent(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return switch (this) {
      PipelineStage.leads => scheme.primary,
      PipelineStage.opportunities => colors.accentPurple,
      PipelineStage.won => colors.success,
    };
  }

  /// Tinted background behind a whole board section (the reference's
  /// `#E8F1FF` / `#F1E8FF` / `#E6F7EF`).
  Color sectionTint(BuildContext context) =>
      accent(context).withValues(alpha: 0.06);

  /// Slightly stronger tint for the section header strip.
  Color headerTint(BuildContext context) =>
      accent(context).withValues(alpha: 0.12);
}

/// The monetary value a lead contributes **to the stage it is in**.
///
/// Deliberately stage-aware rather than one flat field: a lead's worth is an
/// estimate, an opportunity's is the negotiated figure, and a won deal's is the
/// signed amount. Summing `expectedRevenue` across every stage would report an
/// optimistic pipeline total that contradicts the Won board's own numbers.
///
/// Falls back to [Lead.expectedRevenue] when the stage-specific record is absent
/// (a lead moved by an older build), so a board total is never silently zero.
double leadStageValue(Lead lead) => switch (lead.stage) {
      PipelineStage.leads => lead.expectedRevenue,
      PipelineStage.opportunities =>
        lead.opportunityInfo?.estimatedValue ?? lead.expectedRevenue,
      PipelineStage.won => lead.wonInfo?.finalValue ?? lead.expectedRevenue,
    };

/// Sum of [leadStageValue] across a board — the "$15,000 total" in the header.
/// Computed from live state, never stored.
double leadsTotalValue(List<Lead> leads) =>
    leads.fold<double>(0, (sum, lead) => sum + leadStageValue(lead));

/// Compact money for tight card rows: `$50k`, `$1.2M`.
String formatCompactCurrency(double value) =>
    NumberFormat.compactSimpleCurrency(decimalDigits: value >= 1000 ? 1 : 0)
        .format(value);

/// Full money for board headers: `$15,000`.
String formatCurrency(double value) =>
    NumberFormat.simpleCurrency(decimalDigits: 0).format(value);
