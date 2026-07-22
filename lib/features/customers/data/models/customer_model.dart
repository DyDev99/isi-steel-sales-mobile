import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_contact_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_status.dart';

/// Hand-written mapping (mirrors `order`'s `ProductModel`) — the remote SAP
/// payload shape and the flat sqlite row shape differ enough that
/// generated code wouldn't buy much here.
class CustomerModel extends Customer {
  const CustomerModel({
    required super.id,
    required super.sapCustomerId,
    required super.customerCode,
    required super.shopName,
    required super.ownerName,
    required super.phone,
    required super.address,
    required super.province,
    required super.district,
    required super.creditLimit,
    required super.updatedAt,
    super.territory,
    super.latitude,
    super.longitude,
    super.status,
    super.assignedRepId,
    super.assignedRepName,
    super.email,
    super.whatsapp,
    super.originLeadId,
    super.productsPurchased,
    super.contacts,
    super.lastOrderDate,
    super.lastVisitDate,
    super.lifetimeValue,
    super.openOpportunityCount,
    super.salesOrg,
    super.division,
    super.distributionChannel,
    super.customerGroup,
    super.priceGroup,
    super.paymentTerms,
    super.enName,
    super.khName,
    super.taxNumber,
    super.creditBalance,
    super.currency,
    super.totalOrders,
    super.createdAt,
    this.deleted = false,
  });

  final bool deleted;

  /// Parses a persisted/remote status name, tolerating both absence and an
  /// unrecognised value.
  ///
  /// `CustomerStatus.values.byName` throws on an unknown name, which would turn
  /// one unexpected string from SAP into a crash that takes out the whole sync
  /// page. Returning null degrades to "status unknown" for that record instead
  /// — the same state a record with no status at all is already in.
  static CustomerStatus? _statusOrNull(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final status in CustomerStatus.values) {
      if (status.name == name) return status;
    }
    return null;
  }

  factory CustomerModel.fromJson(DataMap json) => CustomerModel(
        id: json['id'] as String,
        sapCustomerId: json['sapCustomerId'] as String,
        customerCode: json['customerCode'] as String,
        shopName: json['shopName'] as String,
        ownerName: json['ownerName'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String?,
        whatsapp: json['whatsapp'] as String?,
        address: json['address'] as String,
        province: json['province'] as String,
        district: json['district'] as String,
        territory: json['territory'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0,
        status: _statusOrNull(json['status'] as String?),
        assignedRepId: json['assignedRepId'] as String?,
        assignedRepName: json['assignedRepName'] as String?,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        originLeadId: json['originLeadId'] as String?,
        productsPurchased:
            (json['productsPurchased'] as List<dynamic>? ?? const [])
                .map((e) => e as String)
                .toList(),
        contacts: (json['contacts'] as List<dynamic>? ?? const [])
            .map((e) => CustomerContactModel.fromRow(e as DataMap))
            .toList(),
        lastOrderDate: json['lastOrderDate'] == null
            ? null
            : DateTime.parse(json['lastOrderDate'] as String),
        lastVisitDate: json['lastVisitDate'] == null
            ? null
            : DateTime.parse(json['lastVisitDate'] as String),
        lifetimeValue: (json['lifetimeValue'] as num?)?.toDouble() ?? 0,
        openOpportunityCount: json['openOpportunityCount'] as int? ?? 0,
        // SAP sales area / commercial block. Keys match the SAP Customer (BP)
        // API field names in `SapAPI_Technical_Document_v1_BP.docx` §5.4, so a
        // real SAP payload deserialises here unchanged (ADR-009 decision 4).
        salesOrg: json['salesOrg'] as String?,
        division: json['division'] as String?,
        distributionChannel: json['distributionChannel'] as String?,
        customerGroup: json['customerGroup'] as String?,
        priceGroup: json['priceGroup'] as String?,
        paymentTerms: json['paymentTerms'] as String?,
        enName: json['enName'] as String?,
        khName: json['khName'] as String?,
        taxNumber: json['taxNumber'] as String?,
        creditBalance: (json['creditBalance'] as num?)?.toDouble() ?? 0,
        currency: json['currency'] as String? ?? 'USD',
        totalOrders: json['totalOrders'] as int? ?? 0,
        createdAt: json['createdAt'] == null
            ? null
            : DateTime.parse(json['createdAt'] as String),
        deleted: json['deleted'] as bool? ?? false,
      );

  factory CustomerModel.fromRow(DataMap row,
          {List<CustomerContactModel> contacts = const []}) =>
      CustomerModel(
        id: row['id'] as String,
        sapCustomerId: row['sap_customer_id'] as String,
        customerCode: row['customer_code'] as String,
        shopName: row['shop_name'] as String,
        ownerName: row['owner_name'] as String,
        phone: row['phone'] as String,
        email: row['email'] as String?,
        whatsapp: row['whatsapp'] as String?,
        address: row['address'] as String,
        province: row['province'] as String,
        district: row['district'] as String,
        territory: row['territory'] as String?,
        latitude: (row['latitude'] as num?)?.toDouble(),
        longitude: (row['longitude'] as num?)?.toDouble(),
        creditLimit: (row['credit_limit'] as num?)?.toDouble() ?? 0,
        status: _statusOrNull(row['status'] as String?),
        assignedRepId: row['assigned_rep_id'] as String?,
        assignedRepName: row['assigned_rep_name'] as String?,
        updatedAt: DateTime.parse(row['updated_at'] as String),
        originLeadId: row['origin_lead_id'] as String?,
        productsPurchased: ((row['products_purchased'] as String?) ?? '')
            .split('|')
            .where((e) => e.isNotEmpty)
            .toList(),
        contacts: contacts,
        lastOrderDate: row['last_order_date'] == null
            ? null
            : DateTime.parse(row['last_order_date'] as String),
        lastVisitDate: row['last_visit_date'] == null
            ? null
            : DateTime.parse(row['last_visit_date'] as String),
        lifetimeValue: (row['lifetime_value'] as num?)?.toDouble() ?? 0,
        openOpportunityCount: row['open_opportunity_count'] as int? ?? 0,
        deleted: (row['deleted'] as int? ?? 0) == 1,
      );

  DataMap toRow() => {
        'id': id,
        'sap_customer_id': sapCustomerId,
        'customer_code': customerCode,
        'shop_name': shopName,
        'owner_name': ownerName,
        'phone': phone,
        'email': email,
        'whatsapp': whatsapp,
        'address': address,
        'province': province,
        'district': district,
        'territory': territory,
        'latitude': latitude,
        'longitude': longitude,
        'credit_limit': creditLimit,
        'status': status?.name,
        'assigned_rep_id': assignedRepId,
        'assigned_rep_name': assignedRepName,
        'updated_at': updatedAt.toIso8601String(),
        'origin_lead_id': originLeadId,
        'products_purchased': productsPurchased.join('|'),
        'last_order_date': lastOrderDate?.toIso8601String(),
        'last_visit_date': lastVisitDate?.toIso8601String(),
        'lifetime_value': lifetimeValue,
        'open_opportunity_count': openOpportunityCount,
        'deleted': deleted ? 1 : 0,
      };

  DataMap toFtsRow() => {
        'customer_id': id,
        'shop_name': shopName,
        'customer_code': customerCode,
        'owner_name': ownerName,
        'phone': phone,
      };
}
