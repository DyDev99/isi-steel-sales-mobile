import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_text.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_contact.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_status.dart';

/// An approved business customer that already exists in SAP.
///
/// This is deliberately **not** a superset of `Lead` — it only ever comes
/// into being via sync from the SAP customer master
/// ([CustomerRemoteDataSource]/`upsertFromSapPayload`). There is no local
/// constructor path for a rep to hand-create one; that would violate the
/// Won -> Submitted -> HQ Approved -> SAP-created entry rule.
/// [sapCustomerId] is **nullable**: a customer registered in the field has no
/// SAP identity until it is approved and pushed to the ERP. It was non-null
/// while customers could only arrive by sync from SAP; now that a rep can
/// create one, `Draft` and `PendingApproval` records legitimately have none.
class Customer extends Equatable {
  const Customer({
    required this.id,
    this.sapCustomerId,
    required this.customerCode,
    required this.shopName,
    required this.ownerName,
    required this.phone,
    required this.address,
    required this.province,
    required this.district,
    required this.territory,
    required this.latitude,
    required this.longitude,
    required this.creditLimit,
    required this.status,
    required this.assignedRepId,
    required this.assignedRepName,
    required this.updatedAt,
    this.email,
    this.whatsapp,
    this.originLeadId,
    this.productsPurchased = const [],
    this.contacts = const [],
    this.lastOrderDate,
    this.lastVisitDate,
    this.lifetimeValue = 0,
    this.openOpportunityCount = 0,
    this.salesOrg,
    this.division,
    this.distributionChannel,
    this.customerGroup,
    this.priceGroup,
    this.enName,
    this.khName,
    this.taxNumber,
    this.creditBalance = 0,
    this.currency = 'USD',
    this.totalOrders = 0,
    this.createdAt,
  });

  final String id;

  /// The ERP's identifier, once it has one. Null until SAP creates the record.
  final String? sapCustomerId;
  final String customerCode;
  final String shopName;
  final String ownerName;
  final String phone;
  final String? email;
  final String? whatsapp;
  final String address;
  final String province;
  final String district;
  final String territory;
  final double latitude;
  final double longitude;

  /// SAP/HQ-controlled financials — read-only on the mobile app.
  final double creditLimit;
  final CustomerStatus status;

  final String assignedRepId;
  final String assignedRepName;
  final DateTime updatedAt;

  /// The Lead this customer originated from, kept for traceability only —
  /// there is no foreign key back to `leads` and nothing here ever writes
  /// to that Lead again.
  final String? originLeadId;

  final List<String> productsPurchased;
  final List<CustomerContact> contacts;
  final DateTime? lastOrderDate;
  final DateTime? lastVisitDate;
  final double lifetimeValue;
  final int openOpportunityCount;

  // ── SAP sales area (schema v9) ──────────────────────────────────────
  // Nullable because SAP leaves the sales area blank until a customer is
  // assigned one, and because rows written before v9 have no value. A filter
  // must treat null as "unassigned", never as a match.
  final String? salesOrg;
  final String? division;
  final String? distributionChannel;

  /// SAP commercial classification.
  final String? customerGroup;
  final String? priceGroup;

  /// SAP `name1` / `name3`. [shopName] remains the display name; these are the
  /// legal names used for search and printed documents.
  final String? enName;
  final String? khName;

  /// VAT / tax identification number.
  final String? taxNumber;

  /// Consumed portion of [creditLimit]; [availableCredit] is the useful figure.
  final double creditBalance;
  final String currency;

  /// Lifetime order count — the countable twin of [lifetimeValue].
  final int totalOrders;

  /// When SAP created the record ([updatedAt] covers modification).
  final DateTime? createdAt;

  /// Whether this customer has a usable position.
  ///
  /// `(0, 0)` encodes "no GPS fix was ever captured". It is a real point in the
  /// Gulf of Guinea, which is precisely why the API rejects it on write and
  /// sends null instead — but the local schema declares both columns non-null,
  /// so that pair is what a coordinate-less customer stores.
  ///
  /// **Every geographic consumer must check this first.** A distance sorter or
  /// geofence that skips the check will happily measure the 10 000 km to the
  /// Atlantic and rank an unlocated shop as impossibly far, or fail a check-in
  /// the rep is standing inside.
  bool get hasCoordinates => latitude != 0 || longitude != 0;

  /// The customer's name in both languages, for rendering.
  ///
  /// English resolves to [shopName] rather than [enName] deliberately:
  /// [shopName] is non-nullable and populated for every row, while SAP leaves
  /// `name1` blank on plenty of accounts. Falling back the other way would
  /// blank out the directory for exactly the customers with the least master
  /// data — the ones a rep most needs to find.
  ///
  /// Khmer resolves to [khName] (SAP `name3`). Where SAP carries no Khmer name,
  /// [LocalizedText.resolve] falls back to English, so a Khmer session shows a
  /// Latin shop name instead of an empty row.
  ///
  /// Widgets render `context.localized(customer.displayName)`. Nothing is
  /// re-fetched on a language switch because both languages are already here —
  /// the same design as [Product.displayName] and [Category.name].
  LocalizedText get displayName =>
      LocalizedText(en: shopName, km: khName ?? '');

  /// Everything the directory search should match, in every language at once.
  ///
  /// Spans both languages regardless of the active locale on purpose: a rep who
  /// knows a shop by its Khmer name types that whether or not the UI is in
  /// Khmer, and returning nothing would be a defect. The DAO applies the same
  /// rule in SQL (`CustomerDao.browse`); this is the in-memory twin, used where
  /// a list is already loaded and re-querying would be wasteful.
  Iterable<String> get searchableValues sync* {
    yield* displayName.allValues;
    if ((enName?.trim().isNotEmpty ?? false) && enName != shopName) {
      yield enName!;
    }
    yield customerCode;
    // Searchable only once it exists — an unsynced customer has no SAP number
    // to match against, and yielding null would poison the token set.
    if (sapCustomerId case final sapId?) yield sapId;
    yield ownerName;
    yield phone;
  }

  /// Headroom left against the credit limit. Clamped at zero so an
  /// over-limit account reads as "no credit available" rather than negative.
  double get availableCredit {
    final remaining = creditLimit - creditBalance;
    return remaining < 0 ? 0 : remaining;
  }

  /// True once SAP has assigned a full sales area. Screens that act on sales
  /// area should check this rather than null-testing three fields.
  bool get hasSalesArea =>
      (salesOrg?.isNotEmpty ?? false) && (division?.isNotEmpty ?? false);

  @override
  List<Object?> get props => [
        id,
        sapCustomerId,
        customerCode,
        shopName,
        ownerName,
        phone,
        email,
        whatsapp,
        address,
        province,
        district,
        territory,
        latitude,
        longitude,
        creditLimit,
        status,
        assignedRepId,
        assignedRepName,
        updatedAt,
        originLeadId,
        productsPurchased,
        contacts,
        lastOrderDate,
        lastVisitDate,
        lifetimeValue,
        openOpportunityCount,
        salesOrg,
        division,
        distributionChannel,
        customerGroup,
        priceGroup,
        enName,
        khName,
        taxNumber,
        creditBalance,
        currency,
        totalOrders,
        createdAt,
      ];
}
