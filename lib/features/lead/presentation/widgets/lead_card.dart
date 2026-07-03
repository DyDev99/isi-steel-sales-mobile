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
        child: SizedBox(width: 260, child: _CardBody(lead: lead)),
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
      borderRadius: BorderRadius.circular(Vibe.radius),
      child: Stack(
        children: [
          GlassCard(
            padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
            onTap: onTap,
            child: _content(),
          ),
          // Blue accent line on the left edge, per the CRM card spec.
          Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 4, color: Vibe.violet)),
        ],
      ),
    );
  }

  Widget _content() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  lead.companyName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Vibe.text, fontSize: 14.5, fontWeight: FontWeight.w800),
                ),
              ),
              if (onAction != null)
                PopupMenuButton<LeadCardAction>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert_rounded, color: Vibe.muted, size: 18),
                  color: Vibe.bgSoft,
                  onSelected: onAction,
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: LeadCardAction.view, child: Text('View')),
                    const PopupMenuItem(value: LeadCardAction.edit, child: Text('Edit')),
                    const PopupMenuItem(value: LeadCardAction.move, child: Text('Move')),
                    if (lead.stage == PipelineStage.won &&
                        lead.wonInfo?.onboardingStatus == OnboardingStatus.notSubmitted)
                      const PopupMenuItem(value: LeadCardAction.sendToHq, child: Text('Send to HQ')),
                    const PopupMenuItem(value: LeadCardAction.delete, child: Text('Delete')),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          _InfoLine(icon: Icons.person_outline_rounded, text: lead.ownerName),
          _InfoLine(icon: Icons.call_outlined, text: lead.phone),
          _InfoLine(icon: Icons.place_outlined, text: lead.territory),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.payments_outlined, size: 13, color: Vibe.mint),
              const SizedBox(width: 4),
              Text(
                '\$${(lead.stage == PipelineStage.won ? lead.currentRevenue : lead.expectedRevenue).toStringAsFixed(0)}',
                style: const TextStyle(color: Vibe.mint, fontSize: 13, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                lead.leadSource.label,
                style: const TextStyle(color: Vibe.muted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
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
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => onAction!(LeadCardAction.sendToHq),
                icon: const Icon(Icons.send_rounded, size: 15, color: Vibe.violet),
                label: const Text('Send to HQ', style: TextStyle(color: Vibe.violet, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Vibe.violet),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.badge_outlined, size: 12, color: Vibe.muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  lead.assignedRepName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Vibe.muted, fontSize: 11),
                ),
              ),
              Text(
                _formatDate(lead.createdDate),
                style: const TextStyle(color: Vibe.muted, fontSize: 11),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Vibe.mint.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Vibe.mint.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: const TextStyle(color: Vibe.mint, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Vibe.muted),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Vibe.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
