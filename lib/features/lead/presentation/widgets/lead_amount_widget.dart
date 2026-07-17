import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/lead_stage_visuals.dart';

/// Renders a monetary figure on a pipeline card — the deal's value.
///
/// [compact] (`$50k`) is the card default because the card is ~half the screen
/// wide and a full `$50,000.00` would either wrap or ellipsise into a lie.
/// Board headers pass `compact: false` for the exact figure, which the design
/// shows in full (`$15,000 total`).
///
/// The accessible label always announces the **full** amount regardless of the
/// visual form: a screen-reader user must not hear "fifty k" when the value is
/// $50,400.
class LeadAmountWidget extends StatelessWidget {
  const LeadAmountWidget({
    super.key,
    required this.value,
    this.color,
    this.compact = true,
    this.fontSize = 13,
    this.fontWeight = FontWeight.w700,
  });

  final double value;
  final Color? color;
  final bool compact;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final text = compact ? formatCompactCurrency(value) : formatCurrency(value);

    return Semantics(
      label: formatCurrency(value),
      excludeSemantics: true,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color ?? context.appColors.textPrimary,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}
