import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/network/network_info.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/local/master_data_cache.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/master_data_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/master_data_item.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/master_data_type.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/repositories/master_data_repository.dart';

/// Cache-first master data with an offline fallback.
///
/// Read order for [fetch]:
///   1. fresh cache        → return immediately, no network at all
///   2. offline            → stale cache if any, else [NetworkFailure]
///   3. remote             → write both cache entries, return fresh
///   4. remote failed      → stale cache if any, else rethrow the typed failure
///
/// Step 1 is what satisfies "never call SAP repeatedly for static dropdown
/// data": once a list is cached, opening the filter costs zero requests until
/// the TTL lapses or the user explicitly refreshes.
class MasterDataRepositoryImpl implements MasterDataRepository {
  const MasterDataRepositoryImpl({
    required MasterDataRemoteDataSource remote,
    required MasterDataCache cache,
    required NetworkInfo network,
  })  : _remote = remote,
        _cache = cache,
        _network = network;

  final MasterDataRemoteDataSource _remote;
  final MasterDataCache _cache;
  final NetworkInfo _network;

  @override
  Future<MasterDataResult> fetch(MasterDataType type) async {
    final fresh = _cache.readFresh(type);
    if (fresh != null) {
      return MasterDataResult(
        items: fresh,
        fromCache: true,
        isStale: false,
        cachedAt: _cache.cachedAt(type),
      );
    }

    if (!await _network.isConnected) {
      final stale = _cache.readStale(type);
      if (stale != null) return _staleResult(type, stale);
      throw const NetworkFailure(
        message: 'No connection, and this list has not been downloaded yet.',
      );
    }

    return _fetchRemote(type);
  }

  @override
  Future<MasterDataResult> refresh(MasterDataType type) async {
    if (!await _network.isConnected) {
      final stale = _cache.readStale(type);
      if (stale != null) return _staleResult(type, stale);
      throw const NetworkFailure();
    }
    return _fetchRemote(type);
  }

  @override
  Future<void> clearCache() => _cache.clear();

  Future<MasterDataResult> _fetchRemote(MasterDataType type) async {
    try {
      final items = await _remote.fetch(type);
      await _cache.write(type, items);
      return MasterDataResult(
        items: items,
        fromCache: false,
        isStale: false,
        cachedAt: DateTime.now(),
      );
    } on Failure {
      // A typed failure still shouldn't strand the user if we hold any copy.
      // Rethrowing only when there is genuinely nothing to show keeps the
      // dropdown usable through a transient SAP outage.
      final stale = _cache.readStale(type);
      if (stale != null) return _staleResult(type, stale);
      rethrow;
    }
  }

  MasterDataResult _staleResult(
          MasterDataType type, List<MasterDataItem> items) =>
      MasterDataResult(
        items: items,
        fromCache: true,
        isStale: true,
        cachedAt: _cache.cachedAt(type),
      );
}
