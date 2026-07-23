import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/l10n/lead_labels.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/lead_amount_widget.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/lead_stage_visuals.dart';

/// Coloured strip at the top of a board section: dot · stage name · count ·
/// total value — the reference's `● Lead    28    $15,000 total`.
///
/// [count] and [totalValue] are passed in already computed from live state
/// (see `leadsTotalValue`); this widget never derives business numbers itself.
class LeadBoardHeader extends StatelessWidget {
  const LeadBoardHeader({
    super.key,
    required this.stage,
    required this.count,
    required this.totalValue,
  });

  final PipelineStage stage;
  final int count;
  final double totalValue;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = stage.accent(context);

    return Semantics(
      header: true,
      label: 'leads.board_summary'.trParams({
        'stage': stage.localizedLabel,
        'count': count,
        'total': formatCurrency(totalValue),
      }),
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: stage.headerTint(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            // Flexible, not Expanded: the name takes only what it needs so the
            // count sits next to it as the design shows, and ellipsises rather
            // than pushing the total off-screen on a narrow phone.
            Flexible(
              child: Text(
                stage.localizedLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$count',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            LeadAmountWidget(
              value: totalValue,
              color: accent,
              compact: false,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
            const SizedBox(width: 4),
            Text(
              'total',
              style: TextStyle(color: accent, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
