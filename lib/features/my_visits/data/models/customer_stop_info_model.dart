import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/customer_stop_info.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/territory_type.dart';

class CustomerStopInfoModel extends CustomerStopInfo {
  const CustomerStopInfoModel({
    required super.id,
    required super.name,
    required super.code,
    required super.contact,
    required super.phone,
    required super.address,
    required super.territory,
    required super.territoryType,
    required super.latitude,
    required super.longitude,
    super.geofenceRadiusOverride,
  });

  factory CustomerStopInfoModel.fromJson(DataMap json) => CustomerStopInfoModel(
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String,
        contact: json['contact'] as String,
        phone: json['phone'] as String,
        address: json['address'] as String,
        territory: json['territory'] as String,
        territoryType: TerritoryType.values.byName(json['territoryType'] as String),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        geofenceRadiusOverride: (json['geofenceRadiusOverride'] as num?)?.toDouble(),
      );

  factory CustomerStopInfoModel.fromRow(DataMap row) => CustomerStopInfoModel(
        id: row['id'] as String,
        name: row['name'] as String,
        code: row['code'] as String,
        contact: row['contact'] as String,
        phone: row['phone'] as String,
        address: row['address'] as String,
        territory: row['territory'] as String,
        territoryType: TerritoryType.values.byName(row['territory_type'] as String),
        latitude: (row['latitude'] as num).toDouble(),
        longitude: (row['longitude'] as num).toDouble(),
        geofenceRadiusOverride: (row['geofence_radius_override'] as num?)?.toDouble(),
      );

  DataMap toRow() => {
        'id': id,
        'name': name,
        'code': code,
        'contact': contact,
        'phone': phone,
        'address': address,
        'territory': territory,
        'territory_type': territoryType.name,
        'latitude': latitude,
        'longitude': longitude,
        'geofence_radius_override': geofenceRadiusOverride,
      };
}
