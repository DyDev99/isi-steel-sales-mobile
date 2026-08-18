import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_activity_type.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_detail_cubit.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_detail_state.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/app_bottom_sheet.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/outlet_information/outlet_info_view_data.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/outlet_information/outlet_information_view.dart';

/// Read-mostly profile of an approved SAP customer.
///
/// Renders [OutletInformationView] — the same body as the visit flow's stop
/// information screen — so a shop looks identical whether the rep opened it
/// from today's route or from the customer directory. Everything SAP owns is
/// read-only here; only Notes/Activities are ever written from this screen, and
/// they are appended as a trailing card below the shared sections.
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

  /// Same escalation ladder as the visit flow: Telegram app, Telegram web, then
  /// a plain dial. Reps reach shop owners on Telegram far more often than by
  /// call, so trying `tel:` first would bury the channel they actually use.
  Future<void> _openPhoneOrTelegram(String rawPhoneNumber) async {
    String cleanNumber = rawPhoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleanNumber.startsWith('0')) {
      cleanNumber = '+855${cleanNumber.substring(1)}';
    } else if (!cleanNumber.startsWith('+')) {
      cleanNumber = '+$cleanNumber';
    }

    final Uri telegramTgUri = Uri.parse('tg://resolve?phone=$cleanNumber');
    final Uri telegramWebUri = Uri.parse('https://t.me/$cleanNumber');
    final Uri callUri = Uri.parse('tel:$cleanNumber');

    try {
      bool launched = await launchUrl(
        telegramTgUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        launched = await launchUrl(
          telegramWebUri,
          mode: LaunchMode.externalApplication,
        );
      }
      if (!launched) {
        await launchUrl(callUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      try {
        await launchUrl(callUri, mode: LaunchMode.externalApplication);
      } catch (err) {
        debugPrint('Could not launch phone app: $err');
      }
    }
  }

  Future<void> _openGoogleMaps(double latitude, double longitude) async {
    final Uri googleMapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    try {
      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch Google Maps: $e');
    }
  }

  void _addNote(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    showModalBottomSheet(
      constraints: const BoxConstraints(maxWidth: AppBottomSheet.maxWidth),
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
              Text('common.add_note'.tr,
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: context.rsp(16),
                      fontWeight: FontWeight.w800)),
              SizedBox(height: context.rh(12)),
              TextField(
                controller: _noteController,
                maxLines: 4,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'customers.note_hint'.tr,
                  filled: true,
                  fillColor: colors.surfaceSoft,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.border)),
                ),
              ),
              SizedBox(height: context.rh(16)),
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
                  child: Text('customers.save_note'.tr,
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
      builder: (context) {
        final colors = context.appColors;
        return Scaffold(
          backgroundColor: colors.canvas,
          appBar: AppBar(
            backgroundColor: colors.canvas,
            elevation: 0,
            scrolledUnderElevation: 0,
            toolbarHeight: context.rh(56),
            iconTheme: IconThemeData(
              color: colors.textPrimary,
              size: context.rr(24),
            ),
            title: Text(
              'Outlet Information',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: context.rsp(17),
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: [
              BlocBuilder<CustomerDetailCubit, CustomerDetailState>(
                builder: (context, state) => IconButton(
                  tooltip: 'common.add_note'.tr,
                  icon: Icon(
                    Icons.note_add_outlined,
                    color: colors.textPrimary,
                    size: context.rr(22),
                  ),
                  onPressed: state is CustomerDetailLoaded
                      ? () => _addNote(context)
                      : null,
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: BlocBuilder<CustomerDetailCubit, CustomerDetailState>(
              builder: (context, state) {
                return switch (state) {
                  CustomerDetailLoaded() => OutletInformationView(
                      data: _viewData(state.customer),
                      onPhoneTap: state.customer.phone.isEmpty
                          ? null
                          : _openPhoneOrTelegram,
                      onLocationTap: _openGoogleMaps,
                      trailing: [
                        if (state.customer.contacts.isNotEmpty)
                          _ContactsCard(customer: state.customer),
                        if (state.customer.productsPurchased.isNotEmpty)
                          _ProductMixCard(customer: state.customer),
                        _TimelineCard(state: state),
                      ],
                    ),
                  CustomerDetailError(:final message) => Center(
                      child: Text(message,
                          style: TextStyle(color: colors.textSecondary)),
                    ),
                  _ => Center(
                      child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary)),
                };
              },
            ),
          ),
        );
      },
    );
  }
}

/// Maps the SAP customer master onto the shared view model.
///
/// Unlike the visit stop — which has only a lean [CustomerStopInfo] projection
/// and falls back to placeholders — nearly every row here is real. Fields SAP
/// has not populated are passed as null so the shared layout drops the row
/// rather than printing "N/A" over a value a rep might act on.
OutletInfoViewData _viewData(Customer c) {
  final address = [c.address, c.district, c.province]
      .where((part) => part.trim().isNotEmpty)
      .join(', ');

  // Only meaningful once there is an order to divide by; showing $0 for a
  // customer who has never ordered reads as a real average of zero.
  final averageRevenue = c.totalOrders > 0
      ? '${_currencySymbol(c.currency)}${(c.lifetimeValue / c.totalOrders).toStringAsFixed(0)}'
      : null;

  return OutletInfoViewData(
    displayName: c.displayName,
    code: c.customerCode,
    // The ERP number where it exists, else the local code — a field-registered
    // customer has no SAP identity until HQ approves it.
    outletId: c.sapCustomerId ?? (c.customerCode.isEmpty ? null : c.customerCode),
    outletType: _blankToNull(c.customerGroup),
    outletTier: _blankToNull(c.priceGroup),
    // No SAP field maps to the visit flow's "Outlet Action" call plan.
    outletAction: null,
    contactPerson: _blankToNull(c.ownerName),
    assignedRep: _blankToNull(c.assignedRepName),
    phone: _blankToNull(c.phone),
    telegram: _blankToNull(c.whatsapp),
    email: _blankToNull(c.email),
    address: address.isEmpty ? null : address,
    taxNumber: _blankToNull(c.taxNumber),
    // hasCoordinates guards the (0,0) "no fix captured" encoding; passing the
    // pair through would put the shop in the Gulf of Guinea and offer a map
    // link to it.
    latitude: c.hasCoordinates ? c.latitude : null,
    longitude: c.hasCoordinates ? c.longitude : null,
    paymentStatus: c.status.name.isEmpty ? null : _statusLabel(c),
    creditLimit:
        '${_currencySymbol(c.currency)}${c.creditLimit.toStringAsFixed(0)}',
    // SAP payment terms are not synced to the device yet.
    paymentTerm: null,
    lifetimeValue:
        '${_currencySymbol(c.currency)}${c.lifetimeValue.toStringAsFixed(0)}',
    totalOrders: c.totalOrders > 0 ? '${c.totalOrders}' : null,
    averageRevenuePerOrder: averageRevenue,
    latestOrderDate:
        c.lastOrderDate == null ? null : _formatDate(c.lastOrderDate!),
    openOpportunities:
        c.openOpportunityCount > 0 ? '${c.openOpportunityCount}' : null,
    lastSynced: _formatDate(c.updatedAt),
    // Not synced for either source yet — the same demo counts the stop screen
    // shows, so the two detail screens stay identical. See
    // OutletPromotionSummary.placeholder.
    promotions: OutletPromotionSummary.placeholder,
  );
}

String _statusLabel(Customer c) {
  final available = c.availableCredit;
  final symbol = _currencySymbol(c.currency);
  return '${c.status.apiValue} · $symbol${available.toStringAsFixed(0)} available';
}

String? _blankToNull(String? value) =>
    (value == null || value.trim().isEmpty) ? null : value;

String _currencySymbol(String currency) => currency == 'USD' ? '\$' : '$currency ';

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

/// The customer's named contacts. Has no counterpart on a route stop, which
/// carries a single contact string — so it rides along as a trailing card in
/// the shared card shell rather than being forced into the shared row list.
class _ContactsCard extends StatelessWidget {
  const _ContactsCard({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return OutletCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutletSectionHeader(title: 'customers.contacts'.tr),
          Padding(
            padding: EdgeInsets.only(bottom: context.rh(10)),
            child: Column(
              children: [
                for (final contact in customer.contacts)
                  Padding(
                    padding: EdgeInsets.only(bottom: context.rh(8)),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: context.rr(16),
                          backgroundColor: colors.surfaceStrong,
                          child: Icon(Icons.person,
                              size: context.rr(16), color: scheme.primary),
                        ),
                        SizedBox(width: context.rw(10)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(contact.name,
                                  style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: context.rsp(13),
                                      fontWeight: FontWeight.w700)),
                              Text('${contact.role} · ${contact.phone}',
                                  style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: context.rsp(11.5))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Product lines this customer already buys.
class _ProductMixCard extends StatelessWidget {
  const _ProductMixCard({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final info = context.appColors.info;

    return OutletCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutletSectionHeader(title: 'customers.active_product_mix'.tr),
          Padding(
            padding: EdgeInsets.only(bottom: context.rh(10)),
            child: Wrap(
              spacing: context.rw(6),
              runSpacing: context.rh(6),
              children: [
                for (final product in customer.productsPurchased)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.rw(10),
                      vertical: context.rh(5),
                    ),
                    decoration: BoxDecoration(
                      color: info.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(context.rr(20)),
                    ),
                    child: Text(product,
                        style: TextStyle(
                            color: info,
                            fontSize: context.rsp(11),
                            fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Notes and activities, in the same card shell as the shared sections.
class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.state});

  final CustomerDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isEmpty = state.activities.isEmpty && state.notes.isEmpty;

    return OutletCard(
      padding: EdgeInsets.symmetric(
        horizontal: context.rr(16),
        vertical: context.rh(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutletSectionHeader(title: 'customers.timeline'.tr),
          if (isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: context.rh(10)),
              child: Text('customers.no_activity'.tr,
                  style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: context.rsp(12.5))),
            )
          else
            Padding(
              padding: EdgeInsets.only(bottom: context.rh(10)),
              child: Column(
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
      ),
    );
  }

  static IconData _iconFor(CustomerActivityType type) => switch (type) {
        CustomerActivityType.call => Icons.call_rounded,
        CustomerActivityType.whatsapp => Icons.chat_rounded,
        CustomerActivityType.visit => Icons.pin_drop_rounded,
        CustomerActivityType.note => Icons.note_rounded,
        CustomerActivityType.opportunityCreated => Icons.trending_up_rounded,
        CustomerActivityType.order => Icons.shopping_bag_rounded,
      };
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
          Icon(icon, size: context.rr(15), color: scheme.primary),
          SizedBox(width: context.rw(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: context.rsp(12.5),
                        fontWeight: FontWeight.w600)),
                Text(_formatDateTime(at),
                    style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: context.rsp(11))),
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
