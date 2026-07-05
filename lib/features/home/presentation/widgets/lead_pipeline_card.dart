import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/home/presentation/widgets/dashboard_kpi_card.dart';

/// Lead pipeline summary card. Headline = total pipeline (leads +
/// opportunities + won), broken down by stage in the bar/legend. The badge
/// calls out fresh leads specifically, since those are the ones that need
/// someone to actually follow up.
class LeadPipelineCard extends StatelessWidget {
  const LeadPipelineCard({
    super.key,
    required this.leadCount,
    required this.opportunityCount,
    required this.wonCount,
    this.leadLabel,
    this.opportunityLabel,
    this.wonLabel,
    this.title,
    this.icon = Icons.person_add_alt_1_rounded,
    this.onTap,
  });

  final int leadCount;
  final int opportunityCount;
  final int wonCount;
  final String? leadLabel;
  final String? opportunityLabel;
  final String? wonLabel;
  final String? title;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final int totalPipeline = leadCount + opportunityCount + wonCount;

    return DashboardKpiCard(
      title: title ?? 'home.quick_access.leads'.tr,
      icon: icon,
      iconColor: Vibe.violet,
      headline: '$totalPipeline',
      headlineCaption: 'home.quick_access.total_pipeline'.tr,
      badge: leadCount > 0 ? KpiBadge(label: '$leadCount ${'home.quick_access.new'.tr}', color: Vibe.violet) : null,
      segments: [
        KpiSegment(label: wonLabel ?? 'home.quick_access.won_deals'.tr, value: wonCount, color: Vibe.success),
        KpiSegment(label: opportunityLabel ?? 'home.quick_access.opportunities'.tr, value: opportunityCount, color: Vibe.amber),
        KpiSegment(label: leadLabel ?? 'home.quick_access.leads'.tr, value: leadCount, color: Vibe.violet),
      ],
      onTap: onTap,
    );
  }
}