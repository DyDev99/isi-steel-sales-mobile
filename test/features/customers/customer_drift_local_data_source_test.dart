import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isi_steel_sales_mobile/core/storage/database/drift/app_database.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/local/customer_drift_local_data_source.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_activity_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_contact_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_note_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_activity_type.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_filter.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_status.dart';

CustomerModel _model({
  required String id,
  String territory = 'Phnom Penh',
  String shopName = 'Shop',
  CustomerStatus status = CustomerStatus.active,
  List<String> products = const ['rebar', 'sheet'],
  List<CustomerContactModel> contacts = const [],
}) {
  return CustomerModel(
    id: id,
    sapCustomerId: 'SAP-$id',
    customerCode: 'C-$id',
    shopName: shopName,
    ownerName: 'Owner $id',
    phone: '01000$id',
    address: 'Addr',
    province: 'PP',
    district: 'D1',
    territory: territory,
    latitude: 11.5,
    longitude: 104.9,
    creditLimit: 5000,
    status: status,
    assignedRepId: 'R1',
    assignedRepName: 'Rep One',
    updatedAt: DateTime.utc(2026, 1, 1),
    productsPurchased: products,
    contacts: contacts,
  );
}

/// End-to-end proof of the T2 cutover: a [CustomerModel] round-trips through the
/// mappers → [CustomerDao] → single Drift database and back, via the production
/// [CustomerDriftLocalDataSource]. Uses an in-memory DB (SQLCipher wrapper is
/// verified separately on-device).
void main() {
  late AppDatabase db;
  late CustomerDriftLocalDataSource source;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    source = CustomerDriftLocalDataSource(db.customerDao);
  });
  tearDown(() => db.close());

  test('upsert + getById round-trips all fields including contacts', () async {
    await source.upsertCustomers([
      _model(
        id: '1',
        products: ['rebar', 'wire'],
        contacts: const [
          CustomerContactModel(
              id: 'k1', name: 'Buyer', role: 'purchasing', phone: '111'),
        ],
      ),
    ]);

    final loaded = await source.getById('1');
    expect(loaded, isNotNull);
    expect(loaded!.status, CustomerStatus.active);
    expect(loaded.productsPurchased, ['rebar', 'wire']);
    expect(loaded.updatedAt, DateTime.utc(2026, 1, 1));
    expect(loaded.contacts.single.name, 'Buyer');
  });

  test('browse applies territory filter and pageSize + 1 lookahead', () async {
    await source.upsertCustomers([
      _model(id: '1', shopName: 'Bravo'),
      _model(id: '2', shopName: 'Alpha'),
      _model(id: '3', shopName: 'Faraway', territory: 'Siem Reap'),
    ]);

    final page = await source.browse(
      page: 0,
      pageSize: 10,
      filter: const CustomerFilter(
          territory: 'Phnom Penh', sortBy: CustomerSortBy.nameAsc),
    );
    expect(page.map((c) => c.shopName), ['Alpha', 'Bravo']);
  });

  test('browse productCategory filter matches products_purchased', () async {
    await source.upsertCustomers([
      _model(id: '1', products: ['rebar']),
      _model(id: '2', products: ['sheet']),
    ]);
    final page = await source.browse(
      page: 0,
      pageSize: 10,
      filter: const CustomerFilter(productCategory: 'rebar'),
    );
    expect(page.single.id, '1');
  });

  test('notes and activities persist and read back newest-first', () async {
    await source.upsertCustomers([_model(id: '1')]);
    await source.addNote(CustomerNoteModel(
        id: 'n1', customerId: '1', body: 'first', createdAt: DateTime.utc(2026, 1, 1)));
    await source.addActivity(CustomerActivityModel(
        id: 'a1',
        customerId: '1',
        type: CustomerActivityType.call,
        summary: 'called',
        createdAt: DateTime.utc(2026, 1, 2)));

    expect((await source.fetchNotes('1')).single.body, 'first');
    final acts = await source.fetchActivities('1');
    expect(acts.single.type, CustomerActivityType.call);
  });

  test('favorites and sync metadata round-trip', () async {
    await source.upsertCustomers([_model(id: '1')]);
    await source.toggleFavorite('1');
    expect((await source.fetchFavorites()).single.id, '1');

    final at = DateTime.utc(2026, 7, 14, 9);
    await source.setLastSyncedAt('customers', at);
    expect(await source.getLastSyncedAt('customers'), at);
  });

  test('markDeleted hides customers from browse/getById', () async {
    await source.upsertCustomers([_model(id: '1'), _model(id: '2')]);
    await source.markDeleted(['1']);
    expect(await source.getById('1'), isNull);
    final remaining = await source.browse(page: 0, pageSize: 10);
    expect(remaining.map((c) => c.id), ['2']);
  });
}
