import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/app_database.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/logging/app_logger.dart';
import 'package:isi_steel_sales_mobile/core/network/network_info.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/route_drift_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/visit_drift_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/local/workflow_state_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/remote/visit_push_batch.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/remote/visit_push_result.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/remote/visit_sync_remote_data_source.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/repositories/active_workflow_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/repositories/route_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/repositories/visit_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/repositories/visit_sync_repository_impl.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/active_workflow.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/stock_level.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/entities/visit_workflow.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/repositories/active_workflow_repository.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/repositories/route_repository.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/repositories/visit_repository.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/repositories/visit_sync_repository.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/add_stock_update.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/check_out.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/complete_visit_check_out.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/get_active_workflow.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/push_pending_visit_data.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/save_active_workflow.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/update_stop_status.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/domain/usecases/update_workflow_step.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/navigation/open_inventory_visibility.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/inventory_visible/inventory_completion_screen.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/presentation/screens/inventory_visible/inventory_visible_screen.dart';

class _FakeOnlineNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
}

class _RecordingVisitSyncRemoteDataSource implements VisitSyncRemoteDataSource {
  final List<VisitPushBatch> pushedBatches = [];

  @override
  Future<VisitPushResult> pushVisitData(VisitPushBatch batch) async {
    pushedBatches.add(batch);
    final allIds = [
      ...batch.checkIns.map((c) => c.id),
      ...batch.checkOuts.map((c) => c.id),
      ...batch.stockUpdates.map((s) => s.id),
      ...batch.notes.map((n) => n.id),
      ...batch.photos.map((p) => p.id),
    ];
    return VisitPushResult(
      acceptedIds: allIds,
      rejectedIds: const [],
      syncedAt: DateTime.now(),
    );
  }
}

void main() {
  late AppDatabase db;
  late VisitDriftLocalDataSource visitLocal;
  late RouteDriftLocalDataSource routeLocal;
  late RouteRepository routes;
  late VisitRepository visits;
  late ActiveWorkflowRepository workflows;
  late _RecordingVisitSyncRemoteDataSource fakeRemote;
  late VisitSyncRepository visitSyncRepo;

  const routeId = 'route-101';
  const stopId = 'stop-202';
  const customerId = 'cust-303';
  const customerName = 'ISI Depot Kampot';

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await LocalizationService.instance.load('en');
  });

  setUp(() async {
    await GetIt.instance.reset();
    db = AppDatabase(NativeDatabase.memory());
    const logger = ConsoleAppLogger(verbose: false);
    visitLocal = VisitDriftLocalDataSource(db.visitDao, logger);
    routeLocal = RouteDriftLocalDataSource(db.routeDao, logger);
    routes = RouteRepositoryImpl(routeLocal);
    visits = VisitRepositoryImpl(visitLocal);
    workflows = ActiveWorkflowRepositoryImpl(
        WorkflowStateLocalDataSourceImpl(db.workflowStateDao));
    fakeRemote = _RecordingVisitSyncRemoteDataSource();
    visitSyncRepo = VisitSyncRepositoryImpl(
      remote: fakeRemote,
      local: visitLocal,
      network: _FakeOnlineNetworkInfo(),
    );

    // Register in DI
    GetIt.instance
      ..registerSingleton<AppDatabase>(db)
      ..registerSingleton<RouteRepository>(routes)
      ..registerSingleton<VisitRepository>(visits)
      ..registerSingleton<ActiveWorkflowRepository>(workflows)
      ..registerSingleton<VisitSyncRepository>(visitSyncRepo)
      ..registerSingleton<AddStockUpdate>(AddStockUpdate(visits))
      ..registerSingleton<GetActiveWorkflow>(GetActiveWorkflow(workflows))
      ..registerSingleton<SaveActiveWorkflow>(SaveActiveWorkflow(workflows))
      ..registerSingleton<UpdateWorkflowStep>(UpdateWorkflowStep(workflows))
      ..registerSingleton<CompleteVisitCheckOut>(CompleteVisitCheckOut(
        workflows,
        routes,
        CheckOut(visits),
        UpdateStopStatus(routes),
      ))
      ..registerSingleton<PushPendingVisitData>(
          PushPendingVisitData(visitSyncRepo));

    await _seedVisitData(
      db,
      workflows: workflows,
      routeId: routeId,
      stopId: stopId,
      customerId: customerId,
      customerName: customerName,
    );
  });

  tearDown(() async {
    await db.close();
    await GetIt.instance.reset();
  });

  testWidgets(
      'Inventory audit submits stock updates and Complete Visit pushes check-out + stock updates to remote',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final navKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, _) => MaterialApp(
          navigatorKey: navKey,
          home: const Scaffold(body: Text('Root Route Dashboard')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Open Inventory Visibility for the checked-in stop
    openInventoryVisibilityForCustomer(
      navKey.currentContext!,
      customerId: customerId,
      customerName: customerName,
      stopId: stopId,
    );
    await tester.pumpAndSettle();

    // 2. Rep judges all 4 items
    for (var i = 0; i < 4; i++) {
      final option = find.text('High stock').at(i);
      await tester.ensureVisible(option);
      await tester.pumpAndSettle();
      await tester.tap(option);
      await tester.pumpAndSettle();
    }

    // 3. Submit the inventory audit
    final submitBtn = find.byType(ElevatedButton);
    await tester.tap(submitBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // Verify stock updates are stored locally in visit storage
    final pendingStockUpdates = await visitLocal.fetchPendingStockUpdates();
    expect(pendingStockUpdates.length, 4,
        reason: 'all 4 judged stock items should be stored');
    for (final su in pendingStockUpdates) {
      expect(su.stopId, stopId);
      expect(su.stockLevel, StockLevel.high);
    }

    // 4. Rep is now on Inventory Completion screen
    expect(find.byType(InventoryCompletionScreen), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);

    // 5. Tap Complete Visit
    await tester.tap(find.byType(OutlinedButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // 6. Navigation popped back to root
    expect(find.text('Root Route Dashboard'), findsOneWidget);

    // 7. Verify push batch reached remote data source
    expect(fakeRemote.pushedBatches.length, 1);
    final batch = fakeRemote.pushedBatches.first;
    expect(batch.checkOuts.length, 1,
        reason: 'CheckOutRecord must be included in the push batch');
    expect(batch.checkOuts.first.stopId, stopId);
    expect(batch.stockUpdates.length, 4,
        reason: 'All 4 StockUpdate records must be included in the push batch');

    // 8. Verify all items are now marked synced in database
    final remainingPendingStock = await visitLocal.fetchPendingStockUpdates();
    final remainingPendingCheckOuts = await visitLocal.fetchPendingCheckOuts();
    expect(remainingPendingStock, isEmpty);
    expect(remainingPendingCheckOuts, isEmpty);
  });
}

Future<void> _seedVisitData(
  AppDatabase db, {
  required ActiveWorkflowRepository workflows,
  required String routeId,
  required String stopId,
  required String customerId,
  required String customerName,
}) async {
  final now = DateTime.now().toUtc();
  final day = DateTime.utc(now.year, now.month, now.day);

  await db.into(db.customers).insert(CustomersCompanion.insert(
        id: customerId,
        sapCustomerId: const Value('SAP-101'),
        customerCode: 'C-101',
        shopName: customerName,
        ownerName: 'Owner Sok',
        phone: '012345678',
        address: 'Main Road',
        province: 'Kampot',
        district: 'Center',
        territory: 'KAMPOT-1',
        latitude: 10.6,
        longitude: 104.18,
        creditLimit: 5000,
        status: 'active',
        assignedRepId: 'rep-1',
        assignedRepName: 'Rep One',
        updatedAt: now,
        territoryType: const Value('urban'),
      ));

  await db.into(db.routes).insert(RoutesCompanion.insert(
        id: routeId,
        name: 'Route Kampot',
        repId: 'rep-1',
        repName: 'Rep One',
        territory: 'KAMPOT-1',
        visitDate: day,
        plannedStart: day.add(const Duration(hours: 8)),
        plannedEnd: day.add(const Duration(hours: 17)),
        status: 'inProgress',
      ));

  await db.into(db.routeStops).insert(RouteStopsCompanion.insert(
        id: stopId,
        routeId: routeId,
        customerId: customerId,
        sequence: 1,
        plannedArrival: day.add(const Duration(hours: 9)),
        plannedDeparture: day.add(const Duration(hours: 10)),
        status: 'checkedIn',
        actualArrival: Value(now.subtract(const Duration(minutes: 15))),
      ));

  await workflows.saveActiveWorkflow(ActiveWorkflow(
    routeId: routeId,
    currentStopId: stopId,
    dayStarted: true,
    updatedAt: now,
    customerId: customerId,
    shopName: customerName,
    checkInAt: now.subtract(const Duration(minutes: 15)),
    currentWorkflow: VisitWorkflow.stockCount,
    currentScreen: InventoryVisibilityScreen.routeName,
    navigationArguments: {
      'stopId': stopId,
      'customerId': customerId,
      'customerName': customerName,
    },
  ));
}
