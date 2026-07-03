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
      ];
}
