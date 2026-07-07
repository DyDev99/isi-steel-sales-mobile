import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/check_in_record.dart';

class CheckInRecordModel extends CheckInRecord {
  const CheckInRecordModel({
    required super.id,
    required super.stopId,
    required super.timestamp,
    required super.latitude,
    required super.longitude,
    required super.accuracyMeters,
    required super.distanceFromCustomerMeters,
    required super.isMocked,
  });

  factory CheckInRecordModel.fromRow(DataMap row) => CheckInRecordModel(
        id: row['id'] as String,
        stopId: row['stop_id'] as String,
        timestamp: DateTime.parse(row['timestamp'] as String),
        latitude: (row['latitude'] as num).toDouble(),
        longitude: (row['longitude'] as num).toDouble(),
        accuracyMeters: (row['accuracy'] as num).toDouble(),
        distanceFromCustomerMeters: (row['distance_from_customer'] as num).toDouble(),
        isMocked: (row['is_mocked'] as int) == 1,
      );

  DataMap toRow() => {
        'id': id,
        'stop_id': stopId,
        'timestamp': timestamp.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracyMeters,
        'distance_from_customer': distanceFromCustomerMeters,
        'is_mocked': isMocked ? 1 : 0,
      };

  factory CheckInRecordModel.fromEntity(CheckInRecord e) => CheckInRecordModel(
        id: e.id,
        stopId: e.stopId,
        timestamp: e.timestamp,
        latitude: e.latitude,
        longitude: e.longitude,
        accuracyMeters: e.accuracyMeters,
        distanceFromCustomerMeters: e.distanceFromCustomerMeters,
        isMocked: e.isMocked,
      );
}
