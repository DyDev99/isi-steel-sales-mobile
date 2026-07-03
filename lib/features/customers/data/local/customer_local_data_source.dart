import 'package:isi_steel_sales_mobile/core/error/exceptions.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/local/customers_database.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_activity_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_contact_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_note_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_filter.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class CustomerLocalDataSource {
  /// Returns up to `pageSize + 1` rows so the caller can detect "has more"
  /// without a separate COUNT query.
  Future<List<CustomerModel>> browse({
    required int page,
    required int pageSize,
    String query = '',
    CustomerFilter filter = const CustomerFilter(),
  });

  Future<CustomerModel?> getById(String id);

  Future<void> toggleFavorite(String customerId);
  Future<List<CustomerModel>> fetchFavorites();
  Future<List<CustomerModel>> fetchRecent();
  Future<void> recordViewed(String customerId);

  Future<List<CustomerNoteModel>> fetchNotes(String customerId);
  Future<void> addNote(CustomerNoteModel note);

  Future<List<CustomerActivityModel>> fetchActivities(String customerId);
  Future<void> addActivity(CustomerActivityModel activity);

  /// Batched, transactional upsert into `customers`/`customer_contacts`/
  /// `customers_fts`. The only write path that may populate `customers` —
  /// called exclusively by the sync repository.
  Future<void> upsertCustomers(List<CustomerModel> customers);
  Future<void> markDeleted(List<String> ids);

  Future<DateTime?> getLastSyncedAt(String entity);
  Future<void> setLastSyncedAt(String entity, DateTime at);
}

class CustomerLocalDataSourceImpl implements CustomerLocalDataSource {
  const CustomerLocalDataSourceImpl(this._customersDb);
  final CustomersDatabase _customersDb;
  Database get _db => _customersDb.db;

  @override
  Future<List<CustomerModel>> browse({
    required int page,
    required int pageSize,
    String query = '',
    CustomerFilter filter = const CustomerFilter(),
  }) async {
    try {
      final offset = page * pageSize;
      final limit = pageSize + 1;
      final where = <String>['c.deleted = 0'];
      final args = <Object?>[];

      if (filter.territory != null) {
        where.add('c.territory = ?');
        args.add(filter.territory);
      }
      if (filter.status != null) {
        where.add('c.status = ?');
        args.add(filter.status!.name);
      }
      if (filter.productCategory != null) {
        where.add("c.products_purchased LIKE ?");
        args.add('%${filter.productCategory}%');
      }

      final orderBy = switch (filter.sortBy) {
        CustomerSortBy.recentOrder => 'c.last_order_date DESC',
        CustomerSortBy.nameAsc => 'c.shop_name ASC',
        CustomerSortBy.nearest => 'c.updated_at DESC', // distance is computed client-side from GPS
        CustomerSortBy.valueDesc => 'c.lifetime_value DESC',
      };

      final sanitized = query.replaceAll(RegExp(r'[^\w\s.]'), ' ').trim();
      late final String sql;
      late final List<Object?> allArgs;

      if (sanitized.isEmpty) {
        sql = '''
          SELECT c.* FROM customers c
          WHERE ${where.join(' AND ')}
          ORDER BY $orderBy
          LIMIT ? OFFSET ?
        ''';
        allArgs = [...args, limit, offset];
      } else {
        final words = sanitized.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
        final match = words
            .map((w) => '(shop_name:$w* OR customer_code:$w* OR owner_name:$w* OR phone:$w*)')
            .join(' AND ');
        sql = '''
          SELECT c.* FROM customers_fts f
          JOIN customers c ON c.id = f.customer_id
          WHERE customers_fts MATCH ? AND ${where.join(' AND ')}
          ORDER BY $orderBy
          LIMIT ? OFFSET ?
        ''';
        allArgs = [match, ...args, limit, offset];
      }

      final rows = await _db.rawQuery(sql, allArgs);
      return rows.map(CustomerModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to browse customers: $e');
    }
  }

  @override
  Future<CustomerModel?> getById(String id) async {
    try {
      final rows = await _db.query('customers', where: 'id = ? AND deleted = 0', whereArgs: [id]);
      if (rows.isEmpty) return null;
      final contactRows = await _db.query('customer_contacts', where: 'customer_id = ?', whereArgs: [id]);
      final contacts = contactRows.map(CustomerContactModel.fromRow).toList();
      return CustomerModel.fromRow(rows.first, contacts: contacts);
    } catch (e) {
      throw CacheException(message: 'Failed to load customer $id: $e');
    }
  }

  @override
  Future<void> toggleFavorite(String customerId) async {
    try {
      final existing = await _db.query('customer_favorites', where: 'customer_id = ?', whereArgs: [customerId]);
      if (existing.isNotEmpty) {
        await _db.delete('customer_favorites', where: 'customer_id = ?', whereArgs: [customerId]);
      } else {
        await _db.insert('customer_favorites', {
          'customer_id': customerId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw CacheException(message: 'Failed to toggle favorite: $e');
    }
  }

  @override
  Future<List<CustomerModel>> fetchFavorites() async {
    try {
      final rows = await _db.rawQuery('''
        SELECT c.* FROM customer_favorites fav
        JOIN customers c ON c.id = fav.customer_id
        WHERE c.deleted = 0
        ORDER BY fav.created_at DESC
      ''');
      return rows.map(CustomerModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load favorite customers: $e');
    }
  }

  @override
  Future<List<CustomerModel>> fetchRecent() async {
    try {
      final rows = await _db.rawQuery('''
        SELECT c.* FROM customer_recent r
        JOIN customers c ON c.id = r.customer_id
        WHERE c.deleted = 0
        ORDER BY r.viewed_at DESC
        LIMIT 20
      ''');
      return rows.map(CustomerModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load recent customers: $e');
    }
  }

  @override
  Future<void> recordViewed(String customerId) async {
    try {
      await _db.insert(
        'customer_recent',
        {'customer_id': customerId, 'viewed_at': DateTime.now().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException(message: 'Failed to record viewed customer: $e');
    }
  }

  @override
  Future<List<CustomerNoteModel>> fetchNotes(String customerId) async {
    try {
      final rows = await _db.query(
        'customer_notes',
        where: 'customer_id = ?',
        whereArgs: [customerId],
        orderBy: 'created_at DESC',
      );
      return rows.map(CustomerNoteModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load notes: $e');
    }
  }

  @override
  Future<void> addNote(CustomerNoteModel note) async {
    try {
      await _db.insert('customer_notes', note.toRow());
    } catch (e) {
      throw CacheException(message: 'Failed to save note: $e');
    }
  }

  @override
  Future<List<CustomerActivityModel>> fetchActivities(String customerId) async {
    try {
      final rows = await _db.query(
        'customer_activities',
        where: 'customer_id = ?',
        whereArgs: [customerId],
        orderBy: 'created_at DESC',
      );
      return rows.map(CustomerActivityModel.fromRow).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to load activities: $e');
    }
  }

  @override
  Future<void> addActivity(CustomerActivityModel activity) async {
    try {
      await _db.insert('customer_activities', activity.toRow());
    } catch (e) {
      throw CacheException(message: 'Failed to save activity: $e');
    }
  }

  @override
  Future<void> upsertCustomers(List<CustomerModel> customers) async {
    try {
      await _db.transaction((txn) async {
        final batch = txn.batch();
        for (final customer in customers) {
          batch.insert('customers', customer.toRow(), conflictAlgorithm: ConflictAlgorithm.replace);
          batch.delete('customers_fts', where: 'customer_id = ?', whereArgs: [customer.id]);
          batch.insert('customers_fts', customer.toFtsRow());
          batch.delete('customer_contacts', where: 'customer_id = ?', whereArgs: [customer.id]);
          for (final contact in customer.contacts) {
            batch.insert('customer_contacts', (contact as CustomerContactModel).toRow(customer.id));
          }
        }
        await batch.commit(noResult: true);
      });
    } catch (e) {
      throw CacheException(message: 'Failed to save synced customers: $e');
    }
  }

  @override
  Future<void> markDeleted(List<String> ids) async {
    if (ids.isEmpty) return;
    try {
      await _db.transaction((txn) async {
        final placeholders = List.filled(ids.length, '?').join(',');
        await txn.rawUpdate('UPDATE customers SET deleted = 1 WHERE id IN ($placeholders)', ids);
        final batch = txn.batch();
        for (final id in ids) {
          batch.delete('customers_fts', where: 'customer_id = ?', whereArgs: [id]);
        }
        await batch.commit(noResult: true);
      });
    } catch (e) {
      throw CacheException(message: 'Failed to apply deletions: $e');
    }
  }

  @override
  Future<DateTime?> getLastSyncedAt(String entity) async {
    try {
      final rows = await _db.query('customer_sync_meta', where: 'entity = ?', whereArgs: [entity]);
      if (rows.isEmpty) return null;
      final raw = rows.first['last_synced_at'] as String?;
      return raw == null ? null : DateTime.parse(raw);
    } catch (e) {
      throw CacheException(message: 'Failed to read sync metadata: $e');
    }
  }

  @override
  Future<void> setLastSyncedAt(String entity, DateTime at) async {
    try {
      await _db.insert(
        'customer_sync_meta',
        {'entity': entity, 'last_synced_at': at.toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException(message: 'Failed to write sync metadata: $e');
    }
  }
}
