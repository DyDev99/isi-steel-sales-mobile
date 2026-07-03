import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/routes/domain/entities/location_sample.dart';

class LocationTrackingState extends Equatable {
  const LocationTrackingState({
    this.isTracking = false,
    this.current,
    this.trail = const [],
    this.permissionDenied = false,
  });

  final bool isTracking;
  final LocationSample? current;
  final List<LocationSample> trail;
  final bool permissionDenied;

  LocationTrackingState copyWith({
    bool? isTracking,
    LocationSample? current,
    List<LocationSample>? trail,
    bool? permissionDenied,
  }) {
    return LocationTrackingState(
      isTracking: isTracking ?? this.isTracking,
      current: current ?? this.current,
      trail: trail ?? this.trail,
      permissionDenied: permissionDenied ?? this.permissionDenied,
    );
  }

  @override
  List<Object?> get props => [isTracking, current, trail, permissionDenied];
}
