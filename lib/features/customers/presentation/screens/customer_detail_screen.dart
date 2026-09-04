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
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_activity_type.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_detail_cubit.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/bloc/customer_detail_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/stop_information/order_history_screen.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/stop_information/promotions_screen.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/app_bottom_sheet.dart';

const double _twoColumnMinWidth = 840;

// Static fallback values used whenever real customer data is missing,
// mirroring the pattern used in StopInformationScreen.
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
        final isTwoColumn =
            MediaQuery.sizeOf(context).width >= _twoColumnMinWidth;

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
                                      _PromoListCard(customer: state.customer),
                                      SizedBox(height: context.rh(16)),
                                      _SalesHistoryDetailCard(
                                          customer: state.customer),
                                      SizedBox(height: context.rh(40)),
                                  
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
                                SizedBox(height: context.rh(14)),
                                _PromoListCard(customer: state.customer),
                                SizedBox(height: context.rh(14)),
                                _SalesHistoryDetailCard(
                                    customer: state.customer),
                                SizedBox(height: context.rh(40)),
                              ],
                            ),
                        ],
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

/// Hero header card. Mirrors StopInformationScreen's hero: it wraps the
/// content in a RepaintBoundary so the outlet card can be captured as an
/// image and saved to the gallery via the camera action.
class _HeroCard extends StatefulWidget {
  const _HeroCard({required this.customer});
  final Customer customer;

  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard> {
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

    return RepaintBoundary(
      key: _cardKey,
      child: Container(
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
                  
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.camera_alt_outlined,
                color: colors.textSecondary,
                size: context.rr(22),
              ),
              tooltip: 'my_visits.screenshot'.tr,
              onPressed: _captureCard,
            ),
          ],
        ),
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

    final outletId = customer.sapCustomerId?.isNotEmpty == true
        ? customer.sapCustomerId!
        : (customer.customerCode.isNotEmpty
            ? customer.customerCode
            : _fallbackOutletId);
    final outletType = (customer.customerGroup?.isNotEmpty ?? false)
        ? customer.customerGroup!
        : _fallbackOutletType;
    final outletTier = (customer.priceGroup?.isNotEmpty ?? false)
        ? customer.priceGroup!
        : _fallbackOutletTier;
    final ownerName =
        customer.ownerName.isNotEmpty ? customer.ownerName : _fallbackOwnerName;
    final phoneNum = customer.phone.isNotEmpty ? customer.phone : _fallbackPhone;
    final telegram = (customer.whatsapp?.isNotEmpty ?? false)
        ? customer.whatsapp!
        : _fallbackTelegram;
    final addressLine = address.isNotEmpty ? address : _fallbackAddress;
    final latitude = customer.hasCoordinates ? customer.latitude : _fallbackLatitude;
    final longitude =
        customer.hasCoordinates ? customer.longitude : _fallbackLongitude;

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
            value: outletId,
          ),
          _InfoRow(
            icon: Icons.store_outlined,
            label: 'Outlet Type',
            value: outletType,
          ),
          _InfoRow(
            icon: Icons.workspace_premium_outlined,
            label: 'Outlet Tier',
            value: outletTier,
          ),
          const _InfoRow(
            icon: Icons.alt_route_rounded,
            label: 'Outlet Action',
            value: _fallbackOutletAction,
          ),
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Owner / Contact Person (SAP)',
            value: ownerName,
          ),
          _InfoRow(
            icon: Icons.call_outlined,
            label: 'Phone Number (SAP)',
            value: phoneNum,
            onTap: () => onPhoneTap(phoneNum),
            actionWidget: _ActionIconButton(
              icon: Icons.phone_forwarded_rounded,
              color: Colors.green,
              onPressed: () => onPhoneTap(phoneNum),
            ),
          ),
          _InfoRow(
            icon: Icons.send_rounded,
            label: 'Telegram',
            value: telegram,
          ),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Address Line (SAP)',
            value: addressLine,
          ),
          _InfoRow(
            icon: Icons.my_location_rounded,
            label: 'Lat & Long (SAP)',
            value:
                '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
            last: true,
            onTap: () => onLocationTap(latitude, longitude),
            actionWidget: _ActionIconButton(
              icon: Icons.map_rounded,
              color: Colors.blue,
              onPressed: () => onLocationTap(latitude, longitude),
            ),
          ),
        ],
      ),
    );
  }
}

/// Promotions summary card — same layout, badges and navigation pattern as
/// StopInformationScreen's promo card. Customer entity has no promo data
/// yet, so the counts are static placeholders until that data is wired up.
class _PromoListCard extends StatelessWidget {
  const _PromoListCard({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(context.rr(16)),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(context.rr(16)),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PromotionsScreen(
                  outletName: context.localized(customer.displayName),
                ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(context.rr(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Icon(Icons.local_offer_outlined,
                              size: context.rr(20), color: colors.textPrimary),
                          SizedBox(width: context.rw(8)),
                          Flexible(
                            child: Text(
                              'Promotions',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: context.rsp(15),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          SizedBox(width: context.rw(8)),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.rw(8),
                              vertical: context.rh(2),
                            ),
                            decoration: BoxDecoration(
                              color: colors.border,
                              borderRadius:
                                  BorderRadius.circular(context.rr(10)),
                            ),
                            child: Text(
                              '25',
                              style: TextStyle(
                                fontSize: context.rsp(11),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: context.rr(24),
                      color: colors.textSecondary,
                    ),
                  ],
                ),
                SizedBox(height: context.rh(14)),
                Wrap(
                  spacing: context.rw(8),
                  runSpacing: context.rh(8),
                  children: [
                    _PromoBadge(
                        label: 'ON-INVOICE (20)',
                        color: Colors.blue.shade100,
                        textColor: Colors.blue.shade900),
                    _PromoBadge(
                        label: 'OFF-INVOICE (0)',
                        color: Colors.grey.shade200,
                        textColor: Colors.grey.shade700),
                    _PromoBadge(
                        label: 'CONTRACT (5)',
                        color: Colors.teal.shade100,
                        textColor: Colors.teal.shade900),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PromoBadge extends StatelessWidget {
  const _PromoBadge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.symmetric(
        horizontal: context.rw(12),
        vertical: context.rh(6),
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(context.rr(8)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: context.rsp(11),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Sales history card mirroring StopInformationScreen's static financial
/// summary, with the same "Order History" navigation entry point.
class _SalesHistoryDetailCard extends StatelessWidget {
  const _SalesHistoryDetailCard({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
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
          const _SectionHeader(title: 'Sales History Detail'),
          const _InfoRow(
            icon: Icons.verified_user_outlined,
            label: 'Payment/Credit Status',
            value: 'Good Standing',
          ),
          const _InfoRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Credit Limit (SAP)',
            value: '\$50,000',
          ),
          const _InfoRow(
            icon: Icons.calendar_month_outlined,
            label: 'Payment Term (SAP)',
            value: '30 Days Net',
          ),
          const _InfoRow(
            icon: Icons.trending_up_rounded,
            label: 'Avg Rev per Order',
            value: '\$12,500',
          ),
          const _InfoRow(
            icon: Icons.history_toggle_off_rounded,
            label: 'Latest Order Date (SAP)',
            value: '12 Aug 2026',
          ),
          _InfoRow(
            icon: Icons.receipt_long_rounded,
            label: 'Order History (SAP)',
            value: 'Tap to view outlet orders history',
            last: true,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OrderHistoryScreen(
                    outletName: context.localized(customer.displayName),
                  ),
                ),
              );
            },
            actionWidget: Icon(
              Icons.arrow_forward_ios_rounded,
              size: context.rr(14),
              color: colors.textSecondary,
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

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.value));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied "${widget.value}" to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isInteractive = widget.onTap != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: widget.onTap != null
            ? () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              }
            : () => _copyToClipboard(context),
        onLongPress: () => _copyToClipboard(context),
        borderRadius: BorderRadius.circular(context.rr(10)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            vertical: context.rh(10),
            horizontal: _isHovered ? context.rw(8) : 0,
          ),
          decoration: BoxDecoration(
            color: _isHovered
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
                  color: isInteractive
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionIconButton(
                    icon: Icons.copy_rounded,
                    color: colors.textSecondary,
                    onPressed: () => _copyToClipboard(context),
                  ),
                  if (widget.actionWidget != null) widget.actionWidget!,
                ],
              ),
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
          icon: Icon(widget.icon, color: widget.color, size: context.rr(20)),
          constraints: BoxConstraints(
            minWidth: context.rr(36),
            minHeight: context.rr(36),
          ),
          padding: EdgeInsets.all(context.rr(6)),
          onPressed: () {
            HapticFeedback.lightImpact();
            widget.onPressed();
          },
        ),
      ),
    );
  }
}
