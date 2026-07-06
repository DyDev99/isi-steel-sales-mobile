import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/local/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_activity_type.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_detail_cubit.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_detail_state.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/widgets/customer_quick_actions.dart';
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

  Future<void> _createOpportunity(BuildContext context, Customer customer) async {
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
      latitude: customer.latitude,
      longitude: customer.longitude,
      storefrontImageUrl: '',
      businessRegistrationNumber: '',
      taxId: '',
      leadSource: LeadSource.referral,
      createdDate: DateTime.now(),
      expectedRevenue: estimatedValue,
      currentRevenue: 0,
      assignedRepName: customer.assignedRepName,
      creditLimit: customer.creditLimit,
      creditStatus: CreditStatus.approved,
      stage: PipelineStage.opportunities,
      priority: Priority.medium,
      industry: 'Steel & Hardware',
      territory: customer.territory,
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(color: Vibe.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Note', style: TextStyle(color: Vibe.text, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 4,
                style: const TextStyle(color: Vibe.text),
                decoration: InputDecoration(
                  hintText: 'Write a note about this customer…',
                  filled: true,
                  fillColor: Vibe.bgSoft,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Vibe.stroke)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<CustomerDetailCubit>().addNote(_noteController.text);
                    _noteController.clear();
                    Navigator.pop(sheetContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Vibe.violet,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Save Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
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
      backgroundColor: Vibe.bg,
      appBar: AppBar(
        backgroundColor: Vibe.bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Vibe.text),
        title: BlocBuilder<CustomerDetailCubit, CustomerDetailState>(
          builder: (context, state) => Text(
            state is CustomerDetailLoaded ? state.customer.shopName : 'customers.customer_fallback'.tr,
            style: const TextStyle(color: Vibe.text, fontSize: 16, fontWeight: FontWeight.w800),
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
                      content: Text('customers.calling'.tr.replaceAll('{phone}', state.customer.phone)),
                      duration: const Duration(seconds: 1)),
                ),
                onCreateOpportunity: () => _createOpportunity(context, state.customer),
                onLogVisit: () {
                  context.read<CustomerDetailCubit>().logActivity(CustomerActivityType.visit, 'customers.visit_logged'.tr);
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('customers.visit_logged'.tr), duration: const Duration(seconds: 1)));
                },
                onAddNote: () => _addNote(context),
              ),
            CustomerDetailError(:final message) => Center(child: Text(message, style: const TextStyle(color: Vibe.muted))),
            _ => const Center(child: CircularProgressIndicator(color: Vibe.violet)),
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
    final customer = state.customer;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        CustomerQuickActions(
          onCall: onCall,
          onCreateOpportunity: onCreateOpportunity,
          onLogVisit: onLogVisit,
          onAddNote: onAddNote,
        ),
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
                    child: Text(customer.ownerName, style: const TextStyle(color: Vibe.text, fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                  CustomerStatusBadge(status: customer.status),
                ],
              ),
              const SizedBox(height: 8),
              _InfoRow(icon: Icons.badge_outlined, label: 'Customer Code', value: customer.customerCode),
              _InfoRow(icon: Icons.call_outlined, label: 'Phone', value: customer.phone),
              if (customer.email != null) _InfoRow(icon: Icons.email_outlined, label: 'Email', value: customer.email!),
              _InfoRow(icon: Icons.place_outlined, label: 'Address', value: '${customer.address}, ${customer.district}, ${customer.province}'),
              _InfoRow(icon: Icons.person_pin_circle_outlined, label: 'Assigned Rep', value: customer.assignedRepName),
              if (customer.openOpportunityCount > 0)
                _InfoRow(icon: Icons.trending_up_rounded, label: 'Open Opportunities', value: '${customer.openOpportunityCount}'),
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
                        const CircleAvatar(radius: 16, backgroundColor: Vibe.primaryLight, child: Icon(Icons.person, size: 16, color: Vibe.violet)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(contact.name, style: const TextStyle(color: Vibe.text, fontSize: 13, fontWeight: FontWeight.w700)),
                              Text('${contact.role} · ${contact.phone}', style: const TextStyle(color: Vibe.muted, fontSize: 11.5)),
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
              _InfoRow(icon: Icons.payments_outlined, label: 'Lifetime Value', value: '\$${customer.lifetimeValue.toStringAsFixed(0)}'),
              _InfoRow(
                icon: Icons.event_outlined,
                label: 'Last Order',
                value: customer.lastOrderDate == null ? 'No orders yet' : _formatDate(customer.lastOrderDate!),
              ),
              if (customer.productsPurchased.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [for (final p in customer.productsPurchased) _ProductChip(label: p)],
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
              _InfoRow(icon: Icons.fingerprint_rounded, label: 'SAP Customer ID', value: customer.sapCustomerId),
              _InfoRow(icon: Icons.account_balance_wallet_outlined, label: 'Credit Limit', value: '\$${customer.creditLimit.toStringAsFixed(0)}'),
              _InfoRow(icon: Icons.update_rounded, label: 'Last Synced', value: _formatDate(customer.updatedAt)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Timeline',
          child: state.activities.isEmpty && state.notes.isEmpty
              ? const Text('No activity yet', style: TextStyle(color: Vibe.muted, fontSize: 12.5))
              : Column(
                  children: [
                    for (final activity in state.activities)
                      _TimelineRow(icon: _iconFor(activity.type), text: activity.summary, at: activity.createdAt),
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(color: Vibe.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Opportunity for ${widget.customer.shopName}',
                style: const TextStyle(color: Vibe.text, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Vibe.text),
              decoration: InputDecoration(
                labelText: 'Estimated Value (\$)',
                filled: true,
                fillColor: Vibe.bgSoft,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Vibe.stroke)),
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
                  backgroundColor: Vibe.violet,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Create Opportunity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.locked = false});
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
              Text(title, style: const TextStyle(color: Vibe.text, fontSize: 14, fontWeight: FontWeight.w800)),
              if (locked) ...[
                const SizedBox(width: 6),
                const Icon(Icons.lock_outline_rounded, size: 13, color: Vibe.muted),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Vibe.muted),
          const SizedBox(width: 8),
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Vibe.muted, fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(color: Vibe.text, fontSize: 12.5, fontWeight: FontWeight.w600))),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Vibe.mint.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: Vibe.mint, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.icon, required this.text, required this.at});
  final IconData icon;
  final String text;
  final DateTime at;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: Vibe.violet),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(color: Vibe.text, fontSize: 12.5, fontWeight: FontWeight.w600)),
                Text(_formatDateTime(at), style: const TextStyle(color: Vibe.muted, fontSize: 11)),
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
