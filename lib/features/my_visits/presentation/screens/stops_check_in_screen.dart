import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_text_context.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/platform/local_files.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/core/utils/offline_banner.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/fraud_policy.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/location_sample.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_photo.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/proof_photo_service.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/active_route_bloc.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/location_tracking_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/visit_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/events/active_route_event.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/active_route_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/location_tracking_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/visit_state.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/navigation/open_inventory_visibility.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/stop_information/stop_information_screen.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/check_in_location_verifier.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/outlet_location_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/models/check_in_gps_phase.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/check_in_confirmation_dialog.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/remote_check_in_sheet.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/widgets/transit_map.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/painters/dashed_rrect.dart';

/// Forces the geo-status banner to read "inside geofence" regardless of the
/// real verdict.
///
/// **Now false, and it should stay false.** It was `true`, and it was OR'd
/// into the *banner* only — the bloc read `state.insideGeofence` directly and
/// never saw it. So the screen showed green while the bloc refused the
/// check-in, which is why this failed silently for so long: the one indicator
/// a rep could see was wired to a constant.
///
/// Nothing depends on it any more. A device with no fix, or a shop with no
/// recorded pin, now checks in and records itself unverified
/// (`ActiveRouteBloc._onCheckIn`) instead of needing the banner to lie on its
/// behalf.
const bool kDebugForceInsideGeofence = false;

class RouteCheckInScreen extends StatefulWidget {
  const RouteCheckInScreen({
    super.key,
    this.stop,
  });

  final RouteStop? stop;

  @override
  State<RouteCheckInScreen> createState() => _RouteCheckInScreenState();
}

class _RouteCheckInScreenState extends State<RouteCheckInScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _capturing = false;

  /// True between dispatching `CheckInRequested` and the bloc answering.
  /// Drives the CTA's spinner and gates `_onCheckInSettled`, so a state change
  /// caused by anything else (a GPS fix, a photo) cannot navigate on its own.
  bool _submitting = false;

  /// The bloc's `checkInAttempt` when this screen dispatched. The answer is
  /// the first state whose counter is higher — never "any state change",
  /// which a GPS update would also be.
  int? _awaitingAttempt;

  /// Releases the spinner if the bloc never answers (not loaded, a handler
  /// still busy with an earlier attempt). Nothing on this screen may spin
  /// forever.
  Timer? _submitWatchdog;
  static const Duration _submitTimeout = Duration(seconds: 15);

  /// Drives the staggered entrance: header → map → action board → CTA, each
  /// fading and rising on its own slice of one timeline.
  late AnimationController _entranceController;

  /// The stop this screen is checking in to — the widget's own, or the bloc's
  /// current one when opened without it.
  RouteStop? _currentStop([ActiveRouteState? state]) {
    final s = state ?? _resolveBloc<ActiveRouteBloc>(context).state;
    return widget.stop ??
        ((s is ActiveRouteReady && s.hasCurrentStop)
            ? s.route.stops[s.currentStopIndex]
            : null);
  }

  /// Recomputes the verdict for the selected stop and hands it to the bloc.
  ///
  /// **Now the same verdict the dialog shows.** This used to run
  /// `GeofenceService.evaluate` against the *customer's* pin and territory
  /// radius (urban 50 m), while the dialog ran `CheckInLocationVerifier`
  /// against the outlet source (demo pin, 100 m). Two rules, two pins: the
  /// dialog could say "within" and the bloc then refuse "outside the
  /// geofence". Both now come from [_readLocation].
  void _reportGeofence(
      ActiveRouteBloc bloc, LocationTrackingState locationState) {
    final stop = _currentStop(bloc.state);
    if (stop == null) return;

    final reading = _readLocation(stop, locationState);
    final verdict = reading.verdict;
    final sample = locationState.usableFix();

    final double? latitude = kUseStaticCheckInPosition
        ? kStaticCheckInPosition.latitude
        : sample?.latitude;
    final double? longitude = kUseStaticCheckInPosition
        ? kStaticCheckInPosition.longitude
        : sample?.longitude;
    // Nothing measured yet: say nothing. The bloc treats "no fix" as its own
    // case (unverified), and inventing one here would erase that distinction.
    if (latitude == null || longitude == null) return;

    bloc.add(GeofenceStatusChanged(
      insideGeofence: verdict.isWithinRadius,
      // NaN when the outlet has no pin. Sent as 0 with
      // `customerLocationKnown: false` beside it rather than as NaN, which
      // would poison `distanceFromCustomer` on the pushed row — the field is a
      // number the server reads, and NaN is not one.
      distanceMeters: verdict.isMeasurable ? verdict.distanceMeters : 0,
      accuracyMeters: reading.accuracyMeters,
      isMocked: kUseStaticCheckInPosition ? false : (sample?.isMocked ?? false),
      latitude: latitude,
      longitude: longitude,
      customerLocationKnown: verdict.hasOutletLocation,
    ));
  }

  /// The id of the stop this screen checks in to.
  String? get _stopId => widget.stop?.id ?? _currentStop()?.id;

  /// The bloc's own, *live* copy of that stop — its status is current, unlike
  /// `widget.stop`, which is the snapshot the screen was opened with.
  static RouteStop? _liveStop(ActiveRouteState state, String? stopId) {
    if (state is! ActiveRouteReady || stopId == null) return null;
    for (final s in state.route.stops) {
      if (s.id == stopId) return s;
    }
    return null;
  }

  static bool _isCheckedIn(RouteStop? stop) =>
      stop != null &&
      (stop.status == VisitStatus.checkedIn ||
          stop.status == VisitStatus.checkedOut);

  /// Marks the start of a check-in attempt: spinner on, answer awaited,
  /// watchdog armed.
  void _beginSubmit(ActiveRouteBloc bloc) {
    final state = bloc.state;
    _awaitingAttempt = state is ActiveRouteReady ? state.checkInAttempt : -1;
    _submitWatchdog?.cancel();
    _submitWatchdog = Timer(_submitTimeout, _onSubmitTimeout);
    setState(() => _submitting = true);
  }

  void _endSubmit() {
    _submitWatchdog?.cancel();
    _submitWatchdog = null;
    _awaitingAttempt = null;
    if (mounted) setState(() => _submitting = false);
  }

  void _onSubmitTimeout() {
    if (!mounted || !_submitting) return;
    _endSubmit();
    final bloc = _resolveBloc<ActiveRouteBloc>(context);
    final live = _liveStop(bloc.state, _stopId);
    // It may have landed after all — the answer was just not seen.
    if (_isCheckedIn(live)) {
      _goToVisit(context, live!);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // TODO(i18n)
        content: const Text(
            'Check-in did not respond. Please check your connection and try again.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Advances only once the check-in has actually landed.
  ///
  /// Keyed on `checkInAttempt`, not on "the state changed": a refusal with the
  /// same reason as last time, or a stop that was already checked in, used to
  /// produce no new state at all — and the spinner never stopped. Every
  /// attempt now bumps the counter, so every attempt is answered.
  void _onCheckInSettled(BuildContext context, ActiveRouteState state) {
    final awaiting = _awaitingAttempt;
    if (!_submitting || awaiting == null || state is! ActiveRouteReady) return;
    if (state.checkInAttempt <= awaiting) return;

    _endSubmit();

    final live = _liveStop(state, _stopId);
    if (_isCheckedIn(live)) {
      _goToVisit(context, live!);
      return;
    }

    // Some blocks a rep can answer for — a depot gate far from the office
    // pin, a warehouse with no sky. Those get the reason sheet. The rest
    // (mock location, VPN, a failed save) only get the banner, which already
    // renders `blockedCheckInReason` in place.
    if (state.blockedCheckInReason != null && state.checkInOverridable) {
      unawaited(_offerOverride(context, state));
    }
  }

  /// Offers the reasoned override, and re-runs check-in with what the rep
  /// wrote.
  ///
  /// The reason rides on the check-in row itself (`CheckInRecord.overrideReason`
  /// → `overrideReason` on the wire), not as a separate `VisitNote`. Two rows
  /// would mean the verdict and its explanation live in different tables, and a
  /// reviewer asking "which overrides happened and why" would be joining a
  /// flagged check-in to free text somebody hoped was there. One row cannot come
  /// apart.
  Future<void> _offerOverride(
      BuildContext context, ActiveRouteReady state) async {
    final reason = await RemoteCheckInSheet.show(
      context,
      blockedReason: state.blockedCheckInReason ?? '',
      distanceMeters: state.distanceMeters,
      minLength: const FraudPolicy().minOverrideReasonLength,
    );
    if (reason == null || !mounted) return;

    // `this.context`, not the parameter. `mounted` is the State's flag, so it
    // only vouches for the State's own context — reading the passed-in one
    // after an await is guarded by something unrelated to it, which is exactly
    // what `use_build_context_synchronously` is pointing at. They are the same
    // element in practice today; using the one the guard covers keeps that
    // true if a caller ever passes a context from a subtree that can go away
    // while the sheet is open.
    final bloc = _resolveBloc<ActiveRouteBloc>(this.context);
    _beginSubmit(bloc);
    bloc.add(CheckInRequested(overrideReason: reason, stopId: _stopId));
  }

  /// Helper to safely obtain BLoC/Cubit instances from BuildContext or Service Locator
  static T _resolveBloc<T extends StateStreamableSource<Object?>>(
      BuildContext context) {
    try {
      return context.read<T>();
    } catch (_) {
      return sl<T>();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );

    final initialStop = widget.stop;
    if (initialStop != null) {
      _resolveBloc<VisitCubit>(context).load(initialStop.id);
      // Without this the bloc never learns which stop this is, and every
      // check-in from this entry point is silently discarded.
      unawaited(_ensureStopSelected(initialStop));
    } else {
      final activeRouteBloc = _resolveBloc<ActiveRouteBloc>(context);
      final state = activeRouteBloc.state;
      if (state is ActiveRouteReady && state.hasCurrentStop) {
        _resolveBloc<VisitCubit>(context)
            .load(state.route.stops[state.currentStopIndex].id);
      }
    }

    // Start reading the GPS. Nothing else does.
    //
    // This screen used to assume the tracker "is started well before this
    // screen opens" — nothing ever called `start` or `observeForScreen`, so
    // `LocationTrackingState.current` was permanently null. The consequence was
    // quiet and total: `_reportGeofence` returned early on every sample, so
    // `GeofenceStatusChanged` was never dispatched, `insideGeofence` kept its
    // optimistic default, and the check-in that claims to verify where a rep is
    // standing never read the device at all.
    //
    // Screen-scoped (`observeForScreen`), not the route stream: this needs a
    // position while the rep is looking at the screen, and a foreground service
    // with a persistent notification is not the right price for that. A running
    // route's own `start` is independent and unaffected.
    unawaited(_beginObservingLocation());

    _entranceController.forward();
  }

  /// Begins the screen-scoped position stream and seeds the geofence verdict
  /// from whatever fix already exists.
  ///
  /// The seed matters even once observation is running: the listener fires on
  /// *change*, and a stationary device may not produce one for seconds — or at
  /// all. Without it the bloc sits on the `insideGeofence: false` that
  /// `_onStopSelected` wrote and the first check-in is refused for no reason
  /// the rep can see.
  /// Puts the bloc into the state the check-in actually needs.
  ///
  /// `ActiveRouteBloc` refuses `CheckInRequested` unless it is
  /// `ActiveRouteReady` **with a stop selected** — and until now nothing on
  /// this path put it there. `ActiveRouteLoadRequested` was dispatched only
  /// from the legacy `Static.myVisits` route, and `StopSelected` was dispatched
  /// *nowhere at all*: only its handler existed.
  ///
  /// The result was a check-in that silently did nothing. `_onCheckIn` returned
  /// on its first guard so no row was written, and `_onCheckInSettled` returned
  /// on the same guard so `_submitting` was never cleared — the CTA span
  /// forever while the screen looked entirely healthy, because every *display*
  /// path falls back to `widget.stop` and so never needed the bloc.
  Future<void> _ensureStopSelected(RouteStop stop) async {
    final bloc = _resolveBloc<ActiveRouteBloc>(context);

    var state = bloc.state;
    if (state is! ActiveRouteReady || state.route.id != stop.routeId) {
      bloc.add(ActiveRouteLoadRequested(stop.routeId));
      try {
        state = await bloc.stream
            .firstWhere(
                (s) => s is ActiveRouteReady && s.route.id == stop.routeId)
            // Bounded: a route that never loads must leave the CTA disabled
            // rather than hang this future for the life of the screen.
            .timeout(const Duration(seconds: 10));
      } on TimeoutException {
        return;
      }
    }
    if (!mounted || state is! ActiveRouteReady) return;

    final index = state.route.stops.indexWhere((s) => s.id == stop.id);
    if (index >= 0 && state.currentStopIndex != index) {
      bloc.add(StopSelected(index));
    }
  }

  Future<void> _beginObservingLocation() async {
    final locationCubit = _resolveBloc<LocationTrackingCubit>(context);

    _reportGeofence(
        _resolveBloc<ActiveRouteBloc>(context), locationCubit.state);

    // A 10 m filter: the check-in radius is 100 m, so a rep walking the last
    // few metres to a shopfront needs to see the distance move. The dashboard's
    // 25 m default would hold a stale reading right where it matters most.
    await locationCubit.observeForScreen(distanceFilterMeters: 10);
    if (!mounted) return;

    // Re-seed once a real fix lands: the state read above was almost certainly
    // still empty.
    _reportGeofence(
        _resolveBloc<ActiveRouteBloc>(context), locationCubit.state);
  }

  @override
  void dispose() {
    // Released here rather than left running: the position was for this screen.
    // A route-scoped `start` is a separate subscription and keeps going.
    WidgetsBinding.instance.removeObserver(this);
    _submitWatchdog?.cancel();
    unawaited(_resolveBloc<LocationTrackingCubit>(context).stopObserving());
    _entranceController.dispose();
    super.dispose();
  }

  /// Coming back from system Settings (Location switched on, permission
  /// granted) re-runs the search on its own. Without this the rep fixes the
  /// setting, returns, and the screen still says Location is off.
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle != AppLifecycleState.resumed || !mounted) return;
    final cubit = _resolveBloc<LocationTrackingCubit>(context);
    final status = cubit.state.fixStatus;
    if (status == GpsFixStatus.servicesDisabled ||
        status == GpsFixStatus.permissionDenied ||
        status == GpsFixStatus.permissionDeniedForever ||
        status == GpsFixStatus.unavailable) {
      unawaited(cubit.retryFix());
    }
  }

  Future<void> _capture(RouteStop stop) async {
    if (_capturing) return;

    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    final pos = _resolveBloc<LocationTrackingCubit>(context).state.current;
    setState(() => _capturing = true);

    try {
      final result = await sl<ProofPhotoService>().captureStamped(
        latitude: pos?.latitude ?? stop.customer.latitude,
        longitude: pos?.longitude ?? stop.customer.longitude,
      );

      if (!mounted) return;

      if (result != null) {
        _resolveBloc<VisitCubit>(context).addPhoto(VisitPhoto(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          stopId: stop.id,
          url: result.filePath,
          caption: 'my_visits.stop.shopfront_proof'.tr,
          takenAt: result.takenAt,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture photo: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
      }
    }
  }

  /// Where the designated check-in area comes from.
  ///
  /// The demo pin by default (testing at the office); each stop's own pin
  /// with `--dart-define=USE_STOP_OUTLET_PIN=true`. See [kUseStopOutletPin].
  static const OutletLocationSource _outletLocations = kUseStopOutletPin
      ? StopOutletLocationSource()
      : StaticOutletLocationSource();

  static const FraudPolicy _policy = FraudPolicy();

  /// Measures the rep against the outlet — the one verdict every location
  /// widget on this screen, the dialog, and the bloc all use.
  ///
  /// Reads the tracker's *usable* fix (recent enough to mean "now"), never a
  /// guess. No fix yet is its own verdict.
  CheckInReading _readLocation(
      RouteStop stop, LocationTrackingState locationState) {
    final sample = locationState.usableFix();

    // TODO(release-gate): while `kUseStaticCheckInPosition` is on (debug
    // builds only), the rep's position is a constant rather than the device's.
    final deviceLatitude = kUseStaticCheckInPosition
        ? kStaticCheckInPosition.latitude
        : sample?.latitude;
    final deviceLongitude = kUseStaticCheckInPosition
        ? kStaticCheckInPosition.longitude
        : sample?.longitude;
    final accuracy =
        kUseStaticCheckInPosition ? 0.0 : (sample?.accuracyMeters ?? 0.0);

    final verdict = CheckInLocationVerifier.verify(
      outlet: _outletLocations.locationFor(stop.customer),
      deviceLatitude: deviceLatitude,
      deviceLongitude: deviceLongitude,
      fallbackRadiusMeters: _outletLocations.radiusMeters,
    );

    return CheckInReading(
      verdict: verdict,
      phase: CheckInGpsPhase.resolve(
        verdict: verdict,
        fixStatus: locationState.fixStatus,
        accuracyMeters: accuracy,
        maxAccuracyMeters: _policy.maxAccuracyMeters,
      ),
      accuracyMeters: accuracy,
      maxAccuracyMeters: _policy.maxAccuracyMeters,
      searchStartedAt: locationState.searchStartedAt,
    );
  }

  /// Retry / open-settings, from the status banner.
  void _onLocationAction(CheckInGpsPhase phase) {
    final cubit = _resolveBloc<LocationTrackingCubit>(context);
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
    if (phase.isBlockedBySetting) {
      unawaited(cubit.openSettingsForStatus());
    } else {
      unawaited(cubit.retryFix());
    }
  }

  Future<void> _submit(RouteStop stop) async {
    if (_submitting) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    final locationCubit = _resolveBloc<LocationTrackingCubit>(context);
    final bloc = _resolveBloc<ActiveRouteBloc>(context);

    // Already checked in (came back to this screen, or an earlier answer was
    // missed): nothing to verify — go straight on.
    final alreadyIn = _liveStop(bloc.state, stop.id);
    if (_isCheckedIn(alreadyIn)) {
      _goToVisit(context, alreadyIn!);
      return;
    }

    // The bloc must hold this route before it can check anything in. If the
    // initial load has not finished (or timed out), try once more now rather
    // than dispatching into a bloc that will ignore it.
    if (bloc.state is! ActiveRouteReady ||
        _liveStop(bloc.state, stop.id) == null) {
      await _ensureStopSelected(stop);
      if (!mounted) return;
      if (_liveStop(bloc.state, stop.id) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // TODO(i18n)
            content: const Text(
                'Route is still loading. Please wait a moment and try again.'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }
    }
    if (!mounted) return;

    // Verify, then ask. The dialog is live: it re-verifies on every fix and
    // always offers a way forward (see `CheckInConfirmationDialog`), so a rep
    // with no fix at the moment of tapping is no longer stranded on "Locating
    // You" with only Cancel.
    final choice = await CheckInConfirmationDialog.show(
      context,
      outletName: context.localized(stop.customer.displayName),
      locationCubit: locationCubit,
      read: (state) => _readLocation(stop, state),
    );
    if (choice == null || !mounted) return;

    // The reading the rep actually agreed to — the dialog's last one.
    final reading = _readLocation(stop, locationCubit.state);

    // Inside the area: nothing more to ask. Outside it, on a weak fix, or with
    // no fix at all, the rep is not blocked — the check-in just has to carry a
    // written reason, which rides on the check-in row itself. Backing out of
    // the reason sheet cancels the check-in; there is no path that records an
    // unverified one with an empty explanation.
    String? overrideReason;
    switch (choice) {
      case CheckInConfirmation.confirmed:
        break;
      case CheckInConfirmation.withReason:
        overrideReason = await RemoteCheckInSheet.show(
          context,
          blockedReason: reading.phase == CheckInGpsPhase.weakSignal
              ? 'GPS accuracy too low '
                  '(±${reading.accuracyMeters.toStringAsFixed(0)} m).'
              : 'my_visits.check_in_verification.outside_body'.tr,
          distanceMeters:
              reading.verdict.isMeasurable ? reading.distanceMeters : null,
          minLength: _policy.minOverrideReasonLength,
        );
      case CheckInConfirmation.withoutGps:
        // TODO(i18n): literals, same convention as RemoteCheckInSheet.
        overrideReason = await RemoteCheckInSheet.show(
          context,
          title: 'Check in without GPS?',
          intro: 'Your position could not be found here. You can still check '
              'in — the visit is marked unverified and your reason is sent '
              'with it.',
          blockedReason: 'No GPS position after a full search.',
          distanceMeters: null,
          minLength: _policy.minOverrideReasonLength,
          presets: RemoteCheckInSheet.noGpsPresets,
          icon: Icons.gps_off_rounded,
        );
    }
    if (choice != CheckInConfirmation.confirmed && overrideReason == null) {
      return;
    }
    if (!mounted) return;

    // Hand the bloc the exact reading the rep saw before asking it to decide.
    // Events are processed in order and the geofence handler is synchronous,
    // so the check-in below is judged on this sample, not an older one.
    _reportGeofence(bloc, locationCubit.state);

    // Dispatch and wait. `_onCheckInSettled` navigates when the stop actually
    // reaches `checkedIn`, and stays here showing the reason when the bloc
    // refuses.
    _beginSubmit(bloc);
    bloc.add(CheckInRequested(overrideReason: overrideReason, stopId: stop.id));
  }

  static List<VisitPhoto> _photosForStop(VisitState state, String stopId) {
    if (state is! VisitLoaded) return const [];
    return state.data.photos.where((p) => p.stopId == stopId).toList();
  }

  void _expandMap(BuildContext context, RouteStop stop) {
    final locationCubit = _resolveBloc<LocationTrackingCubit>(context);
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        fullscreenDialog: true,
        pageBuilder: (_, animation, secondaryAnimation) => BlocProvider.value(
          value: locationCubit,
          child: FadeTransition(
            opacity: animation,
            child: _FullScreenTransitMap(stop: stop),
          ),
        ),
      ),
    );
  }

  void _goToVisit(BuildContext context, RouteStop stop) {
    final navigator = Navigator.of(context);

    // No explicit workflow write here: the `CheckInRequested` dispatched in
    // `_submit` already seeds it — `ActiveRouteBloc._writeWorkflowPointer`
    // sets the baseline resume pointer to the Inventory Visibility step as
    // soon as the check-in lands.
    navigator
        .popUntil((r) => r.settings.name == StopInformationScreen.routeName);

    openInventoryVisibilityForCustomer(
      navigator.context,
      customerId: stop.customer.id,
      customerName: context.localized(stop.customer.displayName),
      stopId: stop.id,
    );
  }

  @override
  Widget build(BuildContext context) => LocalizedBuilder(builder: _build);

  Widget _build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    final activeRouteBloc = _resolveBloc<ActiveRouteBloc>(context);
    final visitCubit = _resolveBloc<VisitCubit>(context);
    final locationCubit = _resolveBloc<LocationTrackingCubit>(context);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text(
          'my_visits.flow.checkin_title'.tr,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: context.rsp(17),
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: MultiBlocListener(
        listeners: [
          // The bridge from GPS to the bloc: every new fix — and every status
          // change, so a fix going stale is noticed — is run through the same
          // verifier the dialog uses and dispatched as `GeofenceStatusChanged`.
          // The bloc deliberately has no location dependency (it stays
          // unit-testable), so the bridge belongs here.
          BlocListener<LocationTrackingCubit, LocationTrackingState>(
            bloc: locationCubit,
            listenWhen: (previous, current) =>
                previous.current != current.current ||
                previous.fixStatus != current.fixStatus,
            listener: (context, locationState) =>
                _reportGeofence(activeRouteBloc, locationState),
          ),
          // Check-in is asynchronous and can be refused. Navigation waits for
          // the verdict instead of assuming one.
          BlocListener<ActiveRouteBloc, ActiveRouteState>(
            bloc: activeRouteBloc,
            listener: _onCheckInSettled,
          ),
        ],
        child: BlocBuilder<ActiveRouteBloc, ActiveRouteState>(
          bloc: activeRouteBloc,
          // Rebuild the page only for what it renders from the bloc. The bloc
          // also emits on every GPS sample (distance, accuracy, position), and
          // rebuilding the whole page — Google Map included — for each one is
          // what made this screen feel stuck.
          buildWhen: (previous, current) =>
              _pageKey(previous) != _pageKey(current),
          builder: (context, state) {
            final RouteStop? stop = _currentStop(state);

            if (stop == null) {
              return Center(
                child: CircularProgressIndicator(
                  color: scheme.primary,
                  strokeWidth: 2.8,
                ),
              );
            }

            final String? blockedReason =
                state is ActiveRouteReady ? state.blockedCheckInReason : null;
            final List<String> warnings =
                state is ActiveRouteReady ? state.checkInWarnings : const [];

            return BlocBuilder<VisitCubit, VisitState>(
              bloc: visitCubit,
              builder: (context, visitState) {
                final photos = _photosForStop(visitState, stop.id);

                return Column(
                  children: [
                    const OfflineBanner(margin: EdgeInsets.zero),

                    // Segment 1: Customer Header Card
                    _Staggered(
                      controller: _entranceController,
                      begin: 0.0,
                      end: 0.55,
                      child: BlocBuilder<LocationTrackingCubit,
                          LocationTrackingState>(
                        bloc: locationCubit,
                        builder: (context, locationState) =>
                            _UnifiedCustomerHeader(
                          stop: stop,
                          reading: _readLocation(stop, locationState),
                        ),
                      ),
                    ),

                    // Segment 2: Interactive Real-time Map Viewport.
                    //
                    // Deliberately **not** inside `_Staggered`: animating
                    // opacity or transform over a native map view forces
                    // expensive compositing on iOS and makes the map flash
                    // grey. It gets its own builder that fires only when the
                    // rep's position actually changes.
                    Expanded(
                      flex: 4,
                      child: RepaintBoundary(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: BlocBuilder<LocationTrackingCubit,
                                  LocationTrackingState>(
                                bloc: locationCubit,
                                buildWhen: (previous, current) =>
                                    previous.current != current.current,
                                builder: (context, locationState) =>
                                    TransitMap(
                                  target: stop,
                                  currentPosition:
                                      _mapPosition(locationState),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 14,
                              top: 14,
                              child: _MapExpandButton(
                                onTap: () => _expandMap(context, stop),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Segment 3: Workspace Action Board
                    Expanded(
                      flex: 5,
                      child: _Staggered(
                        controller: _entranceController,
                        begin: 0.18,
                        end: 0.85,
                        offset: 0.10,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 16,
                                offset: const Offset(0, -6),
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            child: ListView(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 20, 20, 12),
                              children: [
                                BlocBuilder<LocationTrackingCubit,
                                    LocationTrackingState>(
                                  bloc: locationCubit,
                                  builder: (context, locationState) {
                                    final reading =
                                        _readLocation(stop, locationState);
                                    return _GeoStatusBanner(
                                      reading: reading,
                                      blockedReason: blockedReason,
                                      warnings: warnings,
                                      onAction: () =>
                                          _onLocationAction(reading.phase),
                                    );
                                  },
                                ),
                                SizedBox(height: context.rh(18)),
                                Row(
                                  children: [
                                    Text(
                                      'my_visits.flow.proof_photo'.tr,
                                      style: TextStyle(
                                        color: colors.textPrimary,
                                        fontSize: context.rsp(14),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const Spacer(),
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      transitionBuilder: (child, a) =>
                                          ScaleTransition(
                                              scale: a, child: child),
                                      child: photos.isEmpty
                                          ? _PulseIndicator()
                                          : Icon(
                                              Icons.check_circle_rounded,
                                              key: const ValueKey('done'),
                                              color: colors.success,
                                              size: context.rr(18),
                                            ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: context.rh(12)),
                                _CameraDropzone(
                                  photos: photos,
                                  capturing: _capturing,
                                  isLocked: false,
                                  onTap: () => _capture(stop),
                                ),
                                SizedBox(height: context.rh(10)),
                                Text(
                                  'my_visits.flow.checkin_explainer'.tr,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: context.rsp(11.5),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Contextual Bottom CTA
                    _Staggered(
                      controller: _entranceController,
                      begin: 0.35,
                      end: 1.0,
                      offset: 0.35,
                      child: _CheckInBottomBar(
                        enabled: !_submitting,
                        submitting: _submitting,
                        hint: blockedReason,
                        onTap: () => unawaited(_submit(stop)),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// What the page renders from the bloc — and nothing else. GPS-driven
  /// fields (distance, accuracy, rep position) are deliberately left out;
  /// the location builders inside handle those.
  Object? _pageKey(ActiveRouteState state) {
    if (state is! ActiveRouteReady) return state.runtimeType;
    final live = _liveStop(state, _stopId);
    return (
      state.currentStopIndex,
      live?.id,
      live?.status,
      state.blockedCheckInReason,
      state.checkInWarnings.join('\n'),
    );
  }

  /// A fixed stand-in for the rep while `kUseStaticCheckInPosition` is on
  /// (debug builds only), so the map shows the same position the verdict
  /// uses instead of the simulator's default location on another continent.
  static final LocationSample _staticMapSample = LocationSample(
    id: 'static-check-in-position',
    routeId: 'static',
    latitude: kStaticCheckInPosition.latitude,
    longitude: kStaticCheckInPosition.longitude,
    accuracyMeters: 0,
    speedMps: 0,
    headingDegrees: 0,
    altitudeMeters: 0,
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
    isMocked: false,
  );

  static LocationSample? _mapPosition(LocationTrackingState locationState) =>
      kUseStaticCheckInPosition ? _staticMapSample : locationState.current;
}

/// Fades and lifts [child] in over its own slice ([begin]–[end]) of the
/// shared entrance timeline. Several of these on one controller give a smooth
/// top-to-bottom cascade for the price of a single ticker.
class _Staggered extends StatelessWidget {
  const _Staggered({
    required this.controller,
    required this.begin,
    required this.end,
    required this.child,
    this.offset = 0.08,
  });

  final AnimationController controller;
  final double begin;
  final double end;

  /// Starting vertical offset, as a fraction of the child's own height.
  final double offset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: controller,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset(0, offset), end: Offset.zero)
            .animate(curved),
        child: child,
      ),
    );
  }
}

class _UnifiedCustomerHeader extends StatelessWidget {
  const _UnifiedCustomerHeader({
    required this.stop,
    required this.reading,
  });

  final RouteStop stop;
  final CheckInReading reading;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      color: colors.card,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.localized(stop.customer.displayName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: context.rsp(17),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: context.rh(3)),
                Text(
                  stop.customer.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: context.rsp(12.5),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: context.rw(12)),
          _DistanceChip(reading: reading),
        ],
      ),
    );
  }
}

/// The header's distance pill.
///
/// It used to read the bloc's `distanceMeters`, which defaults to **0** — so
/// before any fix it proudly said "0 m • ~1 min" while the dialog below said it
/// had no idea where the rep was. Now it says "Locating…" until something is
/// measured, then glides to the real figure.
class _DistanceChip extends StatelessWidget {
  const _DistanceChip({required this.reading});

  final CheckInReading reading;

  static int _etaMinutes(double meters) =>
      max(1, ((meters / 1000) / 25 * 60).round());

  static String _distanceLabel(double meters) {
    final km = meters / 1000;
    return km < 0.1 ? '${meters.round()} m' : '${km.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final phase = reading.phase;

    final Color tone = switch (phase) {
      CheckInGpsPhase.within => colors.success,
      CheckInGpsPhase.searching || CheckInGpsPhase.noOutlet => scheme.primary,
      _ => colors.warning,
    };

    final Widget content;
    if (phase.isMeasured) {
      final distance = reading.distanceMeters;
      content = Row(
        key: const ValueKey('measured'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.navigation_rounded, color: tone, size: context.rr(14)),
          SizedBox(width: context.rw(5)),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: distance),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text(
              // `trParams`, not `.tr` with the number glued on outside —
              // `minutes_shortTemplate` is `'{minutes} min'` (FS-LOC-3).
              '${_distanceLabel(v)} • ~'
              '${'my_visits.flow.minutes_shortTemplate'.trParams({
                    'minutes': _etaMinutes(v),
                  })}',
              style: TextStyle(
                color: tone,
                fontSize: context.rsp(11.5),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      );
    } else {
      final (IconData icon, String label) = switch (phase) {
        CheckInGpsPhase.servicesDisabled => (
            Icons.location_disabled_rounded,
            'Location off', // TODO(i18n)
          ),
        CheckInGpsPhase.permissionDenied ||
        CheckInGpsPhase.permissionDeniedForever =>
          (Icons.lock_outline_rounded, 'No permission'), // TODO(i18n)
        CheckInGpsPhase.unavailable =>
          (Icons.gps_off_rounded, 'No GPS'), // TODO(i18n)
        CheckInGpsPhase.noOutlet =>
          (Icons.add_location_alt_rounded, 'No pin'), // TODO(i18n)
        _ => (Icons.gps_not_fixed_rounded, 'Locating…'), // TODO(i18n)
      };
      content = Row(
        key: ValueKey(label),
        mainAxisSize: MainAxisSize.min,
        children: [
          if (phase == CheckInGpsPhase.searching)
            SizedBox(
              width: context.rr(12),
              height: context.rr(12),
              child: CircularProgressIndicator(strokeWidth: 1.8, color: tone),
            )
          else
            Icon(icon, color: tone, size: context.rr(14)),
          SizedBox(width: context.rw(6)),
          Text(
            label,
            style: TextStyle(
              color: tone,
              fontSize: context.rsp(11.5),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.18)),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1).animate(a),
              child: child,
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// The live location status above the proof photo.
///
/// Renders from the same [CheckInReading] as the dialog. Each phase has its
/// own pill, cross-faded on change; the searching pill carries a soft sweep so
/// it reads as *working*, and the states the rep can fix carry the button that
/// fixes them.
class _GeoStatusBanner extends StatelessWidget {
  const _GeoStatusBanner({
    required this.reading,
    required this.blockedReason,
    required this.warnings,
    required this.onAction,
  });

  final CheckInReading reading;
  final String? blockedReason;
  final List<String> warnings;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final phase = reading.phase;
    final radius = reading.radiusMeters.round();
    final distance =
        reading.verdict.isMeasurable ? reading.distanceMeters.round() : 0;

    // TODO(i18n): the new phases use literals; the two that existed keep keys.
    final (Color color, IconData icon, String text, String? subtitle,
        String? action) = switch (phase) {
      CheckInGpsPhase.within => (
          colors.success,
          Icons.check_circle_rounded,
          // The key is a template — `{dist}` must be filled, or the rep sees
          // the placeholder itself ("GPS {dist} m away").
          'my_visits.flow.geo_matchedTemplate'
              .tr
              .replaceAll('{dist}', '$distance'),
          'my_visits.flow.transit_banner_ready'.tr,
          null,
        ),
      CheckInGpsPhase.outside => (
          colors.warning,
          Icons.wrong_location_rounded,
          'my_visits.flow.geo_not_matched'.tr.replaceAll('{dist}', '$distance'),
          'my_visits.flow.transit_disclaimer'
              .tr
              .replaceAll('{radius}', '$radius'),
          null,
        ),
      CheckInGpsPhase.weakSignal => (
          colors.warning,
          Icons.network_check_rounded,
          'Weak GPS signal (±${reading.accuracyMeters.round()} m)',
          'You look close enough — the signal is still improving.',
          null,
        ),
      CheckInGpsPhase.searching => (
          scheme.primary,
          Icons.gps_not_fixed_rounded,
          'Finding your location…',
          'This usually takes a few seconds.',
          null,
        ),
      CheckInGpsPhase.servicesDisabled => (
          colors.warning,
          Icons.location_disabled_rounded,
          'Location is turned off',
          'Turn it on to verify this check-in.',
          'Turn on',
        ),
      CheckInGpsPhase.permissionDenied => (
          colors.warning,
          Icons.lock_outline_rounded,
          'Location permission needed',
          'Allow access so the check-in can be verified.',
          'Allow',
        ),
      CheckInGpsPhase.permissionDeniedForever => (
          colors.warning,
          Icons.lock_outline_rounded,
          'Location permission blocked',
          'Enable it in the app settings.',
          'Settings',
        ),
      CheckInGpsPhase.unavailable => (
          colors.warning,
          Icons.gps_off_rounded,
          'No GPS signal here',
          'You can still check in without GPS, with a short reason.',
          'Retry',
        ),
      CheckInGpsPhase.noOutlet => (
          scheme.primary,
          Icons.add_location_alt_rounded,
          'my_visits.check_in_verification.no_outlet_title'.tr,
          null,
          null,
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [...previous, if (current != null) current],
          ),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: child,
            ),
          ),
          child: _StatusPill(
            key: ValueKey(phase),
            color: color,
            icon: icon,
            text: text,
            subtitle: subtitle,
            shimmer: phase == CheckInGpsPhase.searching,
            trailing: phase.isMeasured
                ? SignalBars(
                    level: signalLevelFor(
                        reading.accuracyMeters, reading.maxAccuracyMeters),
                    color: color,
                  )
                : null,
            actionLabel: action,
            onAction: action == null ? null : onAction,
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (blockedReason != null) ...[
                SizedBox(height: context.rh(8)),
                _StatusPill(
                  color: scheme.error,
                  icon: Icons.block_rounded,
                  text: blockedReason!,
                ),
              ],
              for (final warning in warnings) ...[
                SizedBox(height: context.rh(8)),
                _StatusPill(
                  color: colors.warning,
                  icon: Icons.warning_amber_rounded,
                  text: warning,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatefulWidget {
  const _StatusPill({
    super.key,
    required this.color,
    required this.icon,
    required this.text,
    this.subtitle,
    this.shimmer = false,
    this.trailing,
    this.actionLabel,
    this.onAction,
  });

  final Color color;
  final IconData icon;
  final String text;
  final String? subtitle;

  /// A slow light sweep across the pill — "working on it", without a spinner.
  final bool shimmer;
  final Widget? trailing;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.shimmer) _sweep.repeat();
  }

  @override
  void didUpdateWidget(covariant _StatusPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shimmer && !_sweep.isAnimating) {
      _sweep.repeat();
    } else if (!widget.shimmer && _sweep.isAnimating) {
      _sweep.stop();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(widget.icon, size: context.rr(18), color: color),
          SizedBox(width: context.rw(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.text,
                  style: TextStyle(
                    color: color,
                    fontSize: context.rsp(12.5),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  SizedBox(height: context.rh(2)),
                  Text(
                    widget.subtitle!,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.85),
                      fontSize: context.rsp(11),
                    ),
                  ),
                ]
              ],
            ),
          ),
          if (widget.trailing != null) ...[
            SizedBox(width: context.rw(8)),
            widget.trailing!,
          ],
          if (widget.actionLabel != null) ...[
            SizedBox(width: context.rw(8)),
            TextButton(
              onPressed: widget.onAction,
              style: TextButton.styleFrom(
                foregroundColor: color,
                backgroundColor: color.withValues(alpha: 0.12),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                widget.actionLabel!,
                style: TextStyle(
                  fontSize: context.rsp(11.5),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (!widget.shimmer) return pill;

    // The sweep is a moving gradient over the pill, repainted straight off the
    // controller — no rebuilds while it runs.
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          pill,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _sweep,
                builder: (context, _) {
                  final t = Curves.easeInOut.transform(_sweep.value);
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-1.6 + 3.2 * t, 0),
                        end: Alignment(-0.6 + 3.2 * t, 0),
                        colors: [
                          color.withValues(alpha: 0),
                          color.withValues(alpha: 0.10),
                          color.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraDropzone extends StatelessWidget {
  const _CameraDropzone({
    required this.photos,
    required this.capturing,
    required this.isLocked,
    required this.onTap,
  });

  final List<VisitPhoto> photos;
  final bool capturing;
  final bool isLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final borderColor = isLocked
        ? colors.border
        : (photos.isNotEmpty
            ? colors.success
            : scheme.primary.withValues(alpha: 0.5));

    return GestureDetector(
      onTap: (capturing || isLocked) ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isLocked ? 0.55 : 1.0,
        child: CustomPaint(
          painter: _DashedBorderPainter(color: borderColor, radius: 16),
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isLocked
                  ? colors.surfaceSoft
                  : scheme.primary.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(16),
            ),
            child: capturing
                ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: scheme.primary,
                    ),
                  )
                : photos.isEmpty
                    ? _DropzonePlaceholder(isLocked: isLocked)
                    : _ProofGallery(photos: photos),
          ),
        ),
      ),
    );
  }
}

class _DropzonePlaceholder extends StatelessWidget {
  const _DropzonePlaceholder({required this.isLocked});
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 48,
          height: context.rh(48),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: (isLocked ? colors.textSecondary : scheme.primary)
                .withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isLocked ? Icons.lock_outline_rounded : Icons.camera_alt_rounded,
            color: isLocked ? colors.textSecondary : scheme.primary,
            size: context.rr(22),
          ),
        ),
        SizedBox(height: context.rh(10)),
        Text(
          isLocked
              ? 'my_visits.flow.transit_banner_locked'.tr
              : 'my_visits.flow.take_photo'.tr,
          style: TextStyle(
            color: isLocked ? colors.textSecondary : colors.textPrimary,
            fontSize: context.rsp(13.5),
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: context.rh(3)),
        Text(
          'my_visits.flow.fit_frame'.tr,
          style: TextStyle(
              color: colors.textSecondary, fontSize: context.rsp(11.5)),
        ),
      ],
    );
  }
}

class _ProofGallery extends StatelessWidget {
  const _ProofGallery({required this.photos});
  final List<VisitPhoto> photos;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.all(context.rr(10)),
          itemCount: photos.length,
          separatorBuilder: (_, __) => SizedBox(width: context.rw(10)),
          itemBuilder: (context, index) => ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1,
              child: localFileImage(photos[index].url, fit: BoxFit.cover),
            ),
          ),
        ),
        Positioned(
          right: 14,
          top: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_a_photo_rounded,
                  color: Colors.white,
                  size: context.rr(13),
                ),
                SizedBox(width: context.rw(5)),
                Text(
                  '${photos.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.rsp(11.5),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckInBottomBar extends StatefulWidget {
  const _CheckInBottomBar({
    required this.enabled,
    required this.submitting,
    required this.hint,
    required this.onTap,
  });

  final bool enabled;
  final bool submitting;
  final String? hint;
  final VoidCallback onTap;

  @override
  State<_CheckInBottomBar> createState() => _CheckInBottomBarState();
}

class _CheckInBottomBarState extends State<_CheckInBottomBar> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.enabled;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: widget.hint == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: EdgeInsets.only(bottom: context.rh(8)),
                      child: Text(
                        widget.hint!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: context.rsp(11.5)),
                      ),
                    ),
            ),
            Listener(
              onPointerDown: (_) => _setPressed(true),
              onPointerUp: (_) => _setPressed(false),
              onPointerCancel: (_) => _setPressed(false),
              child: AnimatedScale(
                scale: _pressed ? 0.975 : 1,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                child: SizedBox(
                  width: double.infinity,
                  height: context.rh(52),
                  child: ElevatedButton(
                    onPressed: enabled ? widget.onTap : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.success,
                      foregroundColor: scheme.onPrimary,
                      disabledBackgroundColor:
                          colors.success.withValues(alpha: 0.55),
                      disabledForegroundColor: scheme.onPrimary,
                      elevation: enabled && !_pressed ? 3 : 0,
                      shadowColor: colors.success.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, a) =>
                              ScaleTransition(scale: a, child: child),
                          child: widget.submitting
                              ? SizedBox(
                                  key: const ValueKey('spin'),
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: scheme.onPrimary,
                                  ),
                                )
                              : Icon(
                                  Icons.check_circle_rounded,
                                  key: const ValueKey('icon'),
                                  size: context.rr(20),
                                ),
                        ),
                        SizedBox(width: context.rw(8)),
                        Text(
                          'my_visits.flow.checkin_continue'.tr,
                          style: TextStyle(
                            fontSize: context.rsp(15),
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseIndicator extends StatefulWidget {
  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.1 + (_controller.value * 0.15)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'REQUIRED',
          style: TextStyle(
            color: primary.withValues(alpha: 0.75 + (_controller.value * 0.25)),
            fontSize: context.rsp(9.5),
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _MapExpandButton extends StatelessWidget {
  const _MapExpandButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    // No BackdropFilter: a blur over a native map view is re-rendered every
    // frame the map moves, and on iOS that alone can make the map stutter.
    // A near-opaque card with a soft shadow reads the same.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: colors.card.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.open_in_full_rounded,
                  size: context.rr(13),
                  color: colors.textPrimary,
                ),
                SizedBox(width: context.rw(6)),
                Text(
                  'my_visits.route_info.expand_map'.tr,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: context.rsp(11.5),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FullScreenTransitMap extends StatelessWidget {
  const _FullScreenTransitMap({required this.stop});
  final RouteStop stop;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors.card,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text(
          'my_visits.route_info.route_map'.tr,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: context.rsp(16),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: BlocBuilder<LocationTrackingCubit, LocationTrackingState>(
        bloc: _RouteCheckInScreenState._resolveBloc<LocationTrackingCubit>(
            context),
        buildWhen: (previous, current) => previous.current != current.current,
        builder: (context, locationState) => TransitMap(
          target: stop,
          currentPosition:
              _RouteCheckInScreenState._mapPosition(locationState),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final rrect =
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    // PathMetrics.extractPath per dash overflows the stack on web; the
    // polyline walker draws the same border with no lazy Path involved.
    drawDashedRRect(canvas, rrect, paint, dash: 6.0, gap: 4.0);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
