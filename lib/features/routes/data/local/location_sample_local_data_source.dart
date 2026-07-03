import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/features/routes/data/local/routes_database.dart';
import 'package:isi_steel_sales_mobile/features/routes/data/models/fraud_flag_model.dart';
import 'package:isi_steel_sales_mobile/features/routes/data/models/location_sample_model.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class LocationSampleLocalDataSource {
  Future<void> insertSample(LocationSampleModel sample);
  Future<List<LocationSampleModel>> fetchSamples(String routeId);
  Future<void> insertFraudFlag(FraudFlagModel flag);
  Future<List<FraudFlagModel>> fetchFraudFlags(String routeId);
}

class LocationSampleLocalDataSourceImpl implements LocationSampleLocalDataSource {
  const LocationSampleLocalDataSourceImpl(this._routesDb);
  final RoutesDatabase _routesDb;
  Database get _db => _routesDb.db;

  @override
  Future<void> insertSample(LocationSampleModel sample) async {
    try {
      await _db.insert('location_samples', sample.toRow());
    } catch (e) {
      throw CacheException(message: 'Failed to save GPS sample: $e');
    }
  }

  @override
  Future<List<LocationSampleModel>> fetchSamples(String routeId) async {
    try {
      final rows = await _db.query(
        'location_samples',
        where: 'route_id = ?',
        whereArgs: [routeId],
        orderBy: 'timestamp ASC',
      );
      return rows.map(LocationSampleModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load GPS trail: $e');
    }
  }

  @override
  Future<void> insertFraudFlag(FraudFlagModel flag) async {
    try {
      await _db.insert('fraud_flags', flag.toRow());
    } catch (e) {
      throw CacheException(message: 'Failed to save fraud flag: $e');
    }
  }

  @override
  Future<List<FraudFlagModel>> fetchFraudFlags(String routeId) async {
    try {
      final rows = await _db.query(
        'fraud_flags',
        where: 'route_id = ?',
        whereArgs: [routeId],
        orderBy: 'timestamp DESC',
      );
      return rows.map(FraudFlagModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load fraud flags: $e');
    }
  }
}
