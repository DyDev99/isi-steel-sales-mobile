import 'package:isi_steel_sales_mobile/core/database/drift/app_database.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/migrations/legacy_route_source.dart';
import 'package:isi_steel_sales_mobile/core/database/drift/migrations/legacy_routes_importer.dart';
import 'package:isi_steel_sales_mobile/core/database/hive/hive_service.dart';
import 'package:isi_steel_sales_mobile/core/di/injection_container.dart';
import 'package:isi_steel_sales_mobile/core/logging/app_logger.dart';
import 'package:isi_steel_sales_mobile/core/network/connectivity_service.dart';

/// Prepares the application before any feature loads.
///
/// ## Two rules this service exists to enforce
///
/// **1. Boot never blocks on the network** (ADR-002 §3, `docs/OFFLINE_FIRST.md`
/// §2.6). A signed-in rep standing in a warehouse with no signal must reach
/// their data. Therefore this service performs **no** token validation, **no**
/// token refresh, and **no** master-data download. Token refresh is lazy — the
/// network interceptor does it on the first real request, or the sync
/// coordinator does it opportunistically once [ConnectivityService] reports
/// reachable. A failed refresh **never** logs the user out; only a definitive
/// server rejection (refresh token revoked) does, and that cannot be known
/// offline.
///
/// **2. Bootstrap never navigates** (`docs/OFFLINE_FIRST.md` §2.2, ADR-002 §5).
/// Each surface owns its own transition; `SplashScreen` decides
/// `main` vs `chooseLanguage` from `onboarding_complete`. A central
/// bootstrap-driven redirect is the exact global-listener pattern that was
/// already tried, caused guest redirect loops, and was reverted — it is listed
/// as an anti-pattern in `docs/AI_ENGINEERING_PLAYBOOK.md` §12.
///
/// Auth resolution itself stays where it already works: `AuthBloc`
/// (`AuthCheckRequested`) resolves the cached session in the background and
/// mirrors it into `SessionManager` (`docs/OFFLINE_FIRST.md` §2.1/§2.3). This
/// service does not duplicate that.
///
/// ## Ordering note
///
/// The encrypted `AppDatabase` is registered inside [initDependencies] as a lazy
/// singleton and opens on first use, so "init DI" *is* "init the database" —
/// they are not separate ordered steps. Hive must be opened **before** DI
/// because `AppPreferences` resolves `HiveService.cacheBox`.
class AppBootstrapService {
  const AppBootstrapService();

  /// Runs the boot sequence. Safe to await before `runApp`; performs no I/O
  /// that can hang on a dead network.
  Future<BootstrapResult> run() async {
    // 1–2. Config + logger. The logger is constructed directly rather than
    // resolved from DI because it must be able to report a DI failure.
    const AppLogger logger = ConsoleAppLogger();
    logger.info('bootstrap.started');

    try {
      // 3. Key-value store. Must precede DI (see class doc).
      await HiveService.init();
      logger.info('bootstrap.hive_ready');

      // 4. DI — also registers the encrypted AppDatabase (opens lazily) and
      //    secure storage. Sprint 1 crypto (T1.0–T1.4, T1.6) is already built:
      //    the composite key and fail-closed cipher check run at first open.
      await initDependencies();
      logger.info('bootstrap.di_ready');

      // 5. Legacy plaintext → encrypted import (T1.5). Runs at most once, before
      //    any feature reads, so no screen can observe a half-migrated store.
      //    Local disk work only — no network, so ADR-002 §3 holds.
      await _importLegacyRoutes(logger);

      // 6. Session restore: intentionally a no-op here. AuthBloc's
      //    AuthCheckRequested reads the cached user from secure storage in the
      //    background with zero network calls (OFFLINE_FIRST §2.1, §2.5).

      // 7. Connectivity. Started last so a slow reachability probe can never
      //    delay first frame — start() kicks off an async probe and returns;
      //    the initial state is `offline` until the probe proves otherwise.
      final connectivity = sl<ConnectivityService>();
      await connectivity.start();
      logger.info('bootstrap.connectivity_started',
          fields: {'status': connectivity.status.name});

      logger.info('bootstrap.completed');
      return const BootstrapResult.success();
    } catch (error, stackTrace) {
      // A bootstrap failure is not recoverable here, but it must never surface
      // as a raw exception (ENGINEERING_STANDARD §7) and must never be
      // swallowed silently (playbook §12).
      logger.error('bootstrap.failed', error: error, stackTrace: stackTrace);
      return BootstrapResult.failure(error.runtimeType.toString());
    }
  }
}

/// Runs the T1.5 legacy import, then purges the plaintext source **only** if the
/// import was verifiably complete.
///
/// This is the step that actually removes customer PII and employee GPS traces
/// from unencrypted storage — the top entry in `docs/MIGRATION_PLAN.md` §9's
/// risk register. Two rules govern it:
///
/// 1. **Verify, then purge.** `safeToPurge` is false if anything was skipped
///    (an orphan stop, an unknown customer). Those rows exist *only* in the
///    plaintext file, so deleting it would destroy them. We would rather leave
///    plaintext on disk for one more release than lose a rep's captures.
/// 2. **A failed import never blocks boot.** The importer rolls its transaction
///    back and rethrows; we log and continue. The app still opens on encrypted
///    data — offline is a normal state, not an error screen (ADR-002 §4) — and
///    the import retries on the next launch because no marker was written.
Future<void> _importLegacyRoutes(AppLogger logger) async {
  final importer = LegacyRoutesImporter(
    db: sl<AppDatabase>(),
    source: SqfliteLegacyRouteSource(),
    logger: logger,
  );

  try {
    final result = await importer.import();
    if (result.alreadyDone || result.sourceMissing) return;

    logger.info('bootstrap.legacy_import', fields: {
      'imported': result.totalImported,
      'skipped': result.totalSkipped,
    });

    if (result.safeToPurge) {
      await importer.purgeLegacyData();
      logger.warning('bootstrap.legacy_plaintext_purged');
    } else {
      // Deliberately loud: plaintext PII is still on disk and a human needs to
      // know why. The usual cause is a stop whose customer the directory has
      // not synced yet — the next customer sync fixes it and the following
      // launch retries.
      logger.error('bootstrap.legacy_purge_withheld', fields: {
        'skipped': result.totalSkipped,
      });
    }
  } catch (error, stackTrace) {
    logger.error('bootstrap.legacy_import_failed',
        error: error, stackTrace: stackTrace);
  }
}

/// Outcome of [AppBootstrapService.run].
///
/// A sealed result rather than a thrown exception so `main` can decide how to
/// degrade without a `try`/`catch` around `runApp`.
sealed class BootstrapResult {
  const BootstrapResult();

  const factory BootstrapResult.success() = BootstrapSuccess;
  const factory BootstrapResult.failure(String reason) = BootstrapFailure;

  bool get isSuccess => this is BootstrapSuccess;
}

final class BootstrapSuccess extends BootstrapResult {
  const BootstrapSuccess();
}

final class BootstrapFailure extends BootstrapResult {
  const BootstrapFailure(this.reason);

  /// Exception *type* only — never a message, which could embed PII
  /// (`docs/SECURITY.md` §10).
  final String reason;
}

// ─────────────────────────────────────────────────────────────────────────────
// Not yet wired — tracked infrastructure, NOT forgotten steps.
//
// These boot steps are specified but blocked on infrastructure that does not
// exist yet. Per `docs/ENGINEERING_STANDARD.md` §2 and `docs/ARCHITECTURE.md`
// §4, they must not be built ahead of their dependencies:
//
//   • Sync-queue crash recovery (inFlight → queued) — `docs/SYNC_ENGINE.md` §7.
//     Blocked on: a Drift `sync_queue` table + `SyncQueueDao` (Phase 2), and
//     promoting the Orders feature's working queue into `core/sync/` (ADR-006).
//
//   • SyncCoordinator start — `docs/SYNC_ENGINE.md` §9. Blocked on the above.
//
//   • WorkflowSession resume check — `docs/OFFLINE_FIRST.md` §3, ADR-007.
//     Blocked on: a Drift `workflow_session` table + generalizing `my_visits`'
//     `ActiveWorkflow` into `core/workflow/` (Phase 3). NOTE: `workflow_state`
//     is the last live table in the plaintext `routes.db` — the T1.5 purge
//     empties every business table but cannot delete the file until this lands.
//
//   • User-workspace init/reset on user switch. Blocked on an ADR: no business
//     table carries a `userId` today, and ADR-001 mandates a single database,
//     so per-user isolation is an open architectural decision.
//
// See `docs/MIGRATION_PLAN.md` for sequencing. Do not stub these in with
// no-op implementations — an empty hook reads as "done" to the next engineer.
// ─────────────────────────────────────────────────────────────────────────────
