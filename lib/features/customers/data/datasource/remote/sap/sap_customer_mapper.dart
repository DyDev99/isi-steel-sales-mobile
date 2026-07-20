import 'package:isi_steel_sales_mobile/features/customers/data/datasource/remote/sap/dto/sap_business_partner.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_model.dart';

/// Maps a SAP business partner onto the app's [CustomerModel].
///
/// ## What SAP does and does not provide
///
/// The customer master answers with customer number, names, sales area,
/// address, phone, payment terms, credit limit and sales employee
/// (`SapAPI_Technical_Document_v1_BP.docx` §5.2). It carries **no**:
///
/// * geolocation — there is no latitude/longitude anywhere in the BP payload;
/// * CRM status — nothing maps onto `active` / `dormant` / `creditHold`;
/// * territory in this app's sense — `salesOrg`/`division` are SAP sales-area
///   codes, not the rep-facing territory names the UI groups and filters by.
///
/// Those four are therefore left **null**, which is exactly what schema v9 made
/// possible. Inventing values would be worse than admitting the gap: sentinel
/// `0,0` coordinates place every customer off the coast of Africa, and
/// defaulting `status` to `active` would present a customer on credit hold as
/// safe to sell to.
///
/// ## Identity
///
/// [CustomerModel.id] is set to the SAP customer number rather than a fresh
/// UUID. The number is already SAP's stable primary key, and generating a UUID
/// would make every sync insert duplicates instead of updating in place — the
/// upsert is keyed on `id`.
extension SapBusinessPartnerMapper on SapBusinessPartner {
  CustomerModel toCustomerModel({DateTime? syncedAt}) {
    final number = customerNumber;
    return CustomerModel(
      id: number,
      sapCustomerId: number,
      customerCode: number,

      // `name1` is the SAP legal name and the only mandatory field on create
      // (§5.4); `nameEn` is preferred for display where present.
      shopName: displayName ?? number,

      // SAP models a business partner, not a proprietor: there is no separate
      // owner/contact name on the BP record itself. Contacts arrive through a
      // different object, so this is left blank rather than duplicating the
      // company name into a field the UI labels "Owner".
      ownerName: '',

      phone: mobilePhone ?? telephone ?? '',
      email: email,
      address: formattedAddress,

      // SAP's address is street/city/country; there is no province/district
      // split. `city` is the closest analogue to province; district has no
      // source at all.
      province: city ?? '',
      district: district ?? '',

      creditLimit: creditLimit ?? 0,

      // Not supplied by SAP — see the class doc.
      territory: null,
      latitude: null,
      longitude: null,
      status: null,

      // §5.2 lists a sales employee on detail rows. It identifies the SAP sales
      // rep, which is the nearest thing to an assigned rep, so it is carried
      // through when present.
      assignedRepId: salesEmployee,
      assignedRepName: salesEmployeeName ?? salesEmployee,

      // SAP exposes no per-record "last changed" timestamp through these
      // endpoints, so the sync time is recorded instead. This is why local
      // `updatedAt` cannot be used to drive a delta pull — see
      // `CustomerSyncRepositoryImpl`.
      updatedAt: syncedAt ?? DateTime.now().toUtc(),
    );
  }
}

/// Maps a page of SAP rows, discarding any row with no customer number.
///
/// A row without a key cannot be upserted or later matched, so importing it
/// would create an unreachable orphan that every subsequent sync duplicates.
extension SapCustomerPageMapper on SapCustomerPage {
  List<CustomerModel> toCustomerModels({DateTime? syncedAt}) => rows
      .where((r) => r.customerNumber.isNotEmpty)
      .map((r) => r.toCustomerModel(syncedAt: syncedAt))
      .toList(growable: false);
}
