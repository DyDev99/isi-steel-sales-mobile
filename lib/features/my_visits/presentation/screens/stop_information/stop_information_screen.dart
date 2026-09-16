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
import 'package:isi_steel_sales_mobile/core/utils/money.dart';
import 'package:isi_steel_sales_mobile/features/depots/domain/entities/depot_stop_information.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/stop_information_cubit.dart';
import 'package:intl/intl.dart';

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
                  margin: EdgeInsets.symmetric(horizontal: context.pagePadding),
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
    final c = widget.stop.depot;
    // The route sync's phone, or nothing — never the constant that used to
    // stand in for it.
    final phoneNum = _orDash(c.phone.isEmpty ? null : c.phone);

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
                              textColor: scheme.primary,
                              isExample: true),
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
    final c = stop.depot;

    // The route sync gives a name, a pin and a geofence. Everything below
    // comes from `GET /mobile/depots/{id}/stop-information`, fetched when this
    // stop was opened — and falls back to the sync's copy, never to a
    // hardcoded example.
    final outlet = _stopInformationOf(context)?.outlet;

    final phoneNum = _orDash(outlet?.phone.isNotEmpty == true
        ? outlet!.phone
        : (c.phone.isEmpty ? null : c.phone));

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
                  value: _orDash(
                      outlet?.code.isNotEmpty == true ? outlet!.code : c.code)),
              // Never the route sync's `territoryType`: it collapses
              // Distributor and Wholesaler both onto `industrial`, so the
              // real value cannot be recovered from it.
              _CompactTile(
                  icon: Icons.store_outlined,
                  label: 'Outlet Type',
                  value: _orDash(outlet?.outletType)),
              // OBD-2: no assignment process for Attack / Defend / Maintain.
              const _CompactTile(
                  icon: Icons.alt_route_rounded,
                  label: 'Outlet Action',
                  value: 'Attack',
                  isExample: true),
              _CompactTile(
                icon: Icons.person_outline_rounded,
                label: 'Contact Person',
                // Null means nobody was recorded — said plainly, never filled
                // with a name the rep might ask for at the counter.
                value: outlet?.contact ??
                    (c.contact.isNotEmpty
                        ? c.contact
                        : 'my_visits.stop_info.not_recorded'.tr),
              ),
              _CompactTile(
                icon: Icons.call_outlined,
                label: 'Phone Number',
                value: phoneNum,
                onTap:
                    phoneNum == _kNoValue ? null : () => onPhoneTap(phoneNum),
              ),
              _CompactTile(
                  icon: Icons.send_rounded,
                  label: 'Telegram',
                  // Stored without the `@`; added only for display.
                  value: _orDash(outlet?.telegramHandle)),
              _CompactTile(
                  icon: Icons.location_on_outlined,
                  label: 'Address',
                  value: _orDash(outlet?.address.isNotEmpty == true
                      ? outlet!.address
                      : c.address)),
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

    final credit = _stopInformationOf(context)?.credit;

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
              // OBD-3: no invoice, due date or receivable exists anywhere, so
              // "Overdue" is uncomputable — this figure cannot be real yet.
              const _CompactTile(
                  icon: Icons.verified_user_outlined,
                  label: 'Payment Status',
                  value: 'Good Standing',
                  isExample: true),
              _CompactTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Credit Limit',
                  // Zero is a real answer here — cash-only trade — so it is
                  // rendered as \$0.00 rather than re-defaulted to a dash.
                  value: _money(credit?.creditLimit)),
              _CompactTile(
                  icon: Icons.account_balance_outlined,
                  label: 'Available Credit',
                  // Server-computed. Never limit − balance on the client: a
                  // client that subtracts can disagree with the server about
                  // an outlet's headroom.
                  value: _money(credit?.availableCredit)),
              _CompactTile(
                  icon: Icons.calendar_month_outlined,
                  label: 'Payment Term',
                  // Label, else the raw code — the server will not echo the
                  // code back as a label, so null means genuinely unresolved.
                  value: _orDash(credit?.paymentTermDisplay)),
              // OBD-6: undecided which quotation statuses count as a won order.
              const _CompactTile(
                  icon: Icons.trending_up_rounded,
                  label: 'Avg Rev per Order',
                  value: '\$12,500',
                  isExample: true),
              const _CompactTile(
                  icon: Icons.history_toggle_off_rounded,
                  label: 'Latest Order',
                  value: '12 Aug 2026',
                  isExample: true,
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
                  outletName: context.localized(stop.depot.displayName),
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
                  depotId: stop.depot.id,
                  outletName: context.localized(stop.depot.displayName),
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

/// The loaded outlet profile, or null when there is none *yet* — and also
/// when no [StopInformationCubit] was provided at all.
///
/// Tolerating an absent provider is deliberate. This cubit *enriches* the
/// screen; it does not constitute it. The route sync has already supplied the
/// name, pin and geofence, so a screen opened without the provider — a widget
/// test, or a future entry point that forgets it — must still render rather
/// than throw a `ProviderNotFoundException` at a rep standing outside a shop.
///
/// `watch`, so the tabs rebuild when the fetch lands.
DepotStopInformation? _stopInformationOf(BuildContext context) {
  try {
    final state = context.watch<StopInformationCubit>().state;
    return state is StopInformationReady ? state.information : null;
  } on Object {
    return null;
  }
}

/// Marks a value as an illustrative example rather than data.
class _ExampleChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rw(6),
        vertical: context.rh(1),
      ),
      decoration: BoxDecoration(
        color: colors.textSecondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        'my_visits.stop_info.example'.tr,
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: context.rsp(9),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// What to show when neither the stop-information call nor the route sync has
/// a value.
///
/// An em dash, never an invented one. The eight values this screen used to
/// hardcode are exactly why: a placeholder that looks like data is worse than
/// a blank, because a rep will read it out.
const String _kNoValue = '\u2014';

String _orDash(String? value) {
  final v = value?.trim();
  return (v == null || v.isEmpty) ? _kNoValue : v;
}

/// `$50,000` / `៛200,000`, from a `{amount, currency}` pair.
///
/// Rendering an amount without its currency is a 4000× error waiting to happen
/// in front of an outlet owner, so the currency is never dropped.
String _money(Money? money) {
  if (money == null) return _kNoValue;
  return NumberFormat.simpleCurrency(name: money.currency).format(money.amount);
}

class _CompactTile extends StatelessWidget {
  const _CompactTile({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
    this.onTap,
    this.isExample = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool last;
  final VoidCallback? onTap;

  /// Renders the value as a plainly-marked example rather than as data.
  ///
  /// Five figures on this screen have no source in any system yet — each is
  /// blocked on a business rule nobody has decided (OBD-1, -2, -3, -6). A rep
  /// quoting "\$50,000 credit limit" to an outlet owner from a constant is
  /// worse than showing nothing, so these are italic, muted and chipped: the
  /// chip is what lets a rep tell at a glance which figures are real.
  ///
  /// See `docs/feature/depot/mobile/backend-change-notice.md` §4.
  final bool isExample;

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
            if (isExample) ...[
              _ExampleChip(),
              SizedBox(width: context.rw(6)),
            ],
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isExample
                      ? colors.textSecondary
                      : onTap != null
                          ? Theme.of(context).colorScheme.primary
                          : colors.textPrimary,
                  fontSize: context.rsp(12.5),
                  fontWeight: isExample ? FontWeight.w500 : FontWeight.w700,
                  fontStyle: isExample ? FontStyle.italic : FontStyle.normal,
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
    this.isExample = false,
  });

  final String label;
  final Color color;
  final Color textColor;

  /// Renders the badge italic and muted and hangs an [_ExampleChip] beside it.
  ///
  /// Same treatment as `_CompactTile.isExample`, for the same reason: a rep
  /// must be able to tell at a glance which figures are real. See
  /// `docs/feature/depot/mobile/backend-change-notice.md` §4.
  final bool isExample;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.rw(8),
        vertical: context.rh(3),
      ),
      decoration: BoxDecoration(
        color: isExample ? color.withValues(alpha: 0.06) : color,
        borderRadius: BorderRadius.circular(context.rr(6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isExample ? context.appColors.textSecondary : textColor,
          fontSize: context.rsp(10.5),
          fontWeight: isExample ? FontWeight.w600 : FontWeight.w800,
          fontStyle: isExample ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
    if (!isExample) return badge;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        SizedBox(width: context.rw(4)),
        _ExampleChip(),
      ],
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
