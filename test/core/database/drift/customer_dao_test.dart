import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/storage/database/drift/app_database.dart';
import 'package:isi_steel_sales_mobile/core/storage/database/drift/daos/customer_dao.dart';
import 'package:isi_steel_sales_mobile/core/storage/database/drift/migrations/schema_migrations.dart';

CustomersCompanion _customer({
  required String id,
  required String sapId,
  String territory = 'Phnom Penh',
  String shopName = 'Shop',
  String status = 'active',
  bool deleted = false,
}) {
  return CustomersCompanion.insert(
    id: id,
    sapCustomerId: sapId,
    customerCode: 'C-$id',
    shopName: shopName,
    ownerName: 'Owner',
    phone: '000',
    address: 'Addr',
    province: 'PP',
    district: 'D1',
    territory: territory,
    latitude: 11.5,
    longitude: 104.9,
    creditLimit: 1000,
    status: status,
    assignedRepId: 'R1',
    assignedRepName: 'Rep One',
    updatedAt: DateTime.utc(2026, 1, 1),
    deleted: Value(deleted),
  );
}

CustomerContactsCompanion _contact(String id, String customerId) {
  return CustomerContactsCompanion.insert(
    id: id,
    customerId: customerId,
    name: 'Contact $id',
    role: 'buyer',
    phone: '111',
  );
}

void main() {
  late AppDatabase db;
  late CustomerDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.customerDao;
  });
  tearDown(() => db.close());

  test('records the current schema version in the registry on create',
      () async {
    expect(await db.appMetadataDao.getValue('schema.version'),
        '$kCurrentSchemaVersion');
  });

  group('sync upsert + contacts', () {
    test('upsertCustomers writes customer and replaces its contacts', () async {
      await dao.upsertCustomers([
        CustomerWithContacts(
          _customer(id: '1', sapId: 'S1'),
          [_contact('c1', '1'), _contact('c2', '1')],
        ),
      ]);
      expect((await dao.getById('1'))!.shopName, 'Shop');
      expect((await dao.fetchContacts('1')).length, 2);

      // Re-upsert with a single contact → old contacts replaced.
      await dao.upsertCustomers([
        CustomerWithContacts(
          _customer(id: '1', sapId: 'S1', shopName: 'Renamed'),
          [_contact('c3', '1')],
        ),
      ]);
      expect((await dao.getById('1'))!.shopName, 'Renamed');
      final contacts = await dao.fetchContacts('1');
      expect(contacts.map((c) => c.id), ['c3']);
    });

    test('markDeleted soft-deletes many by id', () async {
      await dao.upsertCustomers([
        CustomerWithContacts(_customer(id: '1', sapId: 'S1'), const []),
        CustomerWithContacts(_customer(id: '2', sapId: 'S2'), const []),
      ]);
      await dao.markDeleted(['1', '2']);
      expect(await dao.getById('1'), isNull);
      expect(await dao.getById('2'), isNull);
    });
  });

  group('browse', () {
    setUp(() async {
      await dao.upsertCustomers([
        CustomerWithContacts(
            _customer(id: '1', sapId: 'S1', shopName: 'Bravo'), const []),
        CustomerWithContacts(
            _customer(id: '2', sapId: 'S2', shopName: 'Alpha'), const []),
        CustomerWithContacts(
            _customer(
                id: '3', sapId: 'S3', shopName: 'Other', territory: 'Siem Reap'),
            const []),
        CustomerWithContacts(
            _customer(id: '4', sapId: 'S4', shopName: 'Gone', deleted: true),
            const []),
      ]);
    });

    test('filters deleted + territory and sorts by name', () async {
      final rows = await dao.browse(
        page: 0,
        pageSize: 10,
        territory: 'Phnom Penh',
        sort: CustomerBrowseSort.nameAsc,
      );
      expect(rows.map((c) => c.shopName), ['Alpha', 'Bravo']);
    });

    test('LIKE search matches shop name', () async {
      final rows = await dao.browse(page: 0, pageSize: 10, query: 'alph');
      expect(rows.single.shopName, 'Alpha');
    });

    test('returns pageSize + 1 for has-more detection', () async {
      final rows = await dao.browse(page: 0, pageSize: 1);
      expect(rows.length, 2); // 1 requested + 1 lookahead
    });
  });

  group('notes / activities / favorites / recent', () {
    setUp(() async {
      await dao.upsertCustomers(
          [CustomerWithContacts(_customer(id: '1', sapId: 'S1'), const [])]);
    });

    test('notes are returned newest-first', () async {
      await dao.addNote(CustomerNotesCompanion.insert(
          id: 'n1', customerId: '1', body: 'old', createdAt: DateTime.utc(2026, 1, 1)));
      await dao.addNote(CustomerNotesCompanion.insert(
          id: 'n2', customerId: '1', body: 'new', createdAt: DateTime.utc(2026, 1, 2)));
      final notes = await dao.fetchNotes('1');
      expect(notes.map((n) => n.body), ['new', 'old']);
    });

    test('toggleFavorite adds then removes', () async {
      await dao.toggleFavorite('1');
      expect((await dao.fetchFavorites()).single.id, '1');
      await dao.toggleFavorite('1');
      expect(await dao.fetchFavorites(), isEmpty);
    });

    test('recordViewed is idempotent and feeds fetchRecent', () async {
      await dao.recordViewed('1');
      await dao.recordViewed('1');
      final recent = await dao.fetchRecent();
      expect(recent.single.id, '1');
    });
  });

  group('sync metadata', () {
    test('round-trips last-synced-at', () async {
      expect(await dao.getLastSyncedAt('customers'), isNull);
      final at = DateTime.utc(2026, 7, 14, 10, 30);
      await dao.setLastSyncedAt('customers', at);
      expect(await dao.getLastSyncedAt('customers'), at);
    });
  });
}
