import 'package:isi_steel_sales_mobile/features/customers/data/datasource/remote/sap/dto/sap_business_partner.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_model.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_status.dart';

/// Maps a SAP business partner onto the app's [CustomerModel].
///
/// Grounded in the captured live `GetPaging` response (2026-07-22), which
/// corrected two earlier assumptions:
///
/// * **Coordinates are real.** `Latitude`/`Longitude` exist on the wire
///   (string-encoded, blank for most walk-in accounts). Where present they flow
///   through to the map and geofencing; where blank they stay null.
/// * **Status is real.** SAP expresses block state through `OrderBlock`,
///   `SALESBLOCK` and `BLOCKFLAG`. A blocked partner maps to
///   [CustomerStatus.creditHold]; an unblocked one to [CustomerStatus.active].
///   This is *not* the "never default status" rule being broken — that rule
///   forbade inventing a value SAP had not stated, and the absence of every
///   block flag is now an explicit statement.
///
/// Display-name preference: SAP ships every classification as a code+name pair
/// (`T015` / `15 days due net`). The app stores the **name** for
/// `paymentTerms`/`customerGroup`/`priceGroup` (that is what a rep can read)
/// and the **codes** for the sales-area triple (they key filters and indexes);
/// `territory` carries `SalesOrgName`, which is exactly this app's territory
/// concept ("Phnom Penh (ISI)", "Battambang") and lights up the territory
/// picker with real data.
///
/// ## Identity and duplicates
///
/// [CustomerModel.id] is the SAP customer number. The live feed emits **one row
/// per sales area**, so a page usually contains fewer distinct customers than
/// rows; the keyed upsert makes the last sales-area row win. Acceptable for the
/// directory today, and flagged in `docs/customers.md` §4 as debt — a proper
/// customer×sales-area child table is the eventual fix.
extension SapBusinessPartnerMapper on SapBusinessPartner {
  CustomerModel toCustomerModel({DateTime? syncedAt}) {
    final number = customerNumber;
    return CustomerModel(
      id: number,
      sapCustomerId: number,

      // `SearchTerm2` is the legacy human code (`IC00000001`) staff actually
      // recognise; the bare BP number is the fallback.
      customerCode: searchTerm2 ?? number,

      shopName: displayName ?? number,

      // Still no proprietor in the payload. `CoName` is a channel tag
      // ("ISI KEY DEPOT"), not a person — presenting it as the owner would be
      // wrong in a different way than blank.
      ownerName: '',

      phone: mobilePhone ?? telephone ?? '',
      email: null,
      address: formattedAddress,

      // `City` when SAP filled it; else `SearchTerm1`, the uppercase
      // province/branch tag every live row carries.
      province: city ?? searchTerm1 ?? '',
      district: '',

      territory: salesOrgName,
      latitude: latitude,
      longitude: longitude,
      status: isBlocked ? CustomerStatus.creditHold : CustomerStatus.active,

      creditLimit: creditLimit ?? 0,

      assignedRepId: salesEmployee,
      assignedRepName: salesEmployeeName ?? salesEmployee,

      // Sales-area codes (indexed, filterable); names live on territory above.
      salesOrg: salesOrg,
      division: division,
      distributionChannel: distributionChannel,

      customerGroup: customerGroupName ?? customerGroup,
      priceGroup: priceGroupName ?? priceGroup,
      paymentTerms: paymentTermsName ?? paymentTerms,

      enName: nameEn,
      khName: nameKh,
      createdAt: creationDate,

      // The live payload has no currency field; this ledger operates in USD.
      currency: 'USD',

      // No per-record modification timestamp on the wire, so the sync time is
      // recorded — which is also why delta pulls cannot be server-side.
      updatedAt: syncedAt ?? DateTime.now().toUtc(),
    );
  }
}

/// Maps a page of SAP rows, discarding any row with no customer number.
///
/// A keyless row cannot be upserted or later matched — importing it would
/// create an orphan that every subsequent sync duplicates.
extension SapCustomerPageMapper on SapCustomerPage {
  List<CustomerModel> toCustomerModels({DateTime? syncedAt}) => rows
      .where((r) => r.customerNumber.isNotEmpty)
      .map((r) => r.toCustomerModel(syncedAt: syncedAt))
      .toList(growable: false);
}
