import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart'; // Optional: for saving to gallery

import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_text_context.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_content_frame.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/utils/page_transitions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/geofence_service.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/active_route_bloc.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/location_tracking_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/location_tracking_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/stops_check_in_screen.dart';

import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/stop_information/promotions_screen.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/stop_information/order_history_screen.dart';

const double _twoColumnMinWidth = 840;

class StopInformationScreen extends StatelessWidget {
  const StopInformationScreen({
    super.key,
    required this.stop,
    required this.index,
    required this.totalStops,
  });

  static const String routeName = 'stop_information';

  final RouteStop stop;
  final int index;
  final int totalStops;

  void _startVisit(BuildContext context) {
    HapticFeedback.mediumImpact();

    final ActiveRouteBloc activeRouteBloc =
        _resolveBloc<ActiveRouteBloc>(context);
    final VisitCubit visitCubit = _resolveBloc<VisitCubit>(context);
    final LocationTrackingCubit locationCubit =
        _resolveBloc<LocationTrackingCubit>(context);

    Navigator.of(context).push(
      slideLeftRoute(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: activeRouteBloc),
            BlocProvider.value(value: visitCubit),
            BlocProvider.value(value: locationCubit),
          ],
          child: RouteCheckInScreen(stop: stop),
        ),
      ),
    );
  }

  static T _resolveBloc<T extends StateStreamableSource<Object?>>(
      BuildContext context) {
    try {
      return context.read<T>();
    } catch (_) {
      return sl<T>();
    }
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
        await launchUrl(
          callUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      try {
        await launchUrl(
          callUri,
          mode: LaunchMode.externalApplication,
        );
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
      await launchUrl(
        googleMapsUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Could not launch Google Maps: $e');
    }
  }

  @override
  Widget build(BuildContext context) => LocalizedBuilder(builder: _build);

  Widget _build(BuildContext context) {
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
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: colors.textPrimary,
              size: context.rr(22),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit Outlet Info coming soon')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContentFrame(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              context.pagePadding,
              context.rh(12),
              context.pagePadding,
              context.rh(24),
            ),
            children: [
              _HeroCard(stop: stop),
              SizedBox(height: context.rh(16)),
              if (isTwoColumn)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _OutletInfoCard(
                        stop: stop,
                        onPhoneTap: (phone) => _openPhoneOrTelegram(phone),
                        onLocationTap: (lat, lng) => _openGoogleMaps(lat, lng),
                      ),
                    ),
                    SizedBox(width: context.rw(16)),
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          _PromoListCard(stop: stop),
                          SizedBox(height: context.rh(16)),
                          _SalesHistoryDetailCard(stop: stop),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _OutletInfoCard(
                      stop: stop,
                      onPhoneTap: (phone) => _openPhoneOrTelegram(phone),
                      onLocationTap: (lat, lng) => _openGoogleMaps(lat, lng),
                    ),
                    SizedBox(height: context.rh(14)),
                    _PromoListCard(stop: stop),
                    SizedBox(height: context.rh(14)),
                    _SalesHistoryDetailCard(stop: stop),
                  ],
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _StartVisitBar(onStart: () => _startVisit(context)),
    );
  }
}



class _HeroCard extends StatefulWidget {
  const _HeroCard({required this.stop});
  final RouteStop stop;

  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard> {
  final GlobalKey _cardKey = GlobalKey();

  Future<void> _captureCard() async {
    try {
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
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
    final c = widget.stop.customer;

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
              child: Text(
                context.localized(c.displayName),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: context.rsp(18),
                  fontWeight: FontWeight.w900,
                ),
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
              )
            
          ],
        ),
      ),
    );
  }
}
class _OutletInfoCard extends StatelessWidget {
  const _OutletInfoCard({
    required this.stop,
    required this.onPhoneTap,
    required this.onLocationTap,
  });

  final RouteStop stop;
  final Function(String) onPhoneTap;
  final Function(double, double) onLocationTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final c = stop.customer;

    LocationTrackingCubit? locationCubit;
    try {
      locationCubit = context.read<LocationTrackingCubit>();
    } catch (_) {}

    Widget buildCard(LocationTrackingState? locationState) {
      final pos = locationState?.current;
      final distanceLabel = pos == null
          ? null
          : _formatDistance(GeofenceService.distanceMeters(
              pos.latitude, pos.longitude, c.latitude, c.longitude));

      final phoneNum = c.phone.isEmpty ? '026 407 480' : c.phone;

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
              value: c.code.isNotEmpty ? c.code : 'BP-884920',
            ),
            const _InfoRow(
              icon: Icons.store_outlined,
              label: 'Outlet Type',
              value: 'WHS / Retail',
            ),
            const _InfoRow(
              icon: Icons.workspace_premium_outlined,
              label: 'Outlet Tier',
              value: 'Diamond',
            ),
            const _InfoRow(
              icon: Icons.alt_route_rounded,
              label: 'Outlet Action',
              value: 'Attack',
            ),
            _InfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Owner / Contact Person (SAP)',
              value: c.contact.isEmpty ? 'Yim Vithou' : c.contact,
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
            const _InfoRow(
              icon: Icons.send_rounded,
              label: 'Telegram',
              value: '@phnom_penh_steel_outlet',
            ),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Address Line (SAP)',
              value: c.address.isEmpty ? 'St. 218, Mean Chey' : c.address,
            ),
            _InfoRow(
              icon: Icons.my_location_rounded,
              label: 'Lat & Long (SAP)',
              value:
                  '${c.latitude.toStringAsFixed(5)}, ${c.longitude.toStringAsFixed(5)}',
              last: distanceLabel == null,
              onTap: () => onLocationTap(c.latitude, c.longitude),
              actionWidget: _ActionIconButton(
                icon: Icons.map_rounded,
                color: Colors.blue,
                onPressed: () => onLocationTap(c.latitude, c.longitude),
              ),
            ),
            if (distanceLabel != null)
              _InfoRow(
                icon: Icons.straighten_rounded,
                label: 'Distance',
                value: distanceLabel,
                last: true,
              ),
          ],
        ),
      );
    }

    if (locationCubit != null) {
      return BlocBuilder<LocationTrackingCubit, LocationTrackingState>(
        bloc: locationCubit,
        buildWhen: (a, b) => a.current != b.current,
        builder: (context, state) => buildCard(state),
      );
    }

    return buildCard(null);
  }

  static String _formatDistance(double meters) {
    final km = meters / 1000;
    return km < 0.1 ? '${meters.round()} m' : '${km.toStringAsFixed(1)} km';
  }
}

class _PromoListCard extends StatelessWidget {
  const _PromoListCard({required this.stop});

  final RouteStop stop;

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
                  outletName: context.localized(stop.customer.displayName),
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
                )
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

class _SalesHistoryDetailCard extends StatelessWidget {
  const _SalesHistoryDetailCard({required this.stop});

  final RouteStop stop;

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
                    outletName: context.localized(stop.customer.displayName),
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

class _StartVisitBar extends StatelessWidget {
  const _StartVisitBar({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(top: BorderSide(color: colors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.center,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: Breakpoints.contentMaxWidth,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                context.pagePadding,
                context.rh(12),
                context.pagePadding,
                context.rh(12),
              ),
              child: SizedBox(
                width: double.infinity,
                height: context.rh(52),
                child: ElevatedButton.icon(
                  onPressed: onStart,
                  icon: Icon(Icons.play_arrow_rounded, size: context.rr(22)),
                  label: Text(
                    'my_visits.stop_info.start_visit'.tr,
                    style: TextStyle(
                      fontSize: context.rsp(15),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.rr(14)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}