import 'package:drift/drift.dart' show Value;
import 'package:isi_steel_sales_mobile/core/storage/database/drift/app_database.dart' as db;
import 'package:isi_steel_sales_mobile/core/storage/database/drift/daos/customer_dao.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_activity_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_contact_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_note_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_activity_type.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_filter.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_status.dart';

/// Bidirectional mapping between the encrypted Drift rows/companions and the
/// customer feature's models. Isolated here so the data source stays thin and
/// the `productsPurchased` list⇄`'|'`-joined-text convention lives in one place.
///
/// The Drift generated types are prefixed `db.` to avoid colliding with the
/// domain entities the models extend.

const _kProductsSeparator = '|';

extension CustomerRowMapper on db.Customer {
  CustomerModel toModel({List<CustomerContactModel> contacts = const []}) {
    return CustomerModel(
      id: id,
      sapCustomerId: sapCustomerId,
      customerCode: customerCode,
      shopName: shopName,
      ownerName: ownerName,
      phone: phone,
      email: email,
      whatsapp: whatsapp,
      address: address,
      province: province,
      district: district,
      territory: territory,
      latitude: latitude,
      longitude: longitude,
      creditLimit: creditLimit,
      status: CustomerStatus.values.byName(status),
      assignedRepId: assignedRepId,
      assignedRepName: assignedRepName,
      updatedAt: updatedAt,
      originLeadId: originLeadId,
      productsPurchased: productsPurchased
          .split(_kProductsSeparator)
          .where((e) => e.isNotEmpty)
          .toList(),
      contacts: contacts,
      lastOrderDate: lastOrderDate,
      lastVisitDate: lastVisitDate,
      lifetimeValue: lifetimeValue,
      openOpportunityCount: openOpportunityCount,
      deleted: deleted,
    );
  }
}

extension CustomerModelMapper on CustomerModel {
  db.CustomersCompanion toCompanion() {
    return db.CustomersCompanion.insert(
      id: id,
      sapCustomerId: sapCustomerId,
      customerCode: customerCode,
      shopName: shopName,
      ownerName: ownerName,
      phone: phone,
      email: Value(email),
      whatsapp: Value(whatsapp),
      address: address,
      province: province,
      district: district,
      territory: territory,
      latitude: latitude,
      longitude: longitude,
      creditLimit: creditLimit,
      status: status.name,
      assignedRepId: assignedRepId,
      assignedRepName: assignedRepName,
      updatedAt: updatedAt,
      originLeadId: Value(originLeadId),
      productsPurchased: Value(productsPurchased.join(_kProductsSeparator)),
      lastOrderDate: Value(lastOrderDate),
      lastVisitDate: Value(lastVisitDate),
      lifetimeValue: Value(lifetimeValue),
      openOpportunityCount: Value(openOpportunityCount),
      deleted: Value(deleted),
    );
  }

  CustomerWithContacts toRecord() {
    final contactCompanions = contacts
        .map((c) => db.CustomerContactsCompanion.insert(
              id: c.id,
              customerId: id,
              name: c.name,
              role: c.role,
              phone: c.phone,
              email: Value(c.email),
            ))
        .toList();
    return CustomerWithContacts(toCompanion(), contactCompanions);
  }
}

extension CustomerContactRowMapper on db.CustomerContact {
  CustomerContactModel toModel() => CustomerContactModel(
        id: id,
        name: name,
        role: role,
        phone: phone,
        email: email,
      );
}

extension CustomerNoteRowMapper on db.CustomerNote {
  CustomerNoteModel toModel() => CustomerNoteModel(
        id: id,
        customerId: customerId,
        body: body,
        createdAt: createdAt,
        synced: synced,
      );
}

extension CustomerNoteModelMapper on CustomerNoteModel {
  db.CustomerNotesCompanion toCompanion() => db.CustomerNotesCompanion.insert(
        id: id,
        customerId: customerId,
        body: body,
        createdAt: createdAt,
        synced: Value(synced),
      );
}

extension CustomerActivityRowMapper on db.CustomerActivity {
  CustomerActivityModel toModel() => CustomerActivityModel(
        id: id,
        customerId: customerId,
        type: CustomerActivityType.fromValue(type),
        summary: summary,
        createdAt: createdAt,
        synced: synced,
      );
}

extension CustomerActivityModelMapper on CustomerActivityModel {
  db.CustomerActivitiesCompanion toCompanion() =>
      db.CustomerActivitiesCompanion.insert(
        id: id,
        customerId: customerId,
        type: type.value,
        summary: summary,
        createdAt: createdAt,
        synced: Value(synced),
      );
}

/// Maps the feature's sort enum onto the DAO's decoupled equivalent.
extension CustomerSortMapper on CustomerSortBy {
  CustomerBrowseSort toBrowseSort() => switch (this) {
        CustomerSortBy.recentOrder => CustomerBrowseSort.recentOrder,
        CustomerSortBy.nameAsc => CustomerBrowseSort.nameAsc,
        CustomerSortBy.nearest => CustomerBrowseSort.nearest,
        CustomerSortBy.valueDesc => CustomerBrowseSort.valueDesc,
      };
}
