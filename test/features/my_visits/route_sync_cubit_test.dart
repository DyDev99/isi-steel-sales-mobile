import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/error/failures.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';
import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/core/utils/result.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_sync_result.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_paged_result.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/browse_customers.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/customer_params.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/get_customer_last_synced_at.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/usecases/run_customer_initial_sync.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_sync_result.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/route_sync_scope.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_push_summary.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/get_route_last_synced_at.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/push_pending_visit_data.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/run_route_delta_sync.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/run_route_initial_sync.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/cubit/route_sync_cubit.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/bloc/state/route_sync_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockRunRouteInitialSync extends Mock implements RunRouteInitialSync {}

class _MockRunRouteDeltaSync extends Mock implements RunRouteDeltaSync {}

class _MockGetRouteLastSyncedAt extends Mock implements GetRouteLastSyncedAt {}

class _MockPushPendingVisitData extends Mock implements PushPendingVisitData {}

class _MockRunCustomerInitialSync extends Mock
    implements RunCustomerInitialSync {}

class _MockGetCustomerLastSyncedAt extends Mock
    implements GetCustomerLastSyncedAt {}

class _MockBrowseCustomers extends Mock implements BrowseCustomers {}

/// Only its presence in the list matters — the gate asks "are there any rows",
/// never what is in them.
class _FakeCustomer extends Mock implements Customer {}

class _MockSessionManager extends Mock implements SessionManager {}

void main() {
  // Fixed, UTC-anchored instant — RouteSyncSucceeded equality includes
  // syncedAt, and visit dates in this feature are UTC-anchored by convention.
  final syncedAt = DateTime.utc(2026, 7, 22, 3);
  final routeResult =
      RouteSyncResult(upserted: 3, deleted: 0, syncedAt: syncedAt);
  final customerResult =
      CustomerSyncResult(upserted: 6, deleted: 0, syncedAt: syncedAt);

  late _MockRunRouteInitialSync runRouteInitialSync;
  late _MockRunRouteDeltaSync runRouteDeltaSync;
  late _MockGetRouteLastSyncedAt getRouteLastSyncedAt;
  late _MockPushPendingVisitData pushPendingVisitData;
  late _MockRunCustomerInitialSync runCustomerInitialSync;
  late _MockGetCustomerLastSyncedAt getCustomerLastSyncedAt;
  late _MockBrowseCustomers browseCustomers;
  late _MockSessionManager sessionManager;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
        const RouteSyncScope(repId: 'guest', territory: 'Phnom Penh'));
    registerFallbackValue(const BrowseCustomersParams(page: 0, pageSize: 1));
  });

  setUp(() {
    runRouteInitialSync = _MockRunRouteInitialSync();
    runRouteDeltaSync = _MockRunRouteDeltaSync();
    getRouteLastSyncedAt = _MockGetRouteLastSyncedAt();
    pushPendingVisitData = _MockPushPendingVisitData();
    runCustomerInitialSync = _MockRunCustomerInitialSync();
    getCustomerLastSyncedAt = _MockGetCustomerLastSyncedAt();
    browseCustomers = _MockBrowseCustomers();
    // Default: the directory has rows. Tests that care override this.
    when(() => browseCustomers(any())).thenAnswer((_) async => Success(
        CustomerPagedResult(
            items: [_FakeCustomer()], page: 0, hasMore: false)));
    sessionManager = _MockSessionManager();
    when(() => sessionManager.currentUser).thenReturn(null);
  });

  RouteSyncCubit buildCubit() => RouteSyncCubit(
        runInitialSync: runRouteInitialSync,
        runDeltaSync: runRouteDeltaSync,
        getLastSyncedAt: getRouteLastSyncedAt,
        pushPendingVisitData: pushPendingVisitData,
        runCustomerInitialSync: runCustomerInitialSync,
        getCustomerLastSyncedAt: getCustomerLastSyncedAt,
        browseCustomers: browseCustomers,
        sessionManager: sessionManager,
      );

  // ── Stub helpers so each test reads as its scenario ─────────────────
  void customersAlreadySynced() => when(() => getCustomerLastSyncedAt(any()))
      .thenAnswer((_) async => Success(syncedAt));

  void customersNeverSynced() => when(() => getCustomerLastSyncedAt(any()))
      .thenAnswer((_) async => const Success<DateTime?>(null));

  void routesNeverSynced() => when(() => getRouteLastSyncedAt(any()))
      .thenAnswer((_) async => const Success<DateTime?>(null));

  void routesPreviouslySynced() => when(() => getRouteLastSyncedAt(any()))
      .thenAnswer((_) async => Success(syncedAt));

  void routeInitialSucceeds() => when(() => runRouteInitialSync(any()))
      .thenAnswer((_) async => Success(routeResult));

  void routeDeltaSucceeds() => when(() => runRouteDeltaSync(any()))
      .thenAnswer((_) async => Success(routeResult));

  void customerInitialSucceeds() => when(() => runCustomerInitialSync(any()))
      .thenAnswer((_) async => Success(customerResult));

  void customerDirectoryEmpty() =>
      when(() => browseCustomers(any())).thenAnswer((_) async => const Success(
          CustomerPagedResult(items: [], page: 0, hasMore: false)));

  group('syncIfNeeded', () {
    blocTest<RouteSyncCubit, RouteSyncState>(
      'pulls customers when the watermark says synced but the table is empty',
      build: buildCubit,
      setUp: () {
        // The state behind the empty Visit dashboards: a customer watermark
        // left by an earlier build over a directory that is actually empty.
        // Skipping the pull here left the route feed — which rebases stops
        // onto real customer ids — with nothing to rebase onto, so every
        // Visit screen came up blank.
        customersAlreadySynced();
        customerDirectoryEmpty();
        customerInitialSucceeds();
        routesPreviouslySynced();
        routeDeltaSucceeds();
      },
      act: (cubit) => cubit.syncIfNeeded(),
      verify: (_) {
        verify(() => runCustomerInitialSync(any())).called(1);
        verify(() => runRouteDeltaSync(any())).called(1);
      },
    );

    blocTest<RouteSyncCubit, RouteSyncState>(
      'skips the customer pull when the directory is genuinely populated',
      build: buildCubit,
      setUp: () {
        customersAlreadySynced();
        routesPreviouslySynced();
        routeDeltaSucceeds();
      },
      act: (cubit) => cubit.syncIfNeeded(),
      verify: (_) => verifyNever(() => runCustomerInitialSync(any())),
    );

    blocTest<RouteSyncCubit, RouteSyncState>(
      'runs an initial route sync when there is no route watermark',
      build: buildCubit,
      setUp: () {
        routesNeverSynced();
        customersAlreadySynced();
        routeInitialSucceeds();
      },
      act: (cubit) => cubit.syncIfNeeded(),
      expect: () => [
        const RouteSyncInProgress(isInitial: true),
        RouteSyncSucceeded(upserted: 3, syncedAt: syncedAt),
      ],
      verify: (_) {
        verify(() => runRouteInitialSync(any())).called(1);
        verifyNever(() => runRouteDeltaSync(any()));
      },
    );

    blocTest<RouteSyncCubit, RouteSyncState>(
      'runs a delta sync when a route watermark exists',
      build: buildCubit,
      setUp: () {
        routesPreviouslySynced();
        customersAlreadySynced();
        routeDeltaSucceeds();
      },
      act: (cubit) => cubit.syncIfNeeded(),
      expect: () => [
        const RouteSyncInProgress(isInitial: false),
        RouteSyncSucceeded(upserted: 3, syncedAt: syncedAt),
      ],
      verify: (_) {
        verify(() => runRouteDeltaSync(any())).called(1);
        verifyNever(() => runRouteInitialSync(any()));
      },
    );

    blocTest<RouteSyncCubit, RouteSyncState>(
      'falls back to an initial sync when the route watermark read fails',
      build: buildCubit,
      setUp: () {
        when(() => getRouteLastSyncedAt(any())).thenAnswer(
            (_) async => const Failed(CacheFailure(message: 'db closed')));
        customersAlreadySynced();
        routeInitialSucceeds();
      },
      act: (cubit) => cubit.syncIfNeeded(),
      expect: () => [
        const RouteSyncInProgress(isInitial: true),
        RouteSyncSucceeded(upserted: 3, syncedAt: syncedAt),
      ],
      verify: (_) => verify(() => runRouteInitialSync(any())).called(1),
    );

    blocTest<RouteSyncCubit, RouteSyncState>(
      'surfaces a route sync failure as RouteSyncFailed',
      build: buildCubit,
      setUp: () {
        routesNeverSynced();
        customersAlreadySynced();
        when(() => runRouteInitialSync(any())).thenAnswer((_) async =>
            const Failed(ServerFailure(message: 'boom', statusCode: 500)));
      },
      act: (cubit) => cubit.syncIfNeeded(),
      expect: () => [
        const RouteSyncInProgress(isInitial: true),
        const RouteSyncFailed('boom'),
      ],
    );
  });

  group('customer-directory ordering guard (ADR-001 FK dependency)', () {
    blocTest<RouteSyncCubit, RouteSyncState>(
      'skips customer sync entirely once the customer watermark exists',
      build: buildCubit,
      setUp: () {
        routesNeverSynced();
        customersAlreadySynced();
        routeInitialSucceeds();
      },
      act: (cubit) => cubit.syncIfNeeded(),
      verify: (_) => verifyNever(() => runCustomerInitialSync(any())),
    );

    blocTest<RouteSyncCubit, RouteSyncState>(
      'fresh install: awaits customer initial sync before the route pull',
      build: buildCubit,
      setUp: () {
        routesNeverSynced();
        customersNeverSynced();
        customerInitialSucceeds();
        routeInitialSucceeds();
      },
      act: (cubit) => cubit.syncIfNeeded(),
      expect: () => [
        const RouteSyncInProgress(isInitial: true),
        RouteSyncSucceeded(upserted: 3, syncedAt: syncedAt),
      ],
      verify: (_) => verifyInOrder([
        () => runCustomerInitialSync(any()),
        () => runRouteInitialSync(any()),
      ]),
    );

    blocTest<RouteSyncCubit, RouteSyncState>(
      'fails fast when customer sync fails — no route pull is attempted',
      build: buildCubit,
      setUp: () {
        routesNeverSynced();
        customersNeverSynced();
        when(() => runCustomerInitialSync(any()))
            .thenAnswer((_) async => const Failed(NetworkFailure()));
      },
      act: (cubit) => cubit.syncIfNeeded(),
      expect: () => [
        const RouteSyncInProgress(isInitial: true),
        const RouteSyncFailed('No internet connection.'),
      ],
      verify: (_) {
        verifyNever(() => runRouteInitialSync(any()));
        verifyNever(() => runRouteDeltaSync(any()));
      },
    );

    blocTest<RouteSyncCubit, RouteSyncState>(
      'treats a customer watermark read failure as needing customer sync',
      build: buildCubit,
      setUp: () {
        routesNeverSynced();
        when(() => getCustomerLastSyncedAt(any())).thenAnswer(
            (_) async => const Failed(CacheFailure(message: 'db closed')));
        customerInitialSucceeds();
        routeInitialSucceeds();
      },
      act: (cubit) => cubit.syncIfNeeded(),
      expect: () => [
        const RouteSyncInProgress(isInitial: true),
        RouteSyncSucceeded(upserted: 3, syncedAt: syncedAt),
      ],
      verify: (_) => verify(() => runCustomerInitialSync(any())).called(1),
    );
  });

  group('refresh', () {
    blocTest<RouteSyncCubit, RouteSyncState>(
      'always runs a delta sync, still behind the customer guard',
      build: buildCubit,
      setUp: () {
        customersAlreadySynced();
        routeDeltaSucceeds();
      },
      act: (cubit) => cubit.refresh(),
      expect: () => [
        const RouteSyncInProgress(isInitial: false),
        RouteSyncSucceeded(upserted: 3, syncedAt: syncedAt),
      ],
      verify: (_) {
        verify(() => getCustomerLastSyncedAt(any())).called(1);
        verifyNever(() => runRouteInitialSync(any()));
      },
    );
  });

  group('pushPending', () {
    blocTest<RouteSyncCubit, RouteSyncState>(
      'reports pushed rows as a sync success',
      build: buildCubit,
      setUp: () => when(() => pushPendingVisitData(any())).thenAnswer(
          (_) async =>
              Success(VisitPushSummary(pushedCount: 4, syncedAt: syncedAt))),
      act: (cubit) => cubit.pushPending(),
      expect: () => [
        const RouteSyncInProgress(isInitial: false),
        RouteSyncSucceeded(upserted: 4, syncedAt: syncedAt),
      ],
    );

    blocTest<RouteSyncCubit, RouteSyncState>(
      'surfaces a push failure as RouteSyncFailed',
      build: buildCubit,
      setUp: () => when(() => pushPendingVisitData(any())).thenAnswer(
          (_) async => const Failed(ServerFailure(message: 'push rejected'))),
      act: (cubit) => cubit.pushPending(),
      expect: () => [
        const RouteSyncInProgress(isInitial: false),
        const RouteSyncFailed('push rejected'),
      ],
    );
  });
}
