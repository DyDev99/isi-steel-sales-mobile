import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gal/gal.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:isi_steel_sales_mobile/core/animations/page_transition.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_text_context.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_content_frame.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/utils/page_transitions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/geofence_service.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/active_route_bloc.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/location_tracking_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/active_route_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/location_tracking_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/navigation/end_visit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/stop_information/order_history_screen.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/stop_information/promotions_screen.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/stops_check_in_screen.dart';

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

  void _completeVisit(BuildContext context) {
    HapticFeedback.mediumImpact();
    unawaited(endVisitAndSync(context));
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
      bool launched = await launchUrl(telegramTgUri,
          mode: LaunchMode.externalApplication);
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

  @override
  Widget build(BuildContext context) => LocalizedBuilder(builder: _build);

  Widget _build(BuildContext context) {
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
          'Stop Information',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: context.rsp(17),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ResponsiveContentFrame(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.pagePadding,
                    vertical: context.rh(6),
                  ),
                  child: _HeroCard(
                    stop: stop,
                    onPhoneTap: _openPhoneOrTelegram,
                    onLocationTap: _openGoogleMaps,
                  ),
                ),
                SizedBox(height: context.rh(8)),
                Container(
                  margin: EdgeInsets.symmetric(
                      horizontal: context.pagePadding),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(context.rr(12)),
                    border: Border.all(color: colors.border),
                  ),
                  child: TabBar(
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: colors.textSecondary,
                    indicatorColor: Theme.of(context).colorScheme.primary,
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
                        stop: stop,
                        onPhoneTap: _openPhoneOrTelegram,
                        onLocationTap: _openGoogleMaps,
                      ),
                      _SalesTab(stop: stop),
                      _PromosTab(stop: stop),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _StopActionBar(
        stop: stop,
        bloc: _resolveBloc<ActiveRouteBloc>(context),
        onStart: () => _startVisit(context),
        onComplete: () => _completeVisit(context),
      ),
    );
  }
}

class _HeroCard extends StatefulWidget {
  const _HeroCard({
    required this.stop,
    required this.onPhoneTap,
    required this.onLocationTap,
  });

  final RouteStop stop;
  final Function(String) onPhoneTap;
  final Function(double, double) onLocationTap;

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
    final c = widget.stop.customer;
    final phoneNum = c.phone.isEmpty ? '026 407 480' : c.phone;

    LocationTrackingCubit? locationCubit;
    try {
      locationCubit = context.read<LocationTrackingCubit>();
    } catch (_) {}

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
                        context.localized(c.displayName),
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
                              label: 'Diamond',
                              color: scheme.primary.withValues(alpha: 0.12),
                              textColor: scheme.primary),
                          SizedBox(width: context.rw(6)),
                          if (locationCubit != null)
                            BlocBuilder<LocationTrackingCubit,
                                LocationTrackingState>(
                              bloc: locationCubit,
                              buildWhen: (a, b) => a.current != b.current,
                              builder: (context, state) {
                                final pos = state.current;
                                if (pos == null) return const SizedBox.shrink();
                                final dist = _formatDistance(
                                    GeofenceService.distanceMeters(
                                        pos.latitude,
                                        pos.longitude,
                                        c.latitude,
                                        c.longitude));
                                return _PillBadge(
                                  label: dist,
                                  color: Colors.green.shade100,
                                  textColor: Colors.green.shade900,
                                );
                              },
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
                  onTap: () => widget.onLocationTap(c.latitude, c.longitude),
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

  static String _formatDistance(double meters) {
    final km = meters / 1000;
    return km < 0.1 ? '${meters.round()} m' : '${km.toStringAsFixed(1)} km';
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
            horizontal: context.rw(16), vertical: context.rh(4)),
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
    final phoneNum = c.phone.isEmpty ? '026 407 480' : c.phone;

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
              _CompactTile(
                  icon: Icons.tag_rounded,
                  label: 'SAP ID',
                  value: c.code.isNotEmpty ? c.code : 'BP-884920'),
              const _CompactTile(
                  icon: Icons.store_outlined,
                  label: 'Outlet Type',
                  value: 'WHS / Retail'),
              const _CompactTile(
                  icon: Icons.alt_route_rounded,
                  label: 'Action Tag',
                  value: 'Attack'),
              _CompactTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Contact Person',
                  value: c.contact.isEmpty ? 'Yim Vithou' : c.contact),
              _CompactTile(
                icon: Icons.call_outlined,
                label: 'Phone Number',
                value: phoneNum,
                onTap: () => onPhoneTap(phoneNum),
              ),
              const _CompactTile(
                  icon: Icons.send_rounded,
                  label: 'Telegram',
                  value: '@phnom_penh_steel_outlet'),
              _CompactTile(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: c.address.isEmpty ? 'St. 218, Mean Chey' : c.address),
              _CompactTile(
                icon: Icons.my_location_rounded,
                label: 'Coordinates',
                value:
                    '${c.latitude.toStringAsFixed(4)}, ${c.longitude.toStringAsFixed(4)}',
                last: true,
                onTap: () => onLocationTap(c.latitude, c.longitude),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SalesTab extends StatelessWidget {
  const _SalesTab({required this.stop});
  final RouteStop stop;

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
              AppPageRoute<void>.sharedAxisVertical(
                builder: (_) => OrderHistoryScreen(
                  outletName: context.localized(stop.customer.displayName),
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
  const _PromosTab({required this.stop});
  final RouteStop stop;

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
              AppPageRoute<void>.sharedAxisVertical(
                builder: (_) => PromotionsScreen(
                  customerId: stop.customer.id,
                  outletName: context.localized(stop.customer.displayName),
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

class _StopActionBar extends StatelessWidget {
  const _StopActionBar({
    required this.stop,
    required this.bloc,
    required this.onStart,
    required this.onComplete,
  });

  final RouteStop stop;
  final ActiveRouteBloc bloc;
  final VoidCallback onStart;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActiveRouteBloc, ActiveRouteState>(
      bloc: bloc,
      builder: (context, state) => _bar(context, _liveStatus(state)),
    );
  }

  VisitStatus _liveStatus(ActiveRouteState state) {
    if (state is! ActiveRouteReady) return stop.status;
    for (final s in state.route.stops) {
      if (s.id == stop.id) return s.status;
    }
    return stop.status;
  }

  Widget _bar(BuildContext context, VisitStatus status) {
    if (status == VisitStatus.checkedOut || status == VisitStatus.missed) {
      return _Chrome(child: _DoneMarker(status: status));
    }

    if (status != VisitStatus.checkedIn) {
      return _Chrome(child: _PrimaryAction(onPressed: onStart));
    }

    return _Chrome(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PrimaryAction(
            onPressed: onStart,
            icon: Icons.arrow_forward_rounded,
            labelKey: 'my_visits.stop_info.start_visit',
          ),
          SizedBox(height: context.rh(8)),
          SizedBox(
            width: double.infinity,
            height: context.rh(44),
            child: OutlinedButton.icon(
              onPressed: onComplete,
              icon: Icon(Icons.stop_circle_rounded, size: context.rr(18)),
              label: Text(
                'my_visits.inventory.completion.complete_visit'.tr,
                style: TextStyle(
                  fontSize: context.rsp(13.5),
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .error
                      .withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.rr(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneMarker extends StatelessWidget {
  const _DoneMarker({required this.status});
  final VisitStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final done = status == VisitStatus.checkedOut;
    return SizedBox(
      height: context.rh(44),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.remove_circle_outline,
            size: context.rr(18),
            color: done ? colors.success : colors.textSecondary,
          ),
          SizedBox(width: context.rw(6)),
          Text(
            status.label,
            style: TextStyle(
              fontSize: context.rsp(13.5),
              fontWeight: FontWeight.w800,
              color: done ? colors.success : colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.onPressed,
    this.icon = Icons.play_arrow_rounded,
    this.labelKey = 'my_visits.stop_info.start_visit',
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String labelKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: context.rh(48),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: context.rr(20)),
        label: Text(
          labelKey.tr,
          style: TextStyle(
            fontSize: context.rsp(14.5),
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.rr(12)),
          ),
        ),
      ),
    );
  }
}

class _Chrome extends StatelessWidget {
  const _Chrome({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

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
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.pagePadding,
            context.rh(8),
            context.pagePadding,
            context.rh(8),
          ),
          child: child,
        ),
      ),
    );
  }
}