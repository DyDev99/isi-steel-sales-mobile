import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/utils/page_transitions.dart';
import 'package:isi_steel_sales_mobile/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/geofence_service.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/active_route_bloc.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/location_tracking_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/location_tracking_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/l10n/visit_labels.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/route_check_in_screen.dart';

/// Stop Information — the pre-check-in customer review step.
///
/// Single responsibility: let the rep review *who* they're about to visit
/// before committing to check-in. It renders entirely from the already-loaded
/// [RouteStop] (offline, instant — no fetch), and its **Start Visit** CTA hands
/// the *same* [ActiveRouteBloc]/[VisitCubit]/[LocationTrackingCubit] instances
/// to [RouteCheckInScreen] via `BlocProvider.value`, so check-in behaves
/// exactly as before. The selected stop is already persisted to the workflow
/// (`StopSelected` → `_persistWorkflow`) by the caller, so a force-close here
/// safely resumes to the route.
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
    final bloc = context.read<ActiveRouteBloc>();
    final visitCubit = context.read<VisitCubit>();
    final locationCubit = context.read<LocationTrackingCubit>();
    Navigator.of(context).push(slideLeftRoute(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider.value(value: visitCubit),
          BlocProvider.value(value: locationCubit),
        ],
        child: const RouteCheckInScreen(),
      ),
    ));
  }

  void _openProfile(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(MaterialPageRoute(
      settings: const RouteSettings(name: CustomerDetailScreen.routeName),
      builder: (_) => LocalizedBuilder(
        builder: (_) => CustomerDetailScreen(customerId: stop.customer.id),
      ),
    ));
  }

  void _comingSoon(BuildContext context) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('my_visits.route_info.action_coming_soon'.tr),
        duration: const Duration(seconds: 2),
      ));
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
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text('my_visits.stop_info.title'.tr,
            style: TextStyle(
                color: colors.textPrimary,
                fontSize: 17.sp,
                fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        top: false,
        child: _FadeIn(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 20.h),
            children: [
              _HeroCard(stop: stop, index: index, totalStops: totalStops),
              SizedBox(height: 14.h),
              _DetailsCard(stop: stop),
              SizedBox(height: 14.h),
              _QuickActions(
                onProfile: () => _openProfile(context),
                onComingSoon: () => _comingSoon(context),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _StartVisitBar(onStart: () => _startVisit(context)),
    );
  }
}

/// One-shot fade+slide entrance for the whole page — subtle, 60fps.
class _FadeIn extends StatefulWidget {
  const _FadeIn({required this.child});
  final Widget child;

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 320))
    ..forward();
  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final Animation<Offset> _slide =
      Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
          .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard(
      {required this.stop, required this.index, required this.totalStops});
  final RouteStop stop;
  final int index;
  final int totalStops;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final c = stop.customer;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46.w,
                height: 46.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(Icons.storefront_rounded,
                    color: scheme.primary, size: 24.w),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w900)),
                    SizedBox(height: 2.h),
                    Text(c.code,
                        style: TextStyle(
                            color: colors.textSecondary, fontSize: 12.5.sp)),
                  ],
                ),
              ),
              _StatusPill(label: stop.status.localizedLabel),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Icon(Icons.route_rounded,
                  size: 15.w, color: colors.textSecondary),
              SizedBox(width: 6.w),
              Text(
                'my_visits.stop_info.stop_of'
                    .trParams({'current': index + 1, 'total': totalStops}),
                style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(label,
          style: TextStyle(
              color: scheme.primary,
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w800)),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.stop});
  final RouteStop stop;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final c = stop.customer;
    return BlocBuilder<LocationTrackingCubit, LocationTrackingState>(
      buildWhen: (a, b) => a.current != b.current,
      builder: (context, locationState) {
        final pos = locationState.current;
        final distanceLabel = pos == null
            ? null
            : _formatDistance(GeofenceService.distanceMeters(
                pos.latitude, pos.longitude, c.latitude, c.longitude));
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'customers.address'.tr,
                  value: c.address),
              _InfoRow(
                  icon: Icons.person_outline_rounded,
                  label: 'my_visits.stop_info.contact_person'.tr,
                  value: c.contact.isEmpty ? '—' : c.contact),
              _InfoRow(
                  icon: Icons.call_outlined,
                  label: 'customers.phone'.tr,
                  value: c.phone.isEmpty ? '—' : c.phone),
              _InfoRow(
                  icon: Icons.map_outlined,
                  label: 'customers.territory'.tr,
                  value: c.territory.isEmpty
                      ? c.territoryType.localizedLabel
                      : c.territory),
              _InfoRow(
                  icon: Icons.my_location_rounded,
                  label: 'my_visits.stop_info.gps_location'.tr,
                  value:
                      '${c.latitude.toStringAsFixed(5)}, ${c.longitude.toStringAsFixed(5)}'),
              if (distanceLabel != null)
                _InfoRow(
                    icon: Icons.straighten_rounded,
                    label: 'my_visits.stop_info.distance'.tr,
                    value: distanceLabel,
                    last: true),
            ],
          ),
        );
      },
    );
  }

  static String _formatDistance(double meters) {
    final km = meters / 1000;
    return km < 0.1 ? '${meters.round()} m' : '${km.toStringAsFixed(1)} km';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: colors.border, width: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18.w, color: colors.textSecondary),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: colors.textSecondary, fontSize: 11.5.sp)),
                SizedBox(height: 2.h),
                Text(value,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onProfile, required this.onComingSoon});
  final VoidCallback onProfile;
  final VoidCallback onComingSoon;

  @override
  Widget build(BuildContext context) {
    final actions = <(IconData, String, VoidCallback)>[
      (
        Icons.person_rounded,
        'my_visits.stop_info.action_profile'.tr,
        onProfile
      ),
      (Icons.call_rounded, 'my_visits.stop_info.action_call'.tr, onComingSoon),
      (
        Icons.directions_rounded,
        'my_visits.stop_info.action_maps'.tr,
        onComingSoon
      ),
      (
        Icons.receipt_long_rounded,
        'my_visits.stop_info.action_orders'.tr,
        onComingSoon
      ),
      (
        Icons.history_rounded,
        'my_visits.stop_info.action_history'.tr,
        onComingSoon
      ),
    ];
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: [for (final a in actions) _ActionChip(a.$1, a.$2, a.$3)],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(14.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17.w, color: scheme.primary),
              SizedBox(width: 8.w),
              Text(label,
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600)),
            ],
          ),
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
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onStart,
            icon: Icon(Icons.play_arrow_rounded, size: 20.w),
            label: Text('my_visits.stop_info.start_visit'.tr,
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              padding: EdgeInsets.symmetric(vertical: 15.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r)),
            ),
          ),
        ),
      ),
    );
  }
}
