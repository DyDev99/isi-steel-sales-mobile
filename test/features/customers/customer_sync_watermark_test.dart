import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/logging/app_logger.dart';
import 'package:isi_steel_sales_mobile/core/network/network_info.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/local/customer_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/customer_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/customer_sync_page.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/repositories/customer_sync_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_status.dart';
import 'package:mocktail/mocktail.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_code_lookup.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_draft.dart';

class _MockLocal extends Mock implements CustomerLocalDataSource {}

class _MockNetwork extends Mock implements NetworkInfo {}

/// A scripted remote that hands back pre-built pages and records what it was
/// asked for.
class _ScriptedRemote implements CustomerRemoteDataSource {
  _ScriptedRemote({this.initial = const [], this.deltas = const []});

  final List<CustomerInitialPage> initial;
  final List<CustomerDeltaPage> deltas;

  final List<int> initialPagesRequested = [];
  final List<DateTime> deltaSinceRequested = [];

  @override
  Future<CustomerInitialPage> fetchInitial({
    required int page,
    required int pageSize,
  }) async {
    initialPagesRequested.add(page);
    return initial[initialPagesRequested.length - 1];
  }

  @override
  Future<CustomerDeltaPage> fetchDelta({
    required DateTime since,
    int page = 1,
    int pageSize = 200,
  }) async {
    deltaSinceRequested.add(since);
    return deltas[deltaSinceRequested.length - 1];
  }

  @override
  Future<CustomerModel> create(CustomerDraft draft) =>
      throw UnimplementedError('these tests exercise sync, not creation');

  @override
  Future<CustomerModel> fetchById(String id) async =>
      throw UnimplementedError();

  @override
  Future<CustomerCodeLookup> lookupByCode(String code) =>
      throw UnimplementedError('these tests exercise sync, not code lookup');
}

CustomerModel _customer(String id) => CustomerModel(
      id: id,
      sapCustomerId: 'SAP-$id',
      customerCode: 'ISI-$id',
      shopName: 'Shop $id',
      ownerName: 'Owner',
      phone: '012345678',
      address: 'Street 1',
      province: 'Phnom Penh',
      district: 'Toul Kork',
      territory: 'PP-NORTH',
      latitude: 11.5,
      longitude: 104.9,
      creditLimit: 0,
      status: CustomerStatus.active,
      assignedRepId: 'rep-1',
      assignedRepName: 'Rep',
      updatedAt: DateTime.utc(2026, 8, 12),
    );

void main() {
  late _MockLocal local;
  late _MockNetwork network;

  // The server's clock. Deliberately far from any plausible device clock so a
  // test that accidentally stored `DateTime.now()` fails loudly.
  final serverTime = DateTime.utc(2026, 8, 12, 9, 44, 12);

  setUp(() {
    local = _MockLocal();
    network = _MockNetwork();
    when(() => network.isConnected).thenAnswer((_) async => true);
    when(() => local.upsertCustomers(any())).thenAnswer((_) async {});
    when(() => local.markDeleted(any())).thenAnswer((_) async {});
    when(() => local.setLastSyncedAt(any(), any(),
        language: any(named: 'language'))).thenAnswer((_) async {});
    // Unknown by default, which the repository reads as "matches" — these
    // tests are about the watermark, not the language guard.
    when(() => local.getSyncedLanguage(any())).thenAnswer((_) async => null);
  });

  CustomerSyncRepositoryImpl build(_ScriptedRemote remote) =>
      CustomerSyncRepositoryImpl(
        remote: remote,
        local: local,
        network: network,
        logger: const ConsoleAppLogger(verbose: false),
      );

  group('initial sync', () {
    test('stores the server syncTimestamp, never the device clock', () async {
      // A phone running fast would otherwise ask for changes since the future,
      // receive an empty delta, store *that*, and never sync again — a silent,
      // permanent failure.
      final remote = _ScriptedRemote(initial: [
        CustomerInitialPage(
          items: [_customer('a')],
          hasMore: false,
          syncTimestamp: serverTime,
        ),
      ]);

      final result = await build(remote).runInitialSync();

      expect(result, isA<Success<dynamic>>());
      verify(() => local.setLastSyncedAt('customers', serverTime,
          language: any(named: 'language'))).called(1);
    });

    test('pages from 1, because the API is one-based', () async {
      final remote = _ScriptedRemote(initial: [
        CustomerInitialPage(
            items: [_customer('a')], hasMore: true, syncTimestamp: serverTime),
        CustomerInitialPage(
            items: [_customer('b')],
            hasMore: false,
            syncTimestamp: serverTime.add(const Duration(seconds: 5))),
      ]);

      await build(remote).runInitialSync();

      // Page 0 would be silently treated as page 1 and re-fetch the first page.
      expect(remote.initialPagesRequested, [1, 2]);
    });

    test('keeps the first page timestamp across a multi-page run', () async {
      // Taking the last page's timestamp would skip anything changed while the
      // run was in flight.
      final remote = _ScriptedRemote(initial: [
        CustomerInitialPage(
            items: [_customer('a')], hasMore: true, syncTimestamp: serverTime),
        CustomerInitialPage(
            items: [_customer('b')],
            hasMore: false,
            syncTimestamp: serverTime.add(const Duration(minutes: 3))),
      ]);

      await build(remote).runInitialSync();

      verify(() => local.setLastSyncedAt('customers', serverTime,
          language: any(named: 'language'))).called(1);
    });

    _ScriptedRemote twoPages() => _ScriptedRemote(initial: [
          CustomerInitialPage(
              items: [_customer('a')],
              hasMore: true,
              syncTimestamp: serverTime),
          CustomerInitialPage(
              items: [_customer('b')],
              hasMore: false,
              syncTimestamp: serverTime),
        ]);

    test('commits the watermark after every page is applied', () async {
      // Advancing per page means an interrupted sync permanently skips
      // everything between the last committed page and the stored timestamp.
      await build(twoPages()).runInitialSync();

      verifyInOrder([
        () => local.upsertCustomers(any()),
        () => local.upsertCustomers(any()),
        () => local.setLastSyncedAt('customers', serverTime,
            language: any(named: 'language')),
      ]);
    });

    test('commits the watermark exactly once for the whole run', () async {
      await build(twoPages()).runInitialSync();

      verify(() => local.setLastSyncedAt(any(), any(),
          language: any(named: 'language'))).called(1);
    });
  });

  group('delta sync', () {
    setUp(() {
      when(() => local.getLastSyncedAt('customers'))
          .thenAnswer((_) async => serverTime);
    });

    test('asks for changes since the stored watermark', () async {
      final remote = _ScriptedRemote(deltas: [
        CustomerDeltaPage(
          upserted: const [],
          deletedIds: const [],
          syncTimestamp: serverTime.add(const Duration(hours: 1)),
        ),
      ]);

      await build(remote).runDeltaSync();

      expect(remote.deltaSinceRequested.single, serverTime);
    });

    test('applies tombstones instead of dropping them', () async {
      // Without this a customer deleted on the server simply stops appearing
      // in the delta and lingers on the phone indefinitely.
      final remote = _ScriptedRemote(deltas: [
        CustomerDeltaPage(
          upserted: [_customer('a')],
          deletedIds: const ['gone-1', 'gone-2'],
          syncTimestamp: serverTime.add(const Duration(hours: 1)),
        ),
      ]);

      final result = await build(remote).runDeltaSync();

      verify(() => local.markDeleted(['gone-1', 'gone-2'])).called(1);
      expect(
        (result as Success).data.deleted,
        2,
      );
    });

    test('holds the old watermark when the server sends none', () async {
      // Repeating a delta is free; skipping the window between `since` and now
      // loses records permanently.
      final remote = _ScriptedRemote(deltas: [
        const CustomerDeltaPage(upserted: [], deletedIds: []),
      ]);

      await build(remote).runDeltaSync();

      verify(() => local.setLastSyncedAt('customers', serverTime,
          language: any(named: 'language'))).called(1);
    });

    test('falls back to a full sync when there is no watermark', () async {
      when(() => local.getLastSyncedAt('customers'))
          .thenAnswer((_) async => null);

      final remote = _ScriptedRemote(initial: [
        CustomerInitialPage(
            items: [_customer('a')], hasMore: false, syncTimestamp: serverTime),
      ]);

      await build(remote).runDeltaSync();

      expect(remote.initialPagesRequested, [1]);
      expect(remote.deltaSinceRequested, isEmpty);
    });
  });
}
