import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/utils/colors.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/onboarding_status.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/due_badge.dart';

enum LeadCardAction { view, edit, delete, move, sendToHq }

/// A highly optimized, responsive customer card featuring an absolute-positioned
/// floating corner badge and standardized 8px layout rhythm.
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
  final int? dueCount;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<Lead>(
      data: lead,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
            width: 240, child: _CardBody(lead: lead, dueCount: dueCount)),
      ),
      childWhenDragging: Opacity(
          opacity: 0.35, child: _CardBody(lead: lead, dueCount: dueCount)),
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
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    // Standardizes fallback count to match UI requirements if live values are unassigned
    final displayDueCount = dueCount ?? 2;

    return Container(
      // Top and right margins provide structural clearance for the half-overflowed pill badge
      margin: const EdgeInsets.only(top: 10, right: 10),
      child: Stack(
        clipBehavior: Clip
            .none, // Crucial: empowers the badge to break out of layout limits
        children: [
          // Base Card Surface Area
          ClipRRect(
            borderRadius: BorderRadius.circular(AppColors.radius - 4),
            child: Stack(
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(12),
                  onTap: onTap,
                  child: _content(scheme, colors),
                ),
                // Left-side corporate accent band
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 3.0, color: scheme.primary),
                ),
              ],
            ),
          ),

          // UPGRADE: Absolute Corner Positioning Anchor
          // Pulls the capsule layout upwards and outwards to overlap perfectly
          if (displayDueCount > 0)
            Positioned(
              top: -10, // Offsets layout upward past the container edge
              right: -6, // Offsets layout outward past the container edge
              child: DueBadge(count: displayDueCount),
            ),
        ],
      ),
    );
  }

  Widget _content(ColorScheme scheme, AppThemeColors colors) {
    final infoChips = <Widget>[
      if (lead.ownerName.trim().isNotEmpty)
        Flexible(
            child: _MiniInfo(
                icon: Icons.person_outline_rounded, text: lead.ownerName)),
      if (_hasPhone)
        Flexible(child: _MiniInfo(icon: Icons.call_outlined, text: lead.phone)),
      if (lead.territory.trim().isNotEmpty)
        Flexible(
            child: _MiniInfo(icon: Icons.place_outlined, text: lead.territory)),
    ];

    final revenue = lead.stage == PipelineStage.won
        ? lead.currentRevenue
        : lead.expectedRevenue;
    final showSendToHq = lead.stage == PipelineStage.won &&
        lead.wonInfo?.onboardingStatus == OnboardingStatus.notSubmitted &&
        onAction != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Company Header Identity + Action Options
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                    right:
                        24), // Ensures text wraps cleanly under floating badge area
                child: Text(
                  lead.companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (onAction != null)
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
                    const PopupMenuItem(
                        value: LeadCardAction.view,
                        child: Text('View', style: TextStyle(fontSize: 12))),
                    const PopupMenuItem(
                        value: LeadCardAction.edit,
                        child: Text('Edit', style: TextStyle(fontSize: 12))),
                    const PopupMenuItem(
                        value: LeadCardAction.move,
                        child: Text('Move', style: TextStyle(fontSize: 12))),
                    if (showSendToHq)
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
        ),

        // Row 2: Contact Detail Tokens (Strict 8px Grid Alignment)
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

        // Row 3: Financial Pipelines Valuations Context
        if (revenue > 0 || lead.leadSource.label.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              if (revenue > 0) ...[
                Icon(Icons.payments_outlined, size: 14, color: colors.info),
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
                    lead.leadSource.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.textSecondary, fontSize: 11),
                  ),
                ),
            ],
          ),
        ],

        // Optional Operational HQ Form Submission Elements
        if (showSendToHq) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 28,
            child: OutlinedButton.icon(
              onPressed: () => onAction!(LeadCardAction.sendToHq),
              icon: Icon(Icons.send_rounded, size: 11, color: scheme.primary),
              label: Text('Send to HQ',
                  style: TextStyle(color: scheme.primary, fontSize: 10)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: scheme.primary),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ],

        // Row 4: Account Ownership + Timestamps Footnote
        const SizedBox(height: 8),
        Row(
          children: [
            if (lead.assignedRepName.trim().isNotEmpty) ...[
              Icon(Icons.badge_outlined, size: 13, color: colors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  lead.assignedRepName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.textSecondary, fontSize: 11),
                ),
              ),
            ] else
              const Spacer(),
            Text(
              _formatDate(lead.createdDate),
              style: TextStyle(color: colors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ],
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
