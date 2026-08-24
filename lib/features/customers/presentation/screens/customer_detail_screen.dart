import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_text_context.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_content_frame.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_activity_type.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_detail_cubit.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_detail_state.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/app_bottom_sheet.dart';

const double _twoColumnMinWidth = 840;

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

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
      bool launched = await launchUrl(telegramTgUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        launched = await launchUrl(telegramWebUri, mode: LaunchMode.externalApplication);
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
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'common.add_note'.tr,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: context.rsp(16),
                  fontWeight: FontWeight.w800,
                ),
              ),
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
                    borderSide: BorderSide(color: colors.border),
                  ),
                ),
              ),
              SizedBox(height: context.rh(16)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<CustomerDetailCubit>().addNote(_noteController.text);
                    _noteController.clear();
                    Navigator.pop(sheetContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'customers.save_note'.tr,
                    style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w800),
                  ),
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
        final isTwoColumn = MediaQuery.sizeOf(context).width >= _twoColumnMinWidth;

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
                  onPressed: state is CustomerDetailLoaded ? () => _addNote(context) : null,
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: BlocBuilder<CustomerDetailCubit, CustomerDetailState>(
              builder: (context, state) {
                return switch (state) {
                  CustomerDetailLoaded() => ResponsiveContentFrame(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          context.pagePadding,
                          context.rh(12),
                          context.pagePadding,
                          context.rh(24),
                        ),
                        children: [
                          _HeroCard(customer: state.customer),
                          SizedBox(height: context.rh(16)),
                          if (isTwoColumn)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: _OutletDetailsCard(
                                    customer: state.customer,
                                    onPhoneTap: _openPhoneOrTelegram,
                                    onLocationTap: _openGoogleMaps,
                                  ),
                                ),
                                SizedBox(width: context.rw(16)),
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    children: [
                                      if (state.customer.contacts.isNotEmpty)
                                        _ContactsCard(customer: state.customer),
                                      if (state.customer.productsPurchased.isNotEmpty) ...[
                                        SizedBox(height: context.rh(16)),
                                        _ProductMixCard(customer: state.customer),
                                      ],
                                      SizedBox(height: context.rh(16)),
                                      _TimelineCard(state: state),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                _OutletDetailsCard(
                                  customer: state.customer,
                                  onPhoneTap: _openPhoneOrTelegram,
                                  onLocationTap: _openGoogleMaps,
                                ),
                                if (state.customer.contacts.isNotEmpty) ...[
                                  SizedBox(height: context.rh(14)),
                                  _ContactsCard(customer: state.customer),
                                ],
                                if (state.customer.productsPurchased.isNotEmpty) ...[
                                  SizedBox(height: context.rh(14)),
                                  _ProductMixCard(customer: state.customer),
                                ],
                                SizedBox(height: context.rh(14)),
                                _TimelineCard(state: state),
                              ],
                            ),
                        ],
                      ),
                    ),
                  CustomerDetailError(:final message) => Center(
                      child: Text(message, style: TextStyle(color: colors.textSecondary)),
                    ),
                  _ => Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                };
              },
            ),
          ),
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.customer});
  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(context.rr(16)),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(context.rr(16)),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: context.rr(52),
            height: context.rr(52),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(context.rr(12)),
            ),
            child: Icon(
              Icons.storefront_rounded,
              color: scheme.primary,
              size: context.rr(26),
            ),
          ),
          SizedBox(width: context.rw(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.localized(customer.displayName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: context.rsp(18),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: context.rh(4)),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.rw(6),
                        vertical: context.rh(2),
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(context.rr(6)),
                      ),
                      child: Text(
                        'CUS CODE',
                        style: TextStyle(
                          color: scheme.primary,
                          fontSize: context.rsp(10),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: context.rw(6)),
                    Expanded(
                      child: Text(
                        customer.customerCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: context.rsp(13),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutletDetailsCard extends StatelessWidget {
  const _OutletDetailsCard({
    required this.customer,
    required this.onPhoneTap,
    required this.onLocationTap,
  });

  final Customer customer;
  final Function(String) onPhoneTap;
  final Function(double, double) onLocationTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final address = [customer.address, customer.district, customer.province]
        .where((part) => part.trim().isNotEmpty)
        .join(', ');

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rr(16),
        vertical: context.rh(8),
      ),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(context.rr(16)),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Outlet Details & Location'),
          _InfoRow(
            icon: Icons.tag_rounded,
            label: 'Outlet ID (BP SAP)',
            value: customer.sapCustomerId ?? customer.customerCode,
          ),
          _InfoRow(
            icon: Icons.store_outlined,
            label: 'Outlet Type',
            value: (customer.customerGroup?.isNotEmpty ?? false)
                ? customer.customerGroup!
                : 'N/A',
          ),
          _InfoRow(
            icon: Icons.workspace_premium_outlined,
            label: 'Outlet Tier',
            value: (customer.priceGroup?.isNotEmpty ?? false)
                ? customer.priceGroup!
                : 'N/A',
          ),
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Owner / Contact Person (SAP)',
            value: (customer.ownerName?.isNotEmpty ?? false)
                ? customer.ownerName!
                : 'N/A',
          ),
          if (customer.phone.isNotEmpty)
            _InfoRow(
              icon: Icons.call_outlined,
              label: 'Phone Number (SAP)',
              value: customer.phone,
              onTap: () => onPhoneTap(customer.phone),
              actionWidget: _ActionIconButton(
                icon: Icons.phone_forwarded_rounded,
                color: Colors.green,
                onPressed: () => onPhoneTap(customer.phone),
              ),
            ),
          if (customer.whatsapp?.isNotEmpty ?? false)
            _InfoRow(
              icon: Icons.send_rounded,
              label: 'Telegram',
              value: customer.whatsapp!,
            ),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Address Line (SAP)',
            value: address.isNotEmpty ? address : 'N/A',
          ),
          if (customer.hasCoordinates)
            _InfoRow(
              icon: Icons.my_location_rounded,
              label: 'Lat & Long (SAP)',
              value: '${customer.latitude.toStringAsFixed(5)}, ${customer.longitude.toStringAsFixed(5)}',
              last: true,
              onTap: () => onLocationTap(customer.latitude, customer.longitude),
              actionWidget: _ActionIconButton(
                icon: Icons.map_rounded,
                color: Colors.blue,
                onPressed: () => onLocationTap(customer.latitude, customer.longitude),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.rh(10)),
      child: Text(
        title,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: context.rsp(14.5),
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

class _InfoRow extends StatefulWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
    this.actionWidget,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool last;
  final Widget? actionWidget;
  final VoidCallback? onTap;

  @override
  State<_InfoRow> createState() => _InfoRowState();
}

class _InfoRowState extends State<_InfoRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isInteractive = widget.onTap != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: isInteractive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: InkWell(
        onTap: widget.onTap != null
            ? () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              }
            : null,
        borderRadius: BorderRadius.circular(context.rr(10)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            vertical: context.rh(10),
            horizontal: _isHovered ? context.rw(8) : 0,
          ),
          decoration: BoxDecoration(
            color: _isHovered && isInteractive
                ? colors.border.withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(context.rr(10)),
            border: widget.last
                ? null
                : Border(
                    bottom: BorderSide(
                      color: colors.border,
                      width: 0.6,
                    ),
                  ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: _isHovered ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  widget.icon,
                  size: context.rr(20),
                  color: widget.onTap != null
                      ? Theme.of(context).colorScheme.primary
                      : colors.textSecondary,
                ),
              ),
              SizedBox(width: context.rw(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: context.rsp(11.5),
                      ),
                    ),
                    SizedBox(height: context.rh(2)),
                    Text(
                      widget.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: context.rsp(13.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.actionWidget != null) widget.actionWidget!,
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatefulWidget {
  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  State<_ActionIconButton> createState() => _ActionIconButtonState();
}

class _ActionIconButtonState extends State<_ActionIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: IconButton(
          icon: Icon(widget.icon, color: widget.color, size: context.rr(22)),
          constraints: BoxConstraints(
            minWidth: context.rr(40),
            minHeight: context.rr(40),
          ),
          padding: EdgeInsets.all(context.rr(8)),
          onPressed: () {
            HapticFeedback.lightImpact();
            widget.onPressed();
          },
        ),
      ),
    );
  }
}

class _ContactsCard extends StatelessWidget {
  const _ContactsCard({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rr(16),
        vertical: context.rh(8),
      ),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(context.rr(16)),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'customers.contacts'.tr),
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
                          child: Icon(Icons.person, size: context.rr(16), color: scheme.primary),
                        ),
                        SizedBox(width: context.rw(10)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact.name,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: context.rsp(13),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${contact.role} · ${contact.phone}',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: context.rsp(11.5),
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
          ),
        ],
      ),
    );
  }
}

class _ProductMixCard extends StatelessWidget {
  const _ProductMixCard({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final info = context.appColors.info;
    final colors = context.appColors;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rr(16),
        vertical: context.rh(8),
      ),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(context.rr(16)),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'customers.active_product_mix'.tr),
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
                    child: Text(
                      product,
                      style: TextStyle(
                        color: info,
                        fontSize: context.rsp(11),
                        fontWeight: FontWeight.w700,
                      ),
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

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.state});

  final CustomerDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isEmpty = state.activities.isEmpty && state.notes.isEmpty;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rr(16),
        vertical: context.rh(8),
      ),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(context.rr(16)),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'customers.timeline'.tr),
          if (isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: context.rh(10)),
              child: Text(
                'customers.no_activity'.tr,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: context.rsp(12.5),
                ),
              ),
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
                      at: activity.createdAt,
                    ),
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
  const _TimelineRow({
    required this.icon,
    required this.text,
    required this.at,
  });

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
                Text(
                  text,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: context.rsp(12.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatDateTime(at),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: context.rsp(11),
                  ),
                ),
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