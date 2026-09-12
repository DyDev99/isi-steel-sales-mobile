import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gal/gal.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_text_context.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_content_frame.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_detail_cubit.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_detail_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/stop_information/order_history_screen.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/stop_information/promotions_screen.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/app_bottom_sheet.dart';

const String _fallbackOutletId = 'BP-884920';
const String _fallbackOutletType = 'WHS / Retail';
const String _fallbackOutletTier = 'Diamond';
const String _fallbackOutletAction = 'Attack';
const String _fallbackOwnerName = 'Yim Vithou';
const String _fallbackPhone = '026 407 480';
const String _fallbackTelegram = '@phnom_penh_steel_outlet';
const String _fallbackAddress = 'St. 218, Mean Chey';
const double _fallbackLatitude = 11.55925;
const double _fallbackLongitude = 104.91601;

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
      bool launched =
          await launchUrl(telegramTgUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        launched = await launchUrl(telegramWebUri,
            mode: LaunchMode.externalApplication);
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
                  child: Text(
                    'customers.save_note'.tr,
                    style: TextStyle(
                        color: scheme.onPrimary, fontWeight: FontWeight.w800),
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

        return Scaffold(
          backgroundColor: colors.canvas,
          appBar: AppBar(
            backgroundColor: colors.canvas,
            elevation: 0,
            scrolledUnderElevation: 0,
            toolbarHeight: context.rh(52),
            iconTheme: IconThemeData(
              color: colors.textPrimary,
              size: context.rr(22),
            ),
            title: Text(
              'Outlet Details',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: context.rsp(17),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          body: SafeArea(
            child: BlocBuilder<CustomerDetailCubit, CustomerDetailState>(
              builder: (context, state) {
                return switch (state) {
                  CustomerDetailLoaded() => ResponsiveContentFrame(
                      child: DefaultTabController(
                        length: 3,
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.pagePadding,
                                vertical: context.rh(6),
                              ),
                              child: _HeroHeaderCard(
                                customer: state.customer,
                                onPhoneTap: _openPhoneOrTelegram,
                                onLocationTap: _openGoogleMaps,
                                onAddNoteTap: () => _addNote(context),
                              ),
                            ),
                            SizedBox(height: context.rh(8)),
                            Container(
                              margin: EdgeInsets.symmetric(
                                  horizontal: context.pagePadding),
                              decoration: BoxDecoration(
                                color: colors.card,
                                borderRadius:
                                    BorderRadius.circular(context.rr(12)),
                                border: Border.all(color: colors.border),
                              ),
                              child: TabBar(
                                labelColor:
                                    Theme.of(context).colorScheme.primary,
                                unselectedLabelColor: colors.textSecondary,
                                indicatorColor:
                                    Theme.of(context).colorScheme.primary,
                                indicatorSize: TabBarIndicatorSize.tab,
                                indicatorWeight: 3,
                                labelStyle: TextStyle(
                                  fontSize: context.rsp(13),
                                  fontWeight: FontWeight.w800,
                                ),
                                unselectedLabelStyle: TextStyle(
                                  fontSize: context.rsp(13),
                                  fontWeight: FontWeight.w600,
                                ),
                                tabs: const [
                                  Tab(text: 'Overview'),
                                  Tab(text: 'Sales'),
                                  Tab(text: 'Promos'),
                                ],
                              ),
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _OverviewTab(
                                    customer: state.customer,
                                    onPhoneTap: _openPhoneOrTelegram,
                                    onLocationTap: _openGoogleMaps,
                                  ),
                                  _SalesTab(customer: state.customer),
                                  _PromosTab(customer: state.customer),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  CustomerDetailError(:final message) => Center(
                      child: Text(message,
                          style: TextStyle(color: colors.textSecondary)),
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

class _HeroHeaderCard extends StatefulWidget {
  const _HeroHeaderCard({
    required this.customer,
    required this.onPhoneTap,
    required this.onLocationTap,
    required this.onAddNoteTap,
  });

  final Customer customer;
  final Function(String) onPhoneTap;
  final Function(double, double) onLocationTap;
  final VoidCallback onAddNoteTap;

  @override
  State<_HeroHeaderCard> createState() => _HeroHeaderCardState();
}

class _HeroHeaderCardState extends State<_HeroHeaderCard> {
  final GlobalKey _cardKey = GlobalKey();

  Future<void> _captureCard() async {
    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes != null) {
        await Gal.putImageBytes(pngBytes);
        if (!mounted) return;
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('my_visits.screenshot_saved'.tr),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture screenshot: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final customer = widget.customer;

    final phoneNum =
        customer.phone.isNotEmpty ? customer.phone : _fallbackPhone;
    final latitude =
        customer.hasCoordinates ? customer.latitude : _fallbackLatitude;
    final longitude =
        customer.hasCoordinates ? customer.longitude : _fallbackLongitude;
    final outletTier = (customer.priceGroup?.isNotEmpty ?? false)
        ? customer.priceGroup!
        : _fallbackOutletTier;

    return RepaintBoundary(
      key: _cardKey,
      child: Container(
        padding: EdgeInsets.all(context.rr(14)),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(context.rr(16)),
          border: Border.all(color: colors.border),
          boxShadow: colors.cardShadow,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: context.rr(44),
                  height: context.rr(44),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(context.rr(10)),
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    color: scheme.primary,
                    size: context.rr(22),
                  ),
                ),
                SizedBox(width: context.rw(12)),
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
                          fontSize: context.rsp(16),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: context.rh(2)),
                      Row(
                        children: [
                          _PillBadge(
                              label: outletTier,
                              color: scheme.primary.withValues(alpha: 0.12),
                              textColor: scheme.primary),
                          SizedBox(width: context.rw(6)),
                          Text(
                            customer.sapCustomerId?.isNotEmpty == true
                                ? customer.sapCustomerId!
                                : _fallbackOutletId,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: context.rsp(11),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: context.rh(12)),
            Divider(height: 1, color: colors.border.withValues(alpha: 0.5)),
            SizedBox(height: context.rh(8)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _QuickActionButton(
                  icon: Icons.call_rounded,
                  label: 'Call',
                  color: Colors.green,
                  onTap: () => widget.onPhoneTap(phoneNum),
                ),
                _QuickActionButton(
                  icon: Icons.directions_rounded,
                  label: 'Map',
                  color: Colors.blue,
                  onTap: () => widget.onLocationTap(latitude, longitude),
                ),
                _QuickActionButton(
                  icon: Icons.note_add_outlined,
                  label: 'Note',
                  color: scheme.primary,
                  onTap: widget.onAddNoteTap,
                ),
                _QuickActionButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Capture',
                  color: colors.textSecondary,
                  onTap: _captureCard,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(context.rr(8)),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: context.rw(10), vertical: context.rh(4)),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(context.rr(8)),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: context.rr(18)),
            ),
            SizedBox(height: context.rh(3)),
            Text(
              label,
              style: TextStyle(
                fontSize: context.rsp(11),
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
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

    final outletId = customer.sapCustomerId?.isNotEmpty == true
        ? customer.sapCustomerId!
        : (customer.customerCode.isNotEmpty
            ? customer.customerCode
            : _fallbackOutletId);
    final outletType = (customer.customerGroup?.isNotEmpty ?? false)
        ? customer.customerGroup!
        : _fallbackOutletType;
    final ownerName =
        customer.ownerName.isNotEmpty ? customer.ownerName : _fallbackOwnerName;
    final phoneNum =
        customer.phone.isNotEmpty ? customer.phone : _fallbackPhone;
    final telegram = (customer.whatsapp?.isNotEmpty ?? false)
        ? customer.whatsapp!
        : _fallbackTelegram;
    final addressLine = address.isNotEmpty ? address : _fallbackAddress;
    final latitude =
        customer.hasCoordinates ? customer.latitude : _fallbackLatitude;
    final longitude =
        customer.hasCoordinates ? customer.longitude : _fallbackLongitude;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.pagePadding,
        context.rh(12),
        context.pagePadding,
        context.rh(20),
      ),
      children: [
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: context.rr(14), vertical: context.rh(6)),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(context.rr(16)),
            border: Border.all(color: colors.border),
            boxShadow: colors.cardShadow,
          ),
          child: Column(
            children: [
              _CompactTile(icon: Icons.tag_rounded, label: 'SAP ID', value: outletId),
              _CompactTile(icon: Icons.store_outlined, label: 'Outlet Type', value: outletType),
              _CompactTile(icon: Icons.alt_route_rounded, label: 'Action Tag', value: _fallbackOutletAction),
              _CompactTile(icon: Icons.person_outline_rounded, label: 'Contact Person', value: ownerName),
              _CompactTile(
                icon: Icons.call_outlined,
                label: 'Phone Number',
                value: phoneNum,
                onTap: () => onPhoneTap(phoneNum),
              ),
              _CompactTile(icon: Icons.send_rounded, label: 'Telegram', value: telegram),
              _CompactTile(icon: Icons.location_on_outlined, label: 'Address', value: addressLine),
              _CompactTile(
                icon: Icons.my_location_rounded,
                label: 'Coordinates',
                value: '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
                last: true,
                onTap: () => onLocationTap(latitude, longitude),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SalesTab extends StatelessWidget {
  const _SalesTab({required this.customer});
  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.pagePadding,
        context.rh(12),
        context.pagePadding,
        context.rh(20),
      ),
      children: [
        Container(
          padding: EdgeInsets.all(context.rr(14)),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(context.rr(16)),
            border: Border.all(color: colors.border),
            boxShadow: colors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CompactTile(
                  icon: Icons.verified_user_outlined,
                  label: 'Payment Status',
                  value: 'Good Standing'),
              _CompactTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Credit Limit',
                  value: '\$50,000'),
              _CompactTile(
                  icon: Icons.calendar_month_outlined,
                  label: 'Payment Term',
                  value: '30 Days Net'),
              _CompactTile(
                  icon: Icons.trending_up_rounded,
                  label: 'Avg Rev per Order',
                  value: '\$12,500'),
              _CompactTile(
                  icon: Icons.history_toggle_off_rounded,
                  label: 'Latest Order',
                  value: '12 Aug 2026',
                  last: true),
            ],
          ),
        ),
        SizedBox(height: context.rh(12)),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OrderHistoryScreen(
                  outletName: context.localized(customer.displayName),
                ),
              ),
            );
          },
          icon: Icon(Icons.receipt_long_rounded, size: context.rr(18)),
          label: const Text('View Complete Order History'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: EdgeInsets.symmetric(vertical: context.rh(12)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.rr(12)),
            ),
          ),
        ),
      ],
    );
  }
}

class _PromosTab extends StatelessWidget {
  const _PromosTab({required this.customer});
  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.pagePadding,
        context.rh(12),
        context.pagePadding,
        context.rh(20),
      ),
      children: [
        Container(
          padding: EdgeInsets.all(context.rr(16)),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(context.rr(16)),
            border: Border.all(color: colors.border),
            boxShadow: colors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Promotions',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: context.rsp(15),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  _PillBadge(
                      label: '25 Available',
                      color: Colors.amber.shade100,
                      textColor: Colors.amber.shade900),
                ],
              ),
              SizedBox(height: context.rh(14)),
              Wrap(
                spacing: context.rw(8),
                runSpacing: context.rh(8),
                children: [
                  _PillBadge(
                      label: 'ON-INVOICE (20)',
                      color: Colors.blue.shade100,
                      textColor: Colors.blue.shade900),
                  _PillBadge(
                      label: 'OFF-INVOICE (0)',
                      color: Colors.grey.shade200,
                      textColor: Colors.grey.shade700),
                  _PillBadge(
                      label: 'CONTRACT (5)',
                      color: Colors.teal.shade100,
                      textColor: Colors.teal.shade900),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: context.rh(12)),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PromotionsScreen(
                  customerId: customer.id,
                  outletName: context.localized(customer.displayName),
                ),
              ),
            );
          },
          icon: Icon(Icons.local_offer_outlined, size: context.rr(18)),
          label: const Text('Browse All Promotions'),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: context.rh(12)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.rr(12)),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactTile extends StatelessWidget {
  const _CompactTile({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool last;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return InkWell(
      onTap: onTap != null
          ? () {
              HapticFeedback.selectionClick();
              onTap!();
            }
          : null,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: context.rh(9)),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: colors.border, width: 0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, size: context.rr(18), color: colors.textSecondary),
            SizedBox(width: context.rw(10)),
            Text(
              label,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: context.rsp(12),
              ),
            ),
            SizedBox(width: context.rw(10)),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: onTap != null
                      ? Theme.of(context).colorScheme.primary
                      : colors.textPrimary,
                  fontSize: context.rsp(12.5),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (onTap != null) ...[
              SizedBox(width: context.rw(4)),
              Icon(Icons.chevron_right_rounded,
                  size: context.rr(16), color: colors.textSecondary),
            ],
          ],
        ),
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  const _PillBadge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rw(8),
        vertical: context.rh(3),
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(context.rr(6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: context.rsp(10.5),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}