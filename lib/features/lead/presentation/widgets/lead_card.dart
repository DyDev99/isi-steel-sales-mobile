import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/onboarding_status.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/due_badge.dart';

enum LeadCardAction { view, edit, delete, move, sendToHq }

/// A draggable customer card. Wrapped in [LongPressDraggable] so a normal
/// tap still opens the detail page and a short scroll still scrolls the
/// column — only a deliberate long-press starts a drag.
///
/// The card intentionally shows only actionable business information (shop
/// name, contact, value, follow-up affordances). Priority and pipeline-status
/// badges live in the data layer and on the detail screen, not here — the
/// column header already conveys the stage, so repeating it on every card is
/// noise.
class LeadCard extends StatelessWidget {
  const LeadCard({
    super.key,
    required this.lead,
    required this.onTap,
    required this.onAction,
    this.dueCount,
  });

  final Lead lead;
  final VoidCallback onTap;
  final void Function(LeadCardAction action) onAction;

  /// Number of pending actions for this customer (follow-up / visit /
  /// quotation waiting, etc.). Drives the compact "N Due" badge. When `null`
  /// or `<= 0` the badge hides itself — no data source is wired yet, so today
  /// this stays null and the badge simply doesn't render.
  final int? dueCount;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<Lead>(
      data: lead,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 220, child: _CardBody(lead: lead)),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: _CardBody(lead: lead)),
      child: _CardBody(
        lead: lead,
        onTap: onTap,
        onAction: onAction,
        dueCount: dueCount,
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.lead,
    this.onTap,
    this.onAction,
    this.dueCount,
  });

  final Lead lead;
  final VoidCallback? onTap;
  final void Function(LeadCardAction action)? onAction;
  final int? dueCount;

  bool get _hasPhone => lead.phone.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(Vibe.radius - 4), // Slimmer rounded borders
      child: Stack(
        children: [
          GlassCard(
            // Roomy padding so every item has comfortable breathing space.
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
            onTap: onTap,
            child: _content(),
          ),
          // Thinner profile accent boundary indicator line on the left edge
          Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 2.5, color: Vibe.violet)),
        ],
      ),
    );
  }

  Widget _content() {
    // Every optional row is built conditionally so empty fields collapse the
    // card height automatically instead of leaving blank gaps.
    final infoChips = <Widget>[
      if (lead.ownerName.trim().isNotEmpty)
        _MiniInfo(icon: Icons.person_outline_rounded, text: lead.ownerName),
      if (_hasPhone) _MiniInfo(icon: Icons.call_outlined, text: lead.phone),
      if (lead.territory.trim().isNotEmpty)
        _MiniInfo(icon: Icons.place_outlined, text: lead.territory),
    ];

    final revenue = lead.stage == PipelineStage.won
        ? lead.currentRevenue
        : lead.expectedRevenue;
    final showSendToHq = lead.stage == PipelineStage.won &&
        lead.wonInfo?.onboardingStatus == OnboardingStatus.notSubmitted &&
        onAction != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: shop / depot name + right-aligned "N Due" badge + menu.
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                lead.companyName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Vibe.text,
                    fontSize: 15.0,
                    fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 6),
            DueBadge(count: dueCount),
            if (onAction != null) ...[
              const SizedBox(width: 4),
              SizedBox(
                height: 22,
                width: 22,
                child: PopupMenuButton<LeadCardAction>(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.more_vert_rounded,
                      color: Vibe.muted, size: 18),
                  color: Vibe.bgSoft,
                  onSelected: onAction,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: LeadCardAction.view,
                        child: Text('View', style: TextStyle(fontSize: 12))),
                    const PopupMenuItem(
                        value: LeadCardAction.edit,
                        child: Text('Edit', style: TextStyle(fontSize: 12))),
                    const PopupMenuItem(
                        value: LeadCardAction.move,
                        child: Text('Move', style: TextStyle(fontSize: 12))),
                    if (lead.stage == PipelineStage.won &&
                        lead.wonInfo?.onboardingStatus ==
                            OnboardingStatus.notSubmitted)
                      const PopupMenuItem(
                          value: LeadCardAction.sendToHq,
                          child: Text('Send to HQ',
                              style: TextStyle(fontSize: 12))),
                    const PopupMenuItem(
                        value: LeadCardAction.delete,
                        child: Text('Delete', style: TextStyle(fontSize: 12))),
                  ],
                ),
              ),
            ],
          ],
        ),

        // Dense contact line — only the fields that actually have a value.
        if (infoChips.isNotEmpty) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(children: _withDividers(infoChips)),
          ),
        ],

        // Value + source — value hidden when zero, source hidden when blank.
        if (revenue > 0 || lead.leadSource.label.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (revenue > 0) ...[
                Icon(Icons.payments_outlined, size: 15, color: Vibe.mint),
                const SizedBox(width: 5),
                Text(
                  '\$${revenue.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Vibe.mint,
                      fontSize: 14,
                      fontWeight: FontWeight.w800),
                ),
              ],
              const Spacer(),
              if (lead.leadSource.label.trim().isNotEmpty)
                Text(
                  lead.leadSource.label,
                  style: const TextStyle(color: Vibe.muted, fontSize: 11.5),
                ),
            ],
          ),
        ],

        if (showSendToHq) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => onAction!(LeadCardAction.sendToHq),
              icon:
                  const Icon(Icons.send_rounded, size: 11, color: Vibe.violet),
              label: const Text('Send to HQ',
                  style: TextStyle(color: Vibe.violet, fontSize: 10)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Vibe.violet),
                padding: const EdgeInsets.symmetric(
                    vertical: 4), // Heavily condensed inside button height
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ],

        // Assigned rep + created date — rep hidden when blank.
        const SizedBox(height: 12),
        Row(
          children: [
            if (lead.assignedRepName.trim().isNotEmpty) ...[
              const Icon(Icons.badge_outlined, size: 14, color: Vibe.muted),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  lead.assignedRepName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Vibe.muted, fontSize: 11.5),
                ),
              ),
            ] else
              const Spacer(),
            Text(
              _formatDate(lead.createdDate),
              style: const TextStyle(color: Vibe.muted, fontSize: 11.5),
            ),
          ],
        ),
      ],
    );
  }

  /// Interleaves [chips] with thin divider dots so only present fields get a
  /// separator (no leading/trailing/dangling dots).
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
        Icon(icon, size: 14, color: Vibe.muted),
        const SizedBox(width: 4),
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Vibe.muted, fontSize: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Text('•',
          style: TextStyle(
              color: Vibe.muted.withValues(alpha: 0.5), fontSize: 12)),
    );
  }
}
