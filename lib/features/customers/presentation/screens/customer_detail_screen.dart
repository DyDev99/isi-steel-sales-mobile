import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_activity_type.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_detail_cubit.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_detail_state.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/widgets/customer_status_badge.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/credit_status.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/lead_source.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/opportunity_info.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/pipeline_stage.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/priority.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/create_lead.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_bloc.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/bloc/pipeline_event.dart';
import 'package:isi_steel_sales_mobile/features/lead/presentation/screens/pipeline_screen.dart';

/// Read-mostly profile of an approved SAP customer. SAP-controlled fields
/// (Overview, SAP Information) render with a muted/locked visual language;
/// only Notes/Activities are ever written from here.
class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  /// Stable resume-target key persisted on [ActiveWorkflow.currentScreen] and
  /// mapped back by the visit resume dispatcher.
  static const String routeName = 'customer-detail';

  final String customerId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CustomerDetailCubit>()..load(customerId),
      child: const _CustomerDetailView(),
    );
  }
}

class _CustomerDetailView extends StatefulWidget {
  const _CustomerDetailView();

  @override
  State<_CustomerDetailView> createState() => _CustomerDetailViewState();
}

class _CustomerDetailViewState extends State<_CustomerDetailView> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _createOpportunity(
      BuildContext context, Customer customer) async {
    final estimatedValue = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EstimatedValueSheet(customer: customer),
    );
    if (estimatedValue == null || !context.mounted) return;

    final lead = Lead(
      id: 'LEAD-${DateTime.now().microsecondsSinceEpoch}',
      companyName: customer.shopName,
      ownerName: customer.ownerName,
      phone: customer.phone,
      email: customer.email ?? '',
      address: customer.address,
      province: customer.province,
      district: customer.district,
      // TODO(release-gate): `Lead` still requires a pin and a rep, but a
      // SAP-synced customer carries neither (the business-partner payload has
      // no geolocation and no CRM owner). Falling back to 0,0 puts the lead in
      // the Gulf of Guinea on any map view. Either `Lead` gains nullable
      // coordinates, or this flow must capture the rep's GPS at creation time —
      // decided alongside the customer-coordinate ownership question.
      latitude: customer.latitude ?? 0,
      longitude: customer.longitude ?? 0,
      storefrontImageUrl: '',
      businessRegistrationNumber: '',
      taxId: '',
      leadSource: LeadSource.referral,
      createdDate: DateTime.now(),
      expectedRevenue: estimatedValue,
      currentRevenue: 0,
      assignedRepName: customer.assignedRepName ?? '',
      creditLimit: customer.creditLimit,
      creditStatus: CreditStatus.approved,
      stage: PipelineStage.opportunities,
      priority: Priority.medium,
      industry: 'Steel & Hardware',
      territory: customer.territory ?? '',
      opportunityInfo: OpportunityInfo(estimatedValue: estimatedValue),
    );

    await sl<CreateLead>()(lead);
    if (!context.mounted) return;

    context.read<CustomerDetailCubit>().logActivity(
          CustomerActivityType.opportunityCreated,
          'New opportunity opened (\$${estimatedValue.toStringAsFixed(0)})',
        );

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => sl<PipelineBloc>()..add(const PipelineLoadRequested()),
        child: const PipelineScreen(initialStage: PipelineStage.opportunities),
      ),
    ));
  }

  void _addNote(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Note',
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 4,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Write a note about this customer…',
                  filled: true,
                  fillColor: colors.surfaceSoft,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.border)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context
                        .read<CustomerDetailCubit>()
                        .addNote(_noteController.text);
                    _noteController.clear();
                    Navigator.pop(sheetContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Save Note',
                      style: TextStyle(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LocalizedBuilder(
      builder: (context) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          iconTheme: IconThemeData(color: context.appColors.textPrimary),
          title: BlocBuilder<CustomerDetailCubit, CustomerDetailState>(
            builder: (context, state) => Text(
              state is CustomerDetailLoaded
                  ? state.customer.shopName
                  : 'customers.customer_fallback'.tr,
              style: TextStyle(
                  color: context.appColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ),
        body: BlocBuilder<CustomerDetailCubit, CustomerDetailState>(
          builder: (context, state) {
            return switch (state) {
              CustomerDetailLoaded() => _Loaded(
                  state: state,
                  onCall: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('customers.calling'
                            .tr
                            .replaceAll('{phone}', state.customer.phone)),
                        duration: const Duration(seconds: 1)),
                  ),
                  onCreateOpportunity: () =>
                      _createOpportunity(context, state.customer),
                  onLogVisit: () {
                    context.read<CustomerDetailCubit>().logActivity(
                        CustomerActivityType.visit,
                        'customers.visit_logged'.tr);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('customers.visit_logged'.tr),
                        duration: const Duration(seconds: 1)));
                  },
                  onAddNote: () => _addNote(context),
                ),
              CustomerDetailError(:final message) => Center(
                  child: Text(message,
                      style:
                          TextStyle(color: context.appColors.textSecondary))),
              _ => Center(
                  child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary)),
            };
          },
        ),
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.state,
    required this.onCall,
    required this.onCreateOpportunity,
    required this.onLogVisit,
    required this.onAddNote,
  });

  final CustomerDetailLoaded state;
  final VoidCallback onCall;
  final VoidCallback onCreateOpportunity;
  final VoidCallback onLogVisit;
  final VoidCallback onAddNote;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final customer = state.customer;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // `onCreateOpportunityForProduct` was removed with the hardcoded
        // cross-sell chips — see the rationale on _SalesInsightsSection.build.
        _SalesInsightsSection(customer: customer),
        const SizedBox(height: 12),
        //  CustomerQuickActions(
        //   onCall: onCall,
        //   onCreateOpportunity: onCreateOpportunity,
        // onLogVisit: onLogVisit,
        //  onAddNote: onAddNote,
        //  ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Overview',
          locked: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    // The SAP business partner has no proprietor, so
                    // `ownerName` is empty on every real record. The legal
                    // English name is the genuine SAP field with the same
                    // intent; the customer number is the last resort — real
                    // data only, never a blank header line.
                    child: Text(
                        _firstNonEmpty([
                          customer.ownerName,
                          customer.enName ?? '',
                          customer.customerCode,
                        ]),
                        style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                  ),
                  CustomerStatusBadge(status: customer.status),
                ],
              ),
              const SizedBox(height: 8),
              _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Customer Code',
                  value: customer.customerCode),
              _InfoRow(
                  icon: Icons.call_outlined,
                  label: 'Phone',
                  value: customer.phone.isEmpty ? '—' : customer.phone),
              if (customer.email != null && customer.email!.isNotEmpty)
                _InfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: customer.email!),
              // Only the Khmer legal name gets its own row — `enName` already
              // serves as the header fallback above.
              if ((customer.khName ?? '').isNotEmpty)
                _InfoRow(
                    icon: Icons.translate_rounded,
                    label: 'Khmer Name',
                    value: customer.khName!),
              _InfoRow(
                  icon: Icons.place_outlined,
                  label: 'Address',
                  // SAP supplies street/city/country only — district is not in
                  // the payload. Joining blindly rendered ', , Phnom Penh'.
                  value: _joinNonEmpty([
                    customer.address,
                    customer.district,
                    customer.province,
                  ])),
              _InfoRow(
                  icon: Icons.person_pin_circle_outlined,
                  label: 'Assigned Rep',
                  // An em dash, not a blank: the row should read as "we do not
                  // know" rather than looking like a rendering glitch.
                  value: customer.assignedRepName ?? '—'),
              if (customer.openOpportunityCount > 0)
                _InfoRow(
                    icon: Icons.trending_up_rounded,
                    label: 'Open Opportunities',
                    value: '${customer.openOpportunityCount}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (customer.contacts.isNotEmpty)
          _SectionCard(
            title: 'Contacts',
            child: Column(
              children: [
                for (final contact in customer.contacts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                            radius: 16,
                            backgroundColor: colors.surfaceStrong,
                            child: Icon(Icons.person,
                                size: 16, color: scheme.primary)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(contact.name,
                                  style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                              Text('${contact.role} · ${contact.phone}',
                                  style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 11.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Sales History',
          locked: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                  icon: Icons.payments_outlined,
                  label: 'Lifetime Value',
                  // '$0' looks like a statement about the account; the SAP BP
                  // payload simply does not carry order history, so a zero here
                  // means "not told", not "never bought anything".
                  value: customer.lifetimeValue > 0
                      ? '\$${customer.lifetimeValue.toStringAsFixed(0)}'
                      : '—'),
              if (customer.totalOrders > 0)
                _InfoRow(
                    icon: Icons.receipt_long_outlined,
                    label: 'Total Orders',
                    value: '${customer.totalOrders}'),
              _InfoRow(
                icon: Icons.event_outlined,
                label: 'Last Order',
                value: customer.lastOrderDate == null
                    ? 'No orders yet'
                    : _formatDate(customer.lastOrderDate!),
              ),
              if (customer.productsPurchased.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final p in customer.productsPurchased)
                        _ProductChip(label: p)
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'SAP Information',
          locked: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                  icon: Icons.fingerprint_rounded,
                  label: 'SAP Customer ID',
                  value: customer.sapCustomerId),
              // ── Commercial block — real fields from the BP payload ────
              // Every row below renders exactly what SAP sent, with an em dash
              // where the ERP left the field blank. No value here is invented
              // client-side.
              _InfoRow(
                  icon: Icons.account_tree_outlined,
                  label: 'Sales Area',
                  value: _joinNonEmpty([
                    customer.salesOrg ?? '',
                    customer.distributionChannel ?? '',
                    customer.division ?? '',
                  ], separator: ' / ')),
              _InfoRow(
                  icon: Icons.group_work_outlined,
                  label: 'Customer Group',
                  value: customer.customerGroup ?? '—'),
              _InfoRow(
                  icon: Icons.schedule_outlined,
                  label: 'Payment Terms',
                  value: customer.paymentTerms ?? '—'),
              _InfoRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Credit Limit',
                  value:
                      '${customer.currency} ${customer.creditLimit.toStringAsFixed(0)}'),
              if (customer.creditBalance > 0) ...[
                _InfoRow(
                    icon: Icons.trending_down_rounded,
                    label: 'Credit Used',
                    value:
                        '${customer.currency} ${customer.creditBalance.toStringAsFixed(0)}'),
                _InfoRow(
                    icon: Icons.savings_outlined,
                    label: 'Available Credit',
                    value:
                        '${customer.currency} ${customer.availableCredit.toStringAsFixed(0)}'),
              ],
              if ((customer.taxNumber ?? '').isNotEmpty)
                _InfoRow(
                    icon: Icons.receipt_outlined,
                    label: 'Tax Number',
                    value: customer.taxNumber!),
              _InfoRow(
                  icon: Icons.update_rounded,
                  label: 'Last Synced',
                  value: _formatDate(customer.updatedAt)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Timeline',
          child: state.activities.isEmpty && state.notes.isEmpty
              ? Text('No activity yet',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12.5))
              : Column(
                  children: [
                    for (final activity in state.activities)
                      _TimelineRow(
                          icon: _iconFor(activity.type),
                          text: activity.summary,
                          at: activity.createdAt),
                  ],
                ),
        ),
      ],
    );
  }

  IconData _iconFor(CustomerActivityType type) => switch (type) {
        CustomerActivityType.call => Icons.call_rounded,
        CustomerActivityType.whatsapp => Icons.chat_rounded,
        CustomerActivityType.visit => Icons.pin_drop_rounded,
        CustomerActivityType.note => Icons.note_rounded,
        CustomerActivityType.opportunityCreated => Icons.trending_up_rounded,
        CustomerActivityType.order => Icons.shopping_bag_rounded,
      };

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _EstimatedValueSheet extends StatefulWidget {
  const _EstimatedValueSheet({required this.customer});
  final Customer customer;

  @override
  State<_EstimatedValueSheet> createState() => _EstimatedValueSheetState();
}

class _EstimatedValueSheetState extends State<_EstimatedValueSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Opportunity for ${widget.customer.shopName}',
                style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Estimated Value (\$)',
                filled: true,
                fillColor: colors.surfaceSoft,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.border)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final value = double.tryParse(_controller.text) ?? 0;
                  Navigator.pop(context, value);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Create Opportunity',
                    style: TextStyle(
                        color: scheme.onPrimary, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesInsightsSection extends StatelessWidget {
  const _SalesInsightsSection({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    // Cross-sell recommendations were a hardcoded three-product list here —
    // the same 'Galvanized Pipes / Roofing Screws / Steel Wire Mesh' shown for
    // every customer regardless of what they buy. Removed with the rest of the
    // customer mock data.
    //
    // It was not merely cosmetic: each chip was tappable and created a real
    // Lead via `onCreateOpportunityForProduct`, so a rep could raise a genuine
    // opportunity off a recommendation nothing had computed.
    //
    // Restoring the section needs a real source — SAP's business-partner
    // payload carries no purchase history or recommendation, so this would come
    // from an ISI-side analytics endpoint or a local rule over the order
    // history, surfaced through a usecase rather than assembled in `build()`
    // (`docs/AI_ENGINEERING_PLAYBOOK.md` §1: no business logic in widgets).

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Sales History & Insights',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.lock_outline_rounded,
                  size: 13, color: colors.textSecondary),
            ],
          ),
          const SizedBox(height: 12),

          // Row 1: Key Performance Metrics
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.payments_outlined,
                  label: 'Lifetime Value',
                  // Not supplied by the SAP BP payload — '—' rather than a
                  // '$0' that reads as "this customer never bought anything".
                  value: customer.lifetimeValue > 0
                      ? '\$${customer.lifetimeValue.toStringAsFixed(0)}'
                      : '—',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  icon: Icons.event_outlined,
                  label: 'Last Order',
                  value: customer.lastOrderDate == null
                      ? 'No orders yet'
                      : _formatDate(customer.lastOrderDate!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 2: Currently Purchased Lines
          Text(
            'Active Product Mix',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (customer.productsPurchased.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final product in customer.productsPurchased)
                  _InsightChip(label: product),
              ],
            )
          else
            Text(
              'No active product lines found.',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),

          const SizedBox(height: 16),

          // Row 3: Gap Analysis / White Spaces
          Text(
            'Cross-Sell Gaps',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Not available yet.',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: colors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(color: colors.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightChip extends StatelessWidget {
  const _InsightChip({required this.label});

  final String label;

  // Previously had an `isPurchased` flag and an `onTap`, to render two variants:
  // products the customer buys, and tappable "cross-sell gap" suggestions. The
  // suggestions were hardcoded and their tap did nothing, so both are gone and
  // this is now what it always actually was — a read-only label for a product
  // the customer purchases.

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.info.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.info,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title, required this.child, this.locked = false});
  final String title;
  final Widget child;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style: TextStyle(
                      color: context.appColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
              if (locked) ...[
                const SizedBox(width: 6),
                Icon(Icons.lock_outline_rounded,
                    size: 13, color: context.appColors.textSecondary),
              ],
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// First candidate that actually holds text — for slots that must never render
/// blank but must never invent a value either.
String _firstNonEmpty(List<String> candidates) {
  for (final candidate in candidates) {
    if (candidate.isNotEmpty) return candidate;
  }
  return '—';
}

/// Joins only the parts SAP populated. Interpolating blindly produced
/// `', , Phnom Penh'`-style strings on real records, where the mock had always
/// filled every part.
String _joinNonEmpty(List<String> parts, {String separator = ', '}) {
  final present = parts.where((p) => p.isNotEmpty).toList();
  return present.isEmpty ? '—' : present.join(separator);
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: colors.textSecondary),
          const SizedBox(width: 8),
          SizedBox(
              width: 110,
              child: Text(label,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12))),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _ProductChip extends StatelessWidget {
  const _ProductChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final info = context.appColors.info;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: info.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              color: info, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow(
      {required this.icon, required this.text, required this.at});
  final IconData icon;
  final String text;
  final DateTime at;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
                Text(_formatDateTime(at),
                    style:
                        TextStyle(color: colors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
