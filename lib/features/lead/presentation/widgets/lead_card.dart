import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/onboarding_status.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/onboarding_status_badge.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/priority_badge.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/stage_badge.dart';

enum LeadCardAction { view, edit, delete, move, sendToHq }

/// A draggable customer card. Wrapped in [LongPressDraggable] so a normal
/// tap still opens the detail page and a short scroll still scrolls the
/// column — only a deliberate long-press starts a drag.
class LeadCard extends StatelessWidget {
  const LeadCard({
    super.key,
    required this.lead,
    required this.onTap,
    required this.onAction,
  });

  final Lead lead;
  final VoidCallback onTap;
  final void Function(LeadCardAction action) onAction;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<Lead>(
      data: lead,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 220, child: _CardBody(lead: lead)),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: _CardBody(lead: lead)),
      child: _CardBody(lead: lead, onTap: onTap, onAction: onAction),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({required this.lead, this.onTap, this.onAction});
  final Lead lead;
  final VoidCallback? onTap;
  final void Function(LeadCardAction action)? onAction;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Vibe.radius - 4), // Slimmer rounded borders
      child: Stack(
        children: [
          GlassCard(
            // Slashed padding heavily (14x10 -> 8x6) to compress layout tightly
            padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
            onTap: onTap,
            child: _content(),
          ),
          // Thinner profile accent boundary indicator line on the left edge
          Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 2.5, color: Vibe.violet)),
        ],
      ),
    );
  }

  Widget _content() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  lead.companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Vibe.text, fontSize: 12.0, fontWeight: FontWeight.w800), // Scaled text down to 12.0
                ),
              ),
              if (onAction != null)
                SizedBox(
                  height: 18,
                  width: 18,
                  child: PopupMenuButton<LeadCardAction>(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.more_vert_rounded, color: Vibe.muted, size: 14), // Scaled down icon size
                    color: Vibe.bgSoft,
                    onSelected: onAction,
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: LeadCardAction.view, child: Text('View', style: TextStyle(fontSize: 12))),
                      const PopupMenuItem(value: LeadCardAction.edit, child: Text('Edit', style: TextStyle(fontSize: 12))),
                      const PopupMenuItem(value: LeadCardAction.move, child: Text('Move', style: TextStyle(fontSize: 12))),
                      if (lead.stage == PipelineStage.won &&
                          lead.wonInfo?.onboardingStatus == OnboardingStatus.notSubmitted)
                        const PopupMenuItem(value: LeadCardAction.sendToHq, child: Text('Send to HQ', style: TextStyle(fontSize: 12))),
                      const PopupMenuItem(value: LeadCardAction.delete, child: Text('Delete', style: TextStyle(fontSize: 12))),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          
          // Consolidated layout real estate: packed key details into a single dense horizontal line
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: [
                _MiniInfo(icon: Icons.person_outline_rounded, text: lead.ownerName),
                const _DividerDot(),
                _MiniInfo(icon: Icons.call_outlined, text: lead.phone),
                const _DividerDot(),
                _MiniInfo(icon: Icons.place_outlined, text: lead.territory),
              ],
            ),
          ),
          const SizedBox(height: 3),
          
          Row(
            children: [
              Icon(Icons.payments_outlined, size: 11, color: Vibe.mint),
              const SizedBox(width: 3),
              Text(
                '\$${(lead.stage == PipelineStage.won ? lead.currentRevenue : lead.expectedRevenue).toStringAsFixed(0)}',
                style: const TextStyle(color: Vibe.mint, fontSize: 11, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                lead.leadSource.label,
                style: const TextStyle(color: Vibe.muted, fontSize: 9.5),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // Micro scale wrapping row for status badges
          Wrap(
            spacing: 3,
            runSpacing: 3,
            children: [
              PriorityBadge(priority: lead.priority),
              StageBadge(stage: lead.stage),
              if (lead.stage == PipelineStage.opportunities && lead.opportunityInfo != null)
                _SubStagePill(label: lead.opportunityInfo!.subStage.label),
              if (lead.stage == PipelineStage.won && lead.wonInfo != null)
                OnboardingStatusBadge(status: lead.wonInfo!.onboardingStatus),
            ],
          ),
          if (lead.stage == PipelineStage.won &&
              lead.wonInfo?.onboardingStatus == OnboardingStatus.notSubmitted &&
              onAction != null) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => onAction!(LeadCardAction.sendToHq),
                icon: const Icon(Icons.send_rounded, size: 11, color: Vibe.violet),
                label: const Text('Send to HQ', style: TextStyle(color: Vibe.violet, fontSize: 10)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Vibe.violet),
                  padding: const EdgeInsets.symmetric(vertical: 4), // Heavily condensed inside button height
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 3),
          
          Row(
            children: [
              const Icon(Icons.badge_outlined, size: 10, color: Vibe.muted),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  lead.assignedRepName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Vibe.muted, fontSize: 9.5),
                ),
              ),
              Text(
                _formatDate(lead.createdDate),
                style: const TextStyle(color: Vibe.muted, fontSize: 9.5),
              ),
            ],
          ),
        ],
      );
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _SubStagePill extends StatelessWidget {
  const _SubStagePill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Vibe.mint.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Vibe.mint.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: const TextStyle(color: Vibe.mint, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }
}

/// Ultra-compact horizontally efficient information unit
class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: Vibe.muted),
        const SizedBox(width: 2),
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Vibe.muted, fontSize: 10.5),
        ),
      ],
    );
  }
}

/// Simple micro divider element for inline horizontal arrays
class _DividerDot extends StatelessWidget {
  const _DividerDot();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text('•', style: TextStyle(color: Vibe.muted.withValues(alpha: 0.5), fontSize: 10)),
    );
  }
}