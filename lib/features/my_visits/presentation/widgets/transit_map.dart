import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/location_sample.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_stop.dart';

/// Focused transit map for Step 2: the live GPS dot, the target shop's marker
/// + geofence circle, and a direct polyline between them. Camera auto-fits
/// both points so the rep always sees "where I am → where I'm going".
class TransitMap extends StatefulWidget {
  const TransitMap({super.key, required this.target, this.currentPosition});

  final RouteStop target;
  final LocationSample? currentPosition;

  @override
  State<TransitMap> createState() => _TransitMapState();
}

class _TransitMapState extends State<TransitMap> {
  GoogleMapController? _controller;
  bool _didInitialFit = false;

  LatLng get _targetLatLng =>
      LatLng(widget.target.customer.latitude, widget.target.customer.longitude);
  LatLng? get _currentLatLng => widget.currentPosition == null
      ? null
      : LatLng(
          widget.currentPosition!.latitude, widget.currentPosition!.longitude);

  /// Releases the native map view.
  ///
  /// `GoogleMapController` owns an Android/iOS platform view — a native surface
  /// the engine composites *above* the Flutter layer, not a widget in the Dart
  /// tree. Dropping the Dart reference without disposing it leaves that surface
  /// alive and registered with the platform-view controller, so it keeps
  /// painting at its last screen-space rect over whatever screen is now on top.
  /// That is the stray rounded white rectangle seen on Home and the Route
  /// Dashboard: it is invisible to any widget-tree audit precisely because it
  /// is not a widget.
  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TransitMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Fit both points the first time we get a GPS fix.
    if (!_didInitialFit &&
        widget.currentPosition != null &&
        oldWidget.currentPosition == null) {
      _fitBounds();
    }
  }

  void _fitBounds() {
    final current = _currentLatLng;
    final controller = _controller;
    if (controller == null) return;
    _didInitialFit = true;
    if (current == null) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(_targetLatLng, 15));
      return;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(min(current.latitude, _targetLatLng.latitude),
          min(current.longitude, _targetLatLng.longitude)),
      northeast: LatLng(max(current.latitude, _targetLatLng.latitude),
          max(current.longitude, _targetLatLng.longitude)),
    );
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 64));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = _currentLatLng;

    final markers = <Marker>{
      Marker(
        markerId: MarkerId(widget.target.id),
        position: _targetLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        infoWindow: InfoWindow(
            title: widget.target.customer.name,
            snippet: widget.target.customer.address),
      ),
      if (current != null)
        Marker(
          markerId: const MarkerId('current_position'),
          position: current,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          anchor: const Offset(0.5, 0.5),
          flat: true,
          zIndexInt: 10,
        ),
    };

    final circles = <Circle>{
      Circle(
        circleId: const CircleId('geofence'),
        center: _targetLatLng,
        radius: widget.target.customer.geofenceRadiusMeters,
        strokeColor: scheme.primary,
        strokeWidth: 2,
        fillColor: scheme.primary.withValues(alpha: 0.12),
      ),
    };

    final polylines = current == null
        ? const <Polyline>{}
        : {
            Polyline(
              polylineId: const PolylineId('to_target'),
              color: scheme.primary,
              width: 4,
              patterns: [PatternItem.dash(24), PatternItem.gap(12)],
              points: [current, _targetLatLng],
            ),
          };

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition:
              CameraPosition(target: current ?? _targetLatLng, zoom: 14),
          onMapCreated: (controller) {
            _controller = controller;
            WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
          },
          markers: markers,
          circles: circles,
          polylines: polylines,
          // Native OS blue-dot layer — draws straight from the device's GPS,
          // independent of LocationTrackingCubit/current. Useful both as a
          // real "where am I" indicator for the rep and as a way to tell
          // whether a stuck geofence is a tracking-pipeline issue (blue dot
          // moves, custom marker doesn't) or a genuine GPS/position issue
          // (blue dot itself doesn't move or sits outside the circle).
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: FloatingActionButton.small(
            heroTag: 'transit_map_recenter',
            backgroundColor: scheme.primary,
            onPressed: _fitBounds,
            child: Icon(Icons.center_focus_strong_rounded,
                color: scheme.onPrimary),
          ),
        ),
      ],
    );
  }
}
