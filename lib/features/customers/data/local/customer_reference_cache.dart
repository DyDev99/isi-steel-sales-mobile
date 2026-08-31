import 'dart:convert';

import 'package:isi_steel_sales_mobile/core/database/hive/local_cache.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/customer_datasources.dart';

/// Hive-backed store for the SAP reference catalogues served by
/// `GET /mobile/customers/references`.
///
/// Hive rather than Drift for the same reason as [MasterDataCache]: these are
/// regenerable ERP lookups, not business records, so they belong in Layer 2 and
/// need no schema migration (ADR-009).
///
/// Fresh / stale / stamp, mirroring [MasterDataCache]. The stale mirror is what
/// makes the offline promise work: once the TTL lapses the fresh read is gone,
/// but a stale copy still beats an empty dropdown for a rep registering a shop
/// with no signal. `synchronisedAt` travels with the payload so staleness stays
/// visible.
class CustomerReferenceCache {
  const CustomerReferenceCache(this._cache,
      {this.ttl = const Duration(days: 7)});

  final LocalCache _cache;

  /// SAP org structure changes rarely; a week avoids pointless refetching while
  /// still self-healing without a manual cache clear.
  final Duration ttl;

  static const String _freshKey = 'sap_customer_references';
  static const String _staleKey = 'sap_customer_references:stale';
  static const String _stampKey = 'sap_customer_references:at';

  /// Non-expired catalogues, or null once the TTL has lapsed.
  CustomerReferenceCatalogue? readFresh() =>
      _decode(_cache.get<String>(_freshKey));

  /// The last successfully-fetched catalogues regardless of age. Only surfaced
  /// when the network could not be reached.
  CustomerReferenceCatalogue? readStale() =>
      _decode(_cache.get<String>(_staleKey));

  DateTime? cachedAt() {
    final raw = _cache.get<int>(_stampKey);
    return raw == null ? null : DateTime.fromMillisecondsSinceEpoch(raw);
  }

  Future<void> write(CustomerReferenceCatalogue catalogue) async {
    // Stored as a JSON string rather than a nested map: Hive round-trips
    // `Map<dynamic, dynamic>` for nested structures, and the cast back is where
    // this kind of cache usually starts throwing.
    final encoded = jsonEncode(catalogue.values);
    await _cache.set(_freshKey, encoded, ttl: ttl);
    await _cache.set(_staleKey, encoded);
    await _cache.set(_stampKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> clear() async {
    await _cache.remove(_freshKey);
    await _cache.remove(_staleKey);
    await _cache.remove(_stampKey);
  }

  /// Tolerates a shape change in cached JSON by discarding it rather than
  /// throwing — a decode failure must degrade to a refetch, never a crash.
  CustomerReferenceCatalogue? _decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return CustomerReferenceCatalogue(decoded.cast<String, dynamic>());
    } on Object {
      return null;
    }
  }
}
