import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_activity_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_note_model.dart';

/// Customer-adjacent data owned by the **ISI Steel Sales backend**, not SAP.
///
/// The split is by system of record, not by screen:
///
/// | Data | Owner | Datasource |
/// |---|---|---|
/// | Business partner, names, address, credit limit, sales area | SAP | `CustomerSapRemoteDataSource` |
/// | Notes a rep types, activity timeline, favourites | ISI | this interface |
///
/// Notes and activities are app-native: SAP has no notion of them, and pushing
/// them there would be inventing a business object the ERP does not own. They
/// are held locally today (`customer_notes` / `customer_activities`, with a
/// `synced` flag already on both tables) and this interface is where their
/// eventual push lands.
///
/// **Not implemented yet, deliberately.** Two things block it:
///
/// 1. No ISI endpoint specification exists — the only technical document
///    supplied covers SAP. Inventing URLs now would bake in guesses.
/// 2. Pushing local mutations requires the sync queue, and
///    `core/sync/{sync_engine,sync_queue_service,conflict_manager}.dart` are
///    0-byte stubs scheduled for Phase 4 (`docs/MIGRATION_PLAN.md` §1). A push
///    path built before them could not satisfy ADR-006's rule that a mutation
///    and its queue row commit in one transaction.
///
/// The interface is declared now so the SAP/ISI boundary is explicit in the
/// folder structure rather than implied.
abstract interface class CustomerRemoteDataSource {
  /// Pushes locally-authored notes that have not yet reached the server.
  Future<void> pushNotes(List<CustomerNoteModel> notes);

  /// Pushes locally-recorded activity entries.
  Future<void> pushActivities(List<CustomerActivityModel> activities);

  /// Pulls notes authored on other devices by the same rep.
  Future<List<CustomerNoteModel>> fetchNotes(String customerId);
}
