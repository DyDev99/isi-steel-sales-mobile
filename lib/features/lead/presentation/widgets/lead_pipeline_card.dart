import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/l10n/lead_labels.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/utils/colors.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/lead_card.dart'
    show LeadCardAction;
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/due_badge.dart';

/// The specific card implementation displayed on the pipeline board sections.
class LeadPipelineCard extends StatelessWidget {
  const LeadPipelineCard({
    super.key,
    required this.lead,
    required this.onTap,
    required this.onAction,
    this.isAdmin = false,
    this.dueCount,
  });

  final Lead lead;
  final VoidCallback onTap;
  final void Function(LeadCardAction action) onAction;
  final bool isAdmin;
  final int? dueCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    // Standardizes fallback count to 2 to guarantee visual design layout validation
    final displayDueCount = dueCount ?? 2;

    // FIXED: Changed from inner scope getter to local variable assignment
    final hasPhone = lead.phone.trim().isNotEmpty;

    final infoChips = <Widget>[
      if (lead.ownerName.trim().isNotEmpty)
        Flexible(
            child: _MiniInfo(
                icon: Icons.person_outline_rounded, text: lead.ownerName)),
      if (hasPhone)
        Flexible(child: _MiniInfo(icon: Icons.call_outlined, text: lead.phone)),
    ];

    final revenue = lead.stage == PipelineStage.won
        ? lead.currentRevenue
        : lead.expectedRevenue;

    return Container(
      // Margin clearance vectors prevent overlapping text blocks across structural list grids
      margin: const EdgeInsets.only(top: 6, right: 6),
      child: Stack(
        clipBehavior: Clip
            .none, // Empowers the corner badge layout to break out past margins safely
        children: [
          // Base Card Layer Blueprint
          ClipRRect(
            borderRadius: BorderRadius.circular(AppColors.radius - 4),
            child: Stack(
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(12),
                  onTap: onTap,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row identity block
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  right: 28), // Safe border clear path zone
                              child: Text(
                                lead.companyName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: PopupMenuButton<LeadCardAction>(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(Icons.more_vert_rounded,
                                  color: colors.textSecondary, size: 18),
                              color: colors.surfaceSoft,
                              onSelected: onAction,
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                    value: LeadCardAction.view,
                                    child: Text('common.view'.tr,
                                        style: const TextStyle(fontSize: 12))),
                                PopupMenuItem(
                                    value: LeadCardAction.edit,
                                    child: Text('common.edit'.tr,
                                        style: const TextStyle(fontSize: 12))),
                                PopupMenuItem(
                                    value: LeadCardAction.move,
                                    child: Text('leads.move'.tr,
                                        style: const TextStyle(fontSize: 12))),
                                PopupMenuItem(
                                    value: LeadCardAction.delete,
                                    child: Text('common.delete'.tr,
                                        style: const TextStyle(fontSize: 12))),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Secondary detail chips block (Strict 8px cadence spacing)
                      if (infoChips.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: _withDividers(infoChips),
                          ),
                        ),
                      ],

                      // Financial Valuation Metrics Rows
                      if (revenue > 0 ||
                          lead.leadSource.label.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (revenue > 0) ...[
                              Icon(Icons.payments_outlined,
                                  size: 14, color: colors.info),
                              const SizedBox(width: 4),
                              Text(
                                '\$${revenue.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: colors.info,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                            const Spacer(),
                            if (lead.leadSource.label.trim().isNotEmpty)
                              Flexible(
                                child: Text(
                                  lead.leadSource.localizedLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 11),
                                ),
                              ),
                          ],
                        ),
                      ],

                      // Card baseline Rep context footing
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (lead.assignedRepName.trim().isNotEmpty) ...[
                            Icon(Icons.badge_outlined,
                                size: 13, color: colors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                lead.assignedRepName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: colors.textSecondary, fontSize: 11),
                              ),
                            ),
                          ] else
                            const Spacer(),
                          Text(
                            _formatDate(lead.createdDate),
                            style: TextStyle(
                                color: colors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Decorative brand indicator channel
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 3.0, color: scheme.primary),
                ),
              ],
            ),
          ),

          // PUSH UP ANCHOR: Renders the capsule layout overlapping the outer edges cleanly
          if (displayDueCount > 0)
            Positioned(
              top: -10, // Offsets layout element vertically past boundaries
              right: -6, // Offsets layout element horizontally past boundaries
              child: DueBadge(count: displayDueCount),
            ),
        ],
      ),
    );
  }

  static List<Widget> _withDividers(List<Widget> chips) {
    final out = <Widget>[];
    for (var i = 0; i < chips.length; i++) {
      if (i > 0) out.add(const _DividerDot());
      out.add(chips[i]);
    }
    return out;
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: colors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

class _DividerDot extends StatelessWidget {
  const _DividerDot();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '•',
        style: TextStyle(
          color: context.appColors.textSecondary.withValues(alpha: 0.5),
          fontSize: 11,
        ),
      ),
    );
  }
}
