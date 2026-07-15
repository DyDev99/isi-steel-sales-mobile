import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/aurora_background.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user_role.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/activity_log_item.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/budget_status.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/onboarding_status.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/opportunity_info.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/opportunity_sub_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/lead_detail_cubit.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/lead_detail_state.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_bloc.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_event.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/activity_timeline.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/documents_section.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/gps_location_card.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/lead_form_sheet.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/move_stage_sheet.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/notes_section.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/onboarding_status_badge.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/priority_badge.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/send_to_hq_sheet.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/widgets/stage_badge.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/cart/cart_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/catalog_bloc.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/catalog_event.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/bloc/catalog/sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/order/presentation/screens/quotation/quotation_builder_screen.dart';

/// First "detail screen with an argument" in this app — pushed via
/// Navigator.push from a [LeadCard] tap, wrapped by the caller in a
/// MultiBlocProvider that shares the board's PipelineBloc (for move/delete)
/// alongside a fresh LeadDetailCubit (for this record's read/write state).
class LeadDetailScreen extends StatelessWidget {
  const LeadDetailScreen({super.key, required this.leadId});
  final String leadId;

  bool get _isAdmin => sl<SessionManager>().can(UserRole.admin);

  Future<void> _edit(BuildContext context, Lead lead) async {
    final updated = await showLeadFormSheet(context: context, existing: lead);
    if (updated != null && context.mounted) {
      context.read<PipelineBloc>().add(LeadUpdated(updated));
      await context.read<LeadDetailCubit>().reload();
    }
  }

  Future<void> _move(BuildContext context, Lead lead) async {
    final result = await showMoveStageSheet(
        context: context, lead: lead, isAdmin: _isAdmin);
    if (result != null && context.mounted) {
      context.read<PipelineBloc>().add(LeadMoved(
            leadId: lead.id,
            toStage: result.toStage,
            opportunityInfo: result.opportunityInfo,
            wonInfo: result.wonInfo,
          ));
      await context.read<LeadDetailCubit>().reload();
    }
  }

  Future<void> _sendToHq(BuildContext context, Lead lead) async {
    final updated = await showSendToHqSheet(context: context, lead: lead);
    if (updated != null && context.mounted) {
      context.read<PipelineBloc>().add(LeadUpdated(updated));
      await context.read<LeadDetailCubit>().reload();
    }
  }

  Future<void> _delete(BuildContext context, Lead lead) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appColors.surfaceSoft,
        title: Text('Delete lead?',
            style: TextStyle(color: context.appColors.textPrimary)),
        content: Text('This removes ${lead.companyName} from the pipeline.',
            style: TextStyle(color: context.appColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<PipelineBloc>().add(LeadDeleted(lead.id));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          SafeArea(
            child: BlocBuilder<LeadDetailCubit, LeadDetailState>(
              builder: (context, state) => switch (state) {
                LeadDetailLoaded(:final lead, :final activity) => _DetailBody(
                    lead: lead,
                    activity: activity,
                    onEdit: () => _edit(context, lead),
                    onMove: () => _move(context, lead),
                    onDelete: () => _delete(context, lead),
                    onSendToHq: () => _sendToHq(context, lead),
                  ),
                LeadDetailError(:final message) => Center(
                    child: Text(message,
                        style:
                            TextStyle(color: context.appColors.textSecondary)),
                  ),
                _ => Center(
                    child:
                        CircularProgressIndicator(color: scheme.secondary)),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.lead,
    required this.activity,
    required this.onEdit,
    required this.onMove,
    required this.onDelete,
    required this.onSendToHq,
  });

  final Lead lead;
  final List<ActivityLogItem> activity;
  final VoidCallback onEdit;
  final VoidCallback onMove;
  final VoidCallback onDelete;
  final VoidCallback onSendToHq;

  void _updateOpportunity(
      BuildContext context, OpportunityInfo Function(OpportunityInfo) update) {
    final info = lead.opportunityInfo;
    if (info == null) return;
    final updated = lead.copyWith(opportunityInfo: update(info));
    context.read<PipelineBloc>().add(LeadUpdated(updated));
    context.read<LeadDetailCubit>().reload();
  }

  /// Leads have no SAP `Customer` yet (that only exists after Won -> HQ
  /// Approval), so a lead-scoped quotation skips Territory/Shop picking
  /// entirely and opens the Quotation Builder directly in "lead mode"
  /// (no credit/CN-DN/off-visit — there's no shop to source them from).
  void _openCatalog(
      BuildContext context, String leadId, String leadDisplayName) {
    Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: QuotationBuilderScreen.routeName),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(
              create: (_) =>
                  sl<CatalogBloc>()..add(const CatalogLoadRequested())),
          BlocProvider(create: (_) => sl<CartCubit>()..load()),
          BlocProvider(create: (_) => sl<SyncCubit>()),
        ],
        child: QuotationBuilderScreen(
            leadId: leadId, leadDisplayName: leadDisplayName),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LeadDetailCubit>();
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
            ),
            Expanded(
              child: Text(lead.companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
            ),
            if (lead.stage == PipelineStage.won &&
                lead.wonInfo?.onboardingStatus == OnboardingStatus.notSubmitted)
              IconButton(
                  onPressed: onSendToHq,
                  icon: Icon(Icons.send_rounded, color: scheme.primary)),
            IconButton(
                onPressed: onEdit,
                icon: Icon(Icons.edit_outlined, color: colors.textPrimary)),
            IconButton(
                onPressed: onMove,
                icon:
                    Icon(Icons.swap_horiz_rounded, color: colors.textPrimary)),
            IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline_rounded, color: scheme.error)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          StageBadge(stage: lead.stage),
          PriorityBadge(priority: lead.priority),
          if (lead.stage == PipelineStage.won && lead.wonInfo != null)
            OnboardingStatusBadge(status: lead.wonInfo!.onboardingStatus),
        ]),
        const SizedBox(height: 16),
        _Section(
          title: 'Storefront Photo',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 150,
              width: double.infinity,
              child: Image.network(
                lead.storefrontImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: colors.card,
                  alignment: Alignment.center,
                  child: Icon(Icons.storefront_rounded,
                      color: colors.textSecondary, size: 36),
                ),
              ),
            ),
          ),
        ),
        _Section(
          title: 'General Information',
          child: Column(
            children: [
              _KeyValue('Owner', lead.ownerName),
              _KeyValue('Phone', lead.phone),
              _KeyValue('Email', lead.email.isEmpty ? '—' : lead.email),
              _KeyValue('Assigned rep', lead.assignedRepName),
              _KeyValue('Lead source', lead.leadSource.label),
              _KeyValue('Created', _formatDate(lead.createdDate)),
              _KeyValue('Industry', lead.industry),
            ],
          ),
        ),
        _Section(
          title: 'Business Information',
          child: Column(
            children: [
              _KeyValue(
                  'Business registration #', lead.businessRegistrationNumber),
              _KeyValue('Tax ID', lead.taxId),
              _KeyValue('Expected revenue',
                  '\$${lead.expectedRevenue.toStringAsFixed(0)}'),
              if (lead.stage == PipelineStage.won)
                _KeyValue('Current revenue',
                    '\$${lead.currentRevenue.toStringAsFixed(0)}'),
            ],
          ),
        ),
        _Section(
          title: 'Contacts',
          child: lead.contacts.isEmpty
              ? Text('No contacts yet',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12.5))
              : Column(
                  children: lead.contacts
                      .map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('${c.name} · ${c.role}',
                                          style: TextStyle(
                                              color: colors.textPrimary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700)),
                                      Text(c.phone,
                                          style: TextStyle(
                                              color: colors.textSecondary,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                if (c.isPrimary)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          scheme.primary.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text('Primary',
                                        style: TextStyle(
                                            color: scheme.primary,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700)),
                                  ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
        ),
        _Section(
          title: 'Address & GPS Location',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lead.address,
                  style: TextStyle(color: colors.textPrimary, fontSize: 13)),
              const SizedBox(height: 10),
              GpsLocationCard(
                  latitude: lead.latitude,
                  longitude: lead.longitude,
                  address: lead.district),
            ],
          ),
        ),
        _Section(
          title: 'KYC Documents',
          child: DocumentsSection(
            documents: lead.documents,
            onAddDocument: (type, name) => cubit.addMockDocument(type, name),
          ),
        ),
        _Section(
          title: 'Credit Status',
          child: Column(
            children: [
              _KeyValue('Status', lead.creditStatus.label),
              _KeyValue(
                  'Credit limit', '\$${lead.creditLimit.toStringAsFixed(0)}'),
            ],
          ),
        ),
        if (lead.opportunityInfo case final info?)
          _Section(
            title: 'Opportunity Information',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KeyValue('Estimated value',
                    '\$${info.estimatedValue.toStringAsFixed(0)}'),
                const SizedBox(height: 4),
                Text('Tap what you know. Nothing here is required.',
                    style:
                        TextStyle(color: colors.textSecondary, fontSize: 11.5)),
                const SizedBox(height: 10),
                Text('Stage',
                    style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: OpportunitySubStage.values
                      .map((s) => ChoiceChip(
                            label: Text(s.label),
                            selected: info.subStage == s,
                            onSelected: (_) => _updateOpportunity(
                                context, (i) => i.copyWith(subStage: s)),
                            labelStyle: TextStyle(
                                color: info.subStage == s
                                    ? scheme.primary
                                    : colors.textPrimary,
                                fontSize: 12.5),
                            backgroundColor: colors.card,
                            selectedColor: scheme.primary.withValues(alpha: 0.2),
                            side: BorderSide(
                                color: info.subStage == s
                                    ? scheme.primary
                                    : colors.border),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                Text('Tonnage',
                    style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    ('<5t', 3.0),
                    ('5-20t', 12.0),
                    ('20-50t', 35.0),
                    ('50t+', 60.0)
                  ]
                      .map((t) => ChoiceChip(
                            label: Text(t.$1),
                            selected: info.tonnage == t.$2,
                            onSelected: (_) => _updateOpportunity(
                                context, (i) => i.copyWith(tonnage: t.$2)),
                            labelStyle: TextStyle(
                                color: info.tonnage == t.$2
                                    ? scheme.primary
                                    : colors.textPrimary,
                                fontSize: 12.5),
                            backgroundColor: colors.card,
                            selectedColor: scheme.primary.withValues(alpha: 0.2),
                            side: BorderSide(
                                color: info.tonnage == t.$2
                                    ? scheme.primary
                                    : colors.border),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                Text('Budget',
                    style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: BudgetStatus.values
                      .map((b) => ChoiceChip(
                            label: Text(b.label),
                            selected: info.budgetStatus == b,
                            onSelected: (_) => _updateOpportunity(
                                context, (i) => i.copyWith(budgetStatus: b)),
                            labelStyle: TextStyle(
                                color: info.budgetStatus == b
                                    ? scheme.primary
                                    : colors.textPrimary,
                                fontSize: 12.5),
                            backgroundColor: colors.card,
                            selectedColor: scheme.primary.withValues(alpha: 0.2),
                            side: BorderSide(
                                color: info.budgetStatus == b
                                    ? scheme.primary
                                    : colors.border),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                Text('Authority',
                    style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Talking to decision maker'),
                      selected: info.hasDecisionMakerAccess == true,
                      onSelected: (_) => _updateOpportunity(context,
                          (i) => i.copyWith(hasDecisionMakerAccess: true)),
                      labelStyle: TextStyle(
                          color: info.hasDecisionMakerAccess == true
                              ? scheme.primary
                              : colors.textPrimary,
                          fontSize: 12.5),
                      backgroundColor: colors.card,
                      selectedColor: scheme.primary.withValues(alpha: 0.2),
                      side: BorderSide(
                          color: info.hasDecisionMakerAccess == true
                              ? scheme.primary
                              : colors.border),
                    ),
                    ChoiceChip(
                      label: const Text('Not yet'),
                      selected: info.hasDecisionMakerAccess == false,
                      onSelected: (_) => _updateOpportunity(context,
                          (i) => i.copyWith(hasDecisionMakerAccess: false)),
                      labelStyle: TextStyle(
                          color: info.hasDecisionMakerAccess == false
                              ? scheme.primary
                              : colors.textPrimary,
                          fontSize: 12.5),
                      backgroundColor: colors.card,
                      selectedColor: scheme.primary.withValues(alpha: 0.2),
                      side: BorderSide(
                          color: info.hasDecisionMakerAccess == false
                              ? scheme.primary
                              : colors.border),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _openCatalog(context, lead.id, lead.companyName),
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                    label: const Text('Add Products'),
                  ),
                ),
              ],
            ),
          ),
        if (lead.wonInfo case final won?)
          _Section(
            title: 'Sales History',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KeyValue(
                    'Final value', '\$${won.finalValue.toStringAsFixed(0)}'),
                _KeyValue('Delivery timeline', won.deliveryTimeline ?? '—'),
                _KeyValue('Onboarding status', won.onboardingStatus.label),
                if (won.shopType != null)
                  _KeyValue('Shop type', won.shopType!.label),
                if (won.customerCode != null)
                  _KeyValue('Customer code', won.customerCode!),
                if (won.sapCustomerId != null)
                  _KeyValue('SAP customer ID', won.sapCustomerId!),
                if (won.approvedCreditLimit != null)
                  _KeyValue('Approved credit limit',
                      '\$${won.approvedCreditLimit!.toStringAsFixed(0)}'),
                if (won.approvalDate != null)
                  _KeyValue('Approval date', _formatDate(won.approvalDate!)),
                if (won.contractDate != null)
                  _KeyValue('Contract date', _formatDate(won.contractDate!)),
                if (won.annualRevenue != null)
                  _KeyValue('Annual revenue',
                      '\$${won.annualRevenue!.toStringAsFixed(0)}'),
                if (won.productsPurchased.isNotEmpty)
                  _KeyValue(
                      'Products purchased', won.productsPurchased.join(', ')),
                if (won.firstOrderDate != null)
                  _KeyValue(
                      'First order date', _formatDate(won.firstOrderDate!)),
                if (won.accountManager != null)
                  _KeyValue('Account manager', won.accountManager!),
                if (won.onboardingStatus == OnboardingStatus.notSubmitted) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onSendToHq,
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Send to HQ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        _Section(
          title: 'Activity Timeline',
          child: ActivityTimeline(items: activity),
        ),
        _Section(
          title: 'Notes',
          child: NotesSection(notes: lead.notes, onAddNote: cubit.addNote),
        ),
      ],
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    color: context.appColors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: TextStyle(color: colors.textSecondary, fontSize: 12.5)),
          ),
          Expanded(
            child: Text(value.isEmpty ? '—' : value,
                style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
