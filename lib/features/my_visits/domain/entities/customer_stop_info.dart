import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/territory_type.dart';

/// A customer/depot location a route can stop at.
class CustomerStopInfo extends Equatable {
  const CustomerStopInfo({
    required this.id,
    required this.name,
    required this.code,
    required this.contact,
    required this.phone,
    required this.address,
    required this.territory,
    required this.territoryType,
    required this.latitude,
    required this.longitude,
    this.geofenceRadiusOverride,
  });

  final String id;
  final String name;
  final String code;
  final String contact;
  final String phone;
  final String address;
  final String territory;
  final TerritoryType territoryType;
  final double latitude;
  final double longitude;
  final double? geofenceRadiusOverride;

  double get geofenceRadiusMeters => geofenceRadiusOverride ?? territoryType.defaultGeofenceRadiusMeters;

  @override
  List<Object?> get props => [id, name, code, territory, latitude, longitude, geofenceRadiusOverride];
}
