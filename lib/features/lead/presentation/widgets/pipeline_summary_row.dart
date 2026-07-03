import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/widgets/metric_card.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_summary.dart';

/// Dashboard summary strip at the top of the pipeline board. Reuses the
/// existing [MetricCard] from the home feature instead of a bespoke widget.
class PipelineSummaryRow extends StatelessWidget {
  const PipelineSummaryRow({super.key, required this.summary});
  final PipelineSummary summary;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      MetricCard(
        label: 'Total Leads',
        value: '${summary.totalLeads}',
        icon: Icons.person_add_alt_1_rounded,
        accent: Vibe.violet,
      ),
      MetricCard(
        label: 'Opportunities',
        value: '${summary.totalOpportunities}',
        icon: Icons.trending_up_rounded,
        accent: Vibe.amber,
      ),
      MetricCard(
        label: 'Won Customers',
        value: '${summary.wonCustomers}',
        icon: Icons.emoji_events_rounded,
        accent: Vibe.success,
      ),
      MetricCard(
        label: 'Potential Revenue',
        value: '\$${_compact(summary.potentialRevenue)}',
        icon: Icons.trending_up_rounded,
        accent: Vibe.mint,
      ),
      MetricCard(
        label: 'Won Revenue',
        value: '\$${_compact(summary.wonRevenue)}',
        icon: Icons.payments_rounded,
        accent: Vibe.pink,
      ),
      MetricCard(
        label: 'Conversion Rate',
        value: '${(summary.conversionRate * 100).toStringAsFixed(1)}%',
        icon: Icons.donut_large_rounded,
        accent: Vibe.violet,
      ),
    ];

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: metrics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) => SizedBox(width: 150, child: metrics[i]),
      ),
    );
  }

  static String _compact(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }
}
