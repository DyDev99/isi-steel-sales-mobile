import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_contact.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_status.dart';

/// An approved business customer that already exists in SAP.
///
/// This is deliberately **not** a superset of `Lead` — it only ever comes
/// into being via sync from the SAP customer master
/// ([CustomerRemoteDataSource]/`upsertFromSapPayload`). There is no local
/// constructor path for a rep to hand-create one; that would violate the
/// Won -> Submitted -> HQ Approved -> SAP-created entry rule.
/// [sapCustomerId] is non-nullable by design: a record cannot exist here
/// without a SAP identity.
class Customer extends Equatable {
  const Customer({
    required this.id,
    required this.sapCustomerId,
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
  final String sapCustomerId;
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
