import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/l10n/visit_labels.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/location_sample.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_stop.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_status.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/services/geofence_service.dart';

/// Real Google Maps route view: stop markers (color by visit status), a
/// polyline through stops in sequence, the live position, and a geofence
/// circle around the currently-selected stop.
class RouteMap extends StatefulWidget {
  const RouteMap({
    super.key,
    required this.stops,
    required this.currentStopIndex,
    this.currentPosition,
  });

  final List<RouteStop> stops;
  final int currentStopIndex;
  final LocationSample? currentPosition;

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  GoogleMapController? _controller;
  bool _autoFollow = true;

  /// Releases the native map view — see the matching note in `transit_map.dart`.
  /// Without this the platform view outlives the widget and keeps compositing
  /// over later screens as a blank rounded rectangle.
  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final position = widget.currentPosition;
    if (_autoFollow && _controller != null && position != null) {
      _controller!.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );
    }
  }

  double _hueFor(VisitStatus status) => switch (status) {
        VisitStatus.pending => BitmapDescriptor.hueViolet,
        VisitStatus.enRoute || VisitStatus.arrived => BitmapDescriptor.hueAzure,
        VisitStatus.checkedIn => BitmapDescriptor.hueOrange,
        VisitStatus.checkedOut => BitmapDescriptor.hueGreen,
        VisitStatus.missed => BitmapDescriptor.hueRed,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final stopMarkers = <Marker>{
      for (var i = 0; i < widget.stops.length; i++)
        Marker(
          markerId: MarkerId(widget.stops[i].id),
          position: LatLng(widget.stops[i].customer.latitude,
              widget.stops[i].customer.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              _hueFor(widget.stops[i].status)),
          infoWindow: InfoWindow(
            title: '${i + 1}. ${widget.stops[i].customer.name}',
            snippet: widget.stops[i].status.localizedLabel,
          ),
        ),
    };

    final positionMarker = widget.currentPosition == null
        ? const <Marker>{}
        : {
            Marker(
              markerId: const MarkerId('current_position'),
              position: LatLng(widget.currentPosition!.latitude,
                  widget.currentPosition!.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue),
              zIndexInt: 10,
              anchor: const Offset(0.5, 0.5),
              flat: true,
            ),
          };

    final polyline = widget.stops.length < 2
        ? const <Polyline>{}
        : {
            Polyline(
              polylineId: const PolylineId('route'),
              color: scheme.primary,
              width: 4,
              points: [
                for (final s in widget.stops)
                  LatLng(s.customer.latitude, s.customer.longitude)
              ],
            ),
          };

    final geofenceCircle = widget.currentStopIndex < 0 ||
            widget.currentStopIndex >= widget.stops.length
        ? const <Circle>{}
        : {
            Circle(
              circleId: const CircleId('geofence'),
              center: LatLng(
                widget.stops[widget.currentStopIndex].customer.latitude,
                widget.stops[widget.currentStopIndex].customer.longitude,
              ),
              radius: widget
                  .stops[widget.currentStopIndex].customer.geofenceRadiusMeters,
              strokeColor: scheme.primary,
              strokeWidth: 2,
              fillColor: scheme.primary.withValues(alpha: 0.12),
            ),
          };

    final initialTarget = widget.stops.isEmpty
        ? const LatLng(11.5564, 104.9282)
        : LatLng(widget.stops.first.customer.latitude,
            widget.stops.first.customer.longitude);

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition:
              CameraPosition(target: initialTarget, zoom: 13),
          onMapCreated: (controller) => _controller = controller,
          markers: {...stopMarkers, ...positionMarker},
          polylines: polyline,
          circles: geofenceCircle,
          // Native OS blue-dot layer, same rationale as TransitMap: shows the
          // rep's real device GPS position regardless of whether the app's
          // own LocationTrackingCubit pipeline has a fresh sample yet.
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: FloatingActionButton.small(
            heroTag: 'route_map_follow',
            backgroundColor: _autoFollow ? scheme.primary : colors.card,
            onPressed: () => setState(() => _autoFollow = !_autoFollow),
            child: Icon(Icons.my_location_rounded,
                color: _autoFollow ? scheme.onPrimary : colors.textPrimary),
          ),
        ),
      ],
    );
  }
}

/// Small helper so callers (e.g. the visit screen listening to GPS updates)
/// can turn a raw position into a geofence-relative event without
/// depending on `GeofenceService` directly at every call site.
GeofenceCheckResult? evaluateStopGeofence({
  required List<RouteStop> stops,
  required int currentStopIndex,
  required double latitude,
  required double longitude,
}) {
  if (currentStopIndex < 0 || currentStopIndex >= stops.length) return null;
  return GeofenceService.evaluate(
    repLatitude: latitude,
    repLongitude: longitude,
    customer: stops[currentStopIndex].customer,
  );
}
