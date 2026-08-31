// =============================================================================
// bp_customer_form_data.dart
//
// SAP BP (Customer) creation — mobile capture model.
// Pure Dart (no Flutter imports) so it can be unit-tested and reused by the
// bloc, the repository and the offline draft store.
//
// Source of truth: BP_Creation_Field_SAP.xlsx
//   Create Organization (BP) > Extend Customer > FI Customer
//
// Field ownership legend:
//   REP    = sales rep types / picks it on the phone
//   CONST  = hard-coded at frontend (never shown, never editable)
//   DERIVE = computed from GPS, session (rep's sales area) or another field
//   SAP    = comes back from SAP after creation (read-only in the app)
// =============================================================================

import 'package:isi_steel_sales_mobile/features/geo_location/domain/entities/geo_address.dart';

import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_document.dart';

/// The five capture steps of the "Add Customer" bottom sheet.
enum BpFormStep {
  identity, // 1. Who is the customer          (BP header + names)
  address, // 2. Where are they                (standard address + GPS)
  contact, // 3. How do we reach them          (phones + contact person)
  salesTerms, // 4. How do we sell to them     (sales area + billing/tax)
  documents, // 5. Proof + review              (photos, submit)
}

extension BpFormStepX on BpFormStep {
  int get number => index + 1;

  String get titleKey => switch (this) {
        BpFormStep.identity => 'add_customer.steps.identity',
        BpFormStep.address => 'add_customer.steps.address',
        BpFormStep.contact => 'add_customer.steps.contact',
        BpFormStep.salesTerms => 'add_customer.steps.sales_terms',
        BpFormStep.documents => 'add_customer.steps.documents',
      };
}

/// A SAP key/description pair as shown in a dropdown ("Z001 - Local Customer").
class SapOption {
  final String code;
  final String labelEn;
  final String? labelKh;

  const SapOption(this.code, this.labelEn, [this.labelKh]);

  String get display => '$code - $labelEn';

  @override
  String toString() => display;
}

// -----------------------------------------------------------------------------
// CONST — hard-coded at frontend. Never rendered as an input.
// -----------------------------------------------------------------------------
class SapBpConst {
  static const String partnerCategory = '2'; // Organization
  static const String bpRole = 'ZFLCU1'; // Customer
  static const String country = 'KH'; // Cambodia
  static const String departureCountry = 'KH';
  static const String region = 'R01'; // Central Area
  static const String timeZone = 'UTC+7';
  static const String salesGroup = '010'; // Channel Sales
  static const String pricingProcedure = '1'; // Standard
  static const String taxCategory = 'MWST';
  static const String partnerFunction = 'VE'; // Sales Employee
  static const String creditControlArea = 'ISI';
  static const String companyCode = 'ISI';
  static const String defaultLanguage = 'EN';

  const SapBpConst._();
}

// -----------------------------------------------------------------------------
// Master data. Replace the hard-coded lists with a cached /masterdata call once
// the backend exposes it — the shape (SapOption) stays the same.
// -----------------------------------------------------------------------------
class SapMasterData {
  static const List<SapOption> grouping = [
    SapOption('Z001', 'Local Customer', 'អតិថិជនក្នុងស្រុក'),
    SapOption('Z002', 'Export Customer', 'អតិថិជននាំចេញ'),
    SapOption('Z003', 'One-time Customer', 'អតិថិជនម្តង'),
  ];

  static const List<SapOption> title = [
    SapOption('0003', 'Company', 'ក្រុមហ៊ុន'),
    SapOption('0001', 'Ms.', 'កញ្ញា'),
    SapOption('0002', 'Mr.', 'លោក'),
  ];

  // The `city`, `districtByCity` and `postalCodeByDistrict` tables that used to
  // sit here are gone. They held five provinces, one province's districts and
  // the superseded five-digit Phnom Penh postal codes — so a rep in Kampot
  // could not enter their own district, and the postal code was keyed to a
  // district rather than to the commune that actually determines it.
  //
  // The full hierarchy (25 provinces, 203 districts, 1,646 communes, 14,372
  // villages) now lives in the shared geo_location feature, backed by the
  // bundled gazetteer. Use `GeoLocationSelector`; see
  // `docs/features/geo-location/README.md`.

  // ── Sales area ─────────────────────────────────────────────────────
  //
  // Previously not offered: `salesOrg` and `salesOffice` came from the rep's
  // session and `salesGroup` was the constant `010`, so a rep registering a
  // shop in Battambang filed it against Phnom Penh. All three are part of the
  // sales area SAP requires, and getting one wrong is not a validation error —
  // it is a customer routed to the wrong office.

  static const List<SapOption> salesOrg = [
    SapOption('0001', 'Phnom Penh (ISI)'),
    SapOption('0002', 'Building Solutions'),
    SapOption('0003', 'Battambang'),
    SapOption('0004', 'Sihanoukville'),
    SapOption('0005', 'Kampong Cham'),
    SapOption('0006', 'Kampong Thom'),
    SapOption('0007', 'Takeo'),
    SapOption('0008', 'Svay Rieng'),
    SapOption('0009', 'Siem Riep'),
    SapOption('0010', 'Kratie'),
    SapOption('0011', 'Pursat'),
    SapOption('0012', 'Banteaymeanchey'),
    SapOption('0013', 'Kampong Chhang'),
    SapOption('0014', 'Rorkar Korng'),
    SapOption('0015', 'Udong'),
    SapOption('0016', 'Svay Antor'),
    SapOption('0017', 'Kean Svay'),
    SapOption('0018', 'Tbong Khmum'),
    SapOption('0019', 'Phnom Penh (GVM)'),
    SapOption('0020', 'Export'),
    SapOption('0021', 'Export (GVM)'),
    SapOption('9999', 'Internal'),
  ];

  static const List<SapOption> salesOffice = [
    SapOption('0001', 'Phnom Penh'),
    SapOption('0002', 'Building Solutions'),
    SapOption('0003', 'Battambang'),
    SapOption('0004', 'Sihanoukville'),
    SapOption('0005', 'Kampong Cham'),
    SapOption('0006', 'Kampong Thom'),
    SapOption('0007', 'Takeo'),
    SapOption('0008', 'Svay Rieng'),
    SapOption('0009', 'Siem Riep'),
    SapOption('0010', 'Kratie'),
    SapOption('0011', 'Pursat'),
    SapOption('0012', 'Banteaymeanchey'),
    SapOption('0013', 'Kampong Chhang'),
    SapOption('0014', 'Rorkar Korng'),
    SapOption('0015', 'Udong'),
    SapOption('0016', 'Svay Antor'),
    SapOption('0017', 'Kean Svay'),
    SapOption('0018', 'Tbong Khmum'),
    SapOption('0019', 'Phnom Penh (GVM)'),
    SapOption('0020', 'Export'),
  ];

  static const List<SapOption> salesGroup = [
    SapOption('010', 'Channel Sales'),
    SapOption('020', 'Project Sales'),
    SapOption('030', 'Sales Showroom'),
    SapOption('040', 'Export Sales'),
    SapOption('050', 'Key Account Sales'),
    SapOption('060', 'Digital Sales'),
  ];

  static const List<SapOption> distributionChannel = [
    SapOption('10', 'End-User'),
    SapOption('20', 'Local Builder'),
    SapOption('30', 'Craftsman'),
    SapOption('40', 'PIPE Maker'),
    SapOption('50', 'Contractor'),
    SapOption('60', 'Developer'),
    SapOption('70', 'Distributor'),
    SapOption('80', 'Exporter'),
    SapOption('99', 'Internal'),
  ];

  static const List<SapOption> division = [
    SapOption('10', 'ISI Steel'),
    SapOption('20', 'Mekong Homes'),
    SapOption('30', 'Palm Truss'),
    SapOption('40', 'Galva Coil'),
    SapOption('99', 'Internal'),
  ];

  /// Replaces the old free-text "Shop Type" dropdown.
  static const List<SapOption> customerGroup = [
    SapOption('01', 'End-User', 'អ្នកប្រើប្រាស់ចុងក្រោយ'),
    SapOption('02', 'Local Builder'),
    SapOption('03', 'Craftsman'),
    SapOption('04', 'PIPE Maker'),
    SapOption('05', 'Contractor'),
    SapOption('06', 'Developer'),
    SapOption('07', 'Distributor', 'អ្នកចែកចាយ'),
    SapOption('08', 'Exporter'),
  ];

  /// Price group derived from customer group.
  ///
  /// **Corrected against the live catalogues.** The previous map emitted `12`,
  /// `13`, `14` and `15` — none of which exist in SAP's price groups (`11`,
  /// `21`, `31`, `41`, `51`, `52`, `53`, `61`, `71`). Every registration that
  /// derived one carried a price group the ERP would reject.
  ///
  /// The real relationship is by *name*, not by arithmetic: customer group
  /// `05 Contractor` pairs with price group `51 Contractor`. This map is the
  /// offline fallback; when the catalogues are loaded,
  /// `SapReferenceOptions.priceGroupFor` matches on the name instead, so a new
  /// pairing added in SAP works without an app release.
  ///
  /// `08 Exporter` is deliberately absent — SAP publishes no matching price
  /// group, and inventing one would be worse than leaving it unset.
  static const Map<String, String> priceGroupByCustomerGroup = {
    '01': '11', // End-User
    '02': '21', // Local Builder
    '03': '31', // Craftsman
    '04': '41', // PIPE Maker
    '05': '51', // Contractor
    '06': '61', // Developer
    '07': '71', // Distributor
  };

  static const List<SapOption> priceGroup = [
    SapOption('11', 'End-User'),
    SapOption('21', 'Local Builder'),
    SapOption('31', 'Craftsman'),
    SapOption('41', 'PIPE Maker'),
    SapOption('51', 'Contractor'),
    SapOption('52', 'Key Account'),
    SapOption('53', 'ISI Group'),
    SapOption('61', 'Developer'),
    SapOption('71', 'Distributor'),
  ];

  static const List<SapOption> deliveryPriority = [
    SapOption('01', 'High'),
    SapOption('02', 'Normal'),
    SapOption('03', 'Low'),
  ];

  static const List<SapOption> shippingCondition = [
    SapOption('01', 'ISI Services'),
    SapOption('02', 'Customer Pickup'),
  ];

  static const List<SapOption> paymentTerm = [
    // Cash and cash-equivalent — no credit exposure.
    SapOption('TCIA', 'CIA-Cash in Advance'),
    SapOption('TCOD', 'COD-Cash on Delivery'),
    // Net terms.
    SapOption('T007', '7 days due net'),
    SapOption('T014', '14 day due net'),
    SapOption('T015', '15 days due net'),
    SapOption('T030', '30 days due net'),
    SapOption('T045', '45 days due net'),
    SapOption('T060', '60 days due net'),
    SapOption('T070', '70 days due net'),
    SapOption('T075', '75 days due net'),
    SapOption('T090', '90 days due net'),
    SapOption('T120', '120 days due net'),
    // Due on a day of the following month.
    SapOption('TN05', 'Due 05th next month'),
    SapOption('TN15', 'Due 15th next month'),
    SapOption('TN20', 'Due 20th next month'),
    SapOption('TN25', 'Due 25th next month'),
    SapOption('TN30', 'Due 30th next month'),
    SapOption('TN50', 'Due 50th next month'),
    SapOption('TN60', 'Due 60th next month'),
    // Letter of credit — export trade.
    SapOption('LCAS', 'LC At sight'),
    SapOption('LC30', 'LC after sight 30 days'),
    SapOption('LC45', 'LC after sight 45 days'),
    SapOption('LC60', 'LC after sight 60 days'),
    SapOption('LC90', 'LC after sight 90 days'),
    SapOption('BL30', 'LC after BL date 30days'),
    SapOption('BL45', 'LC after BL date 45days'),
    SapOption('BL60', 'LC after BL date 60days'),
    SapOption('BL90', 'LC after BL date 90days'),
  ];

  /// Payment terms that settle before or on delivery, so no credit is extended.
  ///
  /// The old rule was `code != 'T00'`, against a hard-coded list whose only
  /// cash term was `T00` — a code SAP does not publish. Every real term
  /// therefore looked like a credit sale, including cash on delivery.
  static const Set<String> cashPaymentTerms = {'TCIA', 'TCOD'};

  /// True when the term extends credit and so needs HQ approval.
  ///
  /// Unknown codes are treated as credit deliberately: a term this build has
  /// not seen is more safely routed through an approval it did not need than
  /// waved through as cash it was not.
  static bool paymentTermNeedsCreditApproval(String? code) =>
      code != null && code.isNotEmpty && !cashPaymentTerms.contains(code);

  static const List<SapOption> taxClass = [
    SapOption('0', 'Non VAT'),
    SapOption('1', 'VAT (Liable)'),
  ];

  static const List<SapOption> currency = [
    SapOption('USD', 'US Dollar'),
    SapOption('KHR', 'Riel'),
  ];

  const SapMasterData._();
}

/// Sales-area context of the logged-in rep. Injected from the auth/session
/// layer — the rep never types these.
class RepSalesContext {
  final String salesOrganization; // 0001 - PhnomPenh ISI
  final String salesOrganizationName;
  final String salesOffice; // 0001 - Phnom Penh
  final String salesOfficeName;
  final String salesEmployeeId; // 107576
  final String salesEmployeeName; // Mengchou CHORN
  final String defaultCurrency; // USD

  const RepSalesContext({
    required this.salesOrganization,
    required this.salesOrganizationName,
    required this.salesOffice,
    required this.salesOfficeName,
    required this.salesEmployeeId,
    required this.salesEmployeeName,
    this.defaultCurrency = 'USD',
  });
}

/// A GPS fix captured on site.
class GeoFix {
  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final DateTime capturedAt;

  const GeoFix({
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    this.accuracyMeters,
  });

  /// Rough Cambodia bounding box — rejects an emulator fix or a stale
  /// last-known location from another country.
  bool get isInsideCambodia =>
      latitude >= 9.9 &&
      latitude <= 14.7 &&
      longitude >= 102.3 &&
      longitude <= 107.7;

  String get display =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}

/// One captured document / photo, held on the device until the customer exists.
///
/// Evidence cannot be uploaded during the wizard: the documents endpoint is
/// addressed by customer id, and the customer is not created until submit. So
/// the rep photographs the shop while standing in it, and the files go up once
/// the registration has returned an id
/// (`docs/feature/customer/mobile/customer-documents.md` §Flow).
class BpAttachment {
  final String
      kind; // outlet_front | outlet_inside | id_card | patent_tax | vat_cert
  final String localPath;
  final String? remoteUrl;

  /// When the photograph was taken.
  ///
  /// Stamped here rather than at upload because the upload happens after
  /// submit and may be minutes or hours later; dating the evidence to when the
  /// connection came back would misrepresent the visit.
  final DateTime capturedAt;

  BpAttachment({
    required this.kind,
    required this.localPath,
    this.remoteUrl,
    DateTime? capturedAt,
  }) : capturedAt = capturedAt ?? DateTime.now().toUtc();

  /// The form's local slot names, paired with the API's codes.
  ///
  /// The two vocabularies are kept apart on purpose: the tile keys are UI
  /// identifiers with their own history (`outlet_front`), and the codes are the
  /// wire contract. Renaming either without the other would silently drop a
  /// photograph, so the pairing lives in exactly one place.
  static const Map<String, CustomerDocumentType> kindToDocumentType = {
    'outlet_front': CustomerDocumentType.storefront,
    'outlet_inside': CustomerDocumentType.insideStore,
    'id_card': CustomerDocumentType.idCard,
    'patent_tax': CustomerDocumentType.patentTax,
    'vat_cert': CustomerDocumentType.vatCertificate,
  };

  /// The API slot this attachment belongs in, or null for an unrecognised kind.
  CustomerDocumentType? get documentType => kindToDocumentType[kind];

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'local_path': localPath,
        if (remoteUrl != null) 'url': remoteUrl,
      };
}

// =============================================================================
// The draft the rep builds up across the five steps.
// =============================================================================
class BpCustomerDraft {
  // --- Step 1: Identity -------------------------------------------------
  String grouping; // REP   Grouping            (Z001)
  String title; // REP   Title               (0003)
  String nameEn; // REP   Name 1 (EN)        *
  String nameKh; // REP   Name 3 (KH)        *
  String name2; // REP   Name 2              (optional)
  String searchTerm; // REP   Search Name 1/2      (optional, auto-suggest)
  String coName; // REP   CO-Name             (optional)

  // --- Step 2: Address --------------------------------------------------
  String street; // REP   Street / House Number
  String houseNumber; // REP
  String? cityCode; // REP   City / Province     *
  String? districtCode; // REP   District            *
  String? communeCode; // REP   Commune             *
  String? villageCode; // REP   Village             (optional)
  String postalCode; // DERIVE+REP Postal Code    *
  GeoFix? geoFix; // REP   Latitude / Longitude *
  String language; // REP   Language            (default EN)
  GeoAddress? geoAddress; // Domain gazetteer address

  // --- Step 3: Contact --------------------------------------------------
  String mobilePhone; // REP   Mobile Phone        *
  String telephone; // REP   Telephone           * (may mirror mobile)
  bool telephoneSameAsMobile;
  String faxNumber; // REP   Fax Number          (optional)
  String contactPersonName; // REP   (app CRM, sent as BP contact person)
  String? contactPersonRole;

  // --- Step 4: Sales & billing terms ------------------------------------
  //
  // The sales area (salesOrg + distributionChannel + division) is one of the
  // five field groups a record must carry to be registerable in SAP at all —
  // without it the push is marked `Rejected` without SAP even being called
  // (`docs/feature/customer/mobile/create-customer.md` §Path B).
  String? salesOrg; // REP   Sales Organization   *
  String? salesOffice; // REP   Sales Office      *
  String? salesGroupCode; // REP   Sales Group     *
  String? distributionChannel; // REP   Distribution Channel *
  String? divisionCode; // REP   Division             *
  String? customerGroup; // REP   Customer Group       *
  String? priceGroup; // DERIVE Price Group          *
  String? deliveryPriority; // REP   Delivery Priority    *
  String? shippingCondition; // REP   Shipping Condition   *
  String? paymentTerm; // REP   Payment Term         *
  String? taxClass; // REP   Tax Class            *
  String vatTin; // REP   (required when taxClass == '1')
  String currency; // DERIVE Currency             *

  // --- Step 5: Documents ------------------------------------------------
  final List<BpAttachment> attachments;
  String remark;

  BpCustomerDraft({
    this.grouping = 'Z001',
    this.title = '0003',
    this.nameEn = '',
    this.nameKh = '',
    this.name2 = '',
    this.searchTerm = '',
    this.coName = '',
    this.street = '',
    this.houseNumber = '',
    this.cityCode,
    this.districtCode,
    this.communeCode,
    this.villageCode,
    this.postalCode = '',
    this.geoFix,
    this.language = SapBpConst.defaultLanguage,
    this.geoAddress,
    this.mobilePhone = '',
    this.telephone = '',
    this.telephoneSameAsMobile = true,
    this.faxNumber = '',
    this.contactPersonName = '',
    this.contactPersonRole,
    this.salesOrg,
    this.salesOffice,
    this.salesGroupCode,
    this.distributionChannel = '10',
    this.divisionCode = '10',
    this.customerGroup,
    this.priceGroup,
    this.deliveryPriority = '01',
    this.shippingCondition = '01',
    this.paymentTerm = 'TCOD',
    this.taxClass = '0',
    this.vatTin = '',
    this.currency = 'USD',
    List<BpAttachment>? attachments,
    this.remark = '',
  }) : attachments = attachments ?? <BpAttachment>[];

  /// Applies the server-owned draft returned by `POST draft` and `POST update`.
  /// The API field names are deliberately kept at the boundary; the form keeps
  /// its more readable Flutter names.
  void applyServerFields(Map<String, dynamic> fields) {
    String stringValue(String key, [String fallback = '']) {
      final value = fields[key];
      return value == null ? fallback : value.toString();
    }

    String? nullableString(String key, [String? fallback]) {
      final value = fields[key];
      if (value == null || value.toString().isEmpty) return fallback;
      return value.toString();
    }

    grouping =
        stringValue('accountGroup', stringValue('partnerGroup', grouping));
    title = stringValue('title', title);
    nameEn = stringValue('name1', nameEn);
    name2 = stringValue('name2', name2);
    nameKh = stringValue('name3', nameKh);
    searchTerm = stringValue('searchTerm1', searchTerm);
    coName = stringValue('coName', coName);
    street = stringValue('street', street);
    houseNumber = stringValue('houseNo', houseNumber);
    if (fields.containsKey('city')) cityCode = nullableString('city', cityCode);
    if (fields.containsKey('district')) {
      districtCode = nullableString('district', districtCode);
    }
    if (fields.containsKey('commune')) {
      communeCode = nullableString('commune', communeCode);
    } else if (fields.containsKey('communeCode')) {
      communeCode = nullableString('communeCode', communeCode);
    }
    if (fields.containsKey('village')) {
      villageCode = nullableString('village', villageCode);
    } else if (fields.containsKey('villageCode')) {
      villageCode = nullableString('villageCode', villageCode);
    }
    postalCode = stringValue('postalCode', postalCode);
    language = stringValue('language', language);
    mobilePhone = stringValue('mobilePhone', mobilePhone);
    telephone = stringValue('telephone', telephone);
    telephoneSameAsMobile = telephone.isEmpty || telephone == mobilePhone;
    faxNumber = stringValue('faxNumber', faxNumber);
    contactPersonName = stringValue('contactPersonName', contactPersonName);
    if (fields.containsKey('contactPersonRole')) {
      contactPersonRole =
          nullableString('contactPersonRole', contactPersonRole);
    }
    if (fields.containsKey('salesOrg')) {
      salesOrg = nullableString('salesOrg', salesOrg);
    }
    if (fields.containsKey('salesOffice')) {
      salesOffice = nullableString('salesOffice', salesOffice);
    }
    if (fields.containsKey('salesGroup')) {
      salesGroupCode = nullableString('salesGroup', salesGroupCode);
    }
    if (fields.containsKey('distributionChannel')) {
      distributionChannel =
          nullableString('distributionChannel', distributionChannel);
    }
    if (fields.containsKey('division')) {
      divisionCode = nullableString('division', divisionCode);
    }
    if (fields.containsKey('customerGroup')) {
      customerGroup = nullableString('customerGroup', customerGroup);
    }
    if (fields.containsKey('priceGroup')) {
      priceGroup = nullableString('priceGroup', priceGroup);
    }
    if (fields.containsKey('deliveryPriority')) {
      deliveryPriority = nullableString('deliveryPriority', deliveryPriority);
    }
    if (fields.containsKey('shippingCondition')) {
      shippingCondition =
          nullableString('shippingCondition', shippingCondition);
    }
    if (fields.containsKey('paymentTerms')) {
      paymentTerm = nullableString('paymentTerms', paymentTerm);
    }
    if (fields.containsKey('taxClass')) {
      taxClass = nullableString('taxClass', taxClass);
    }
    vatTin = stringValue('vatTin', vatTin);
    currency = stringValue('currency', currency);
    remark = stringValue('remark', remark);

    final latitude = fields['latitude'];
    final longitude = fields['longitude'];
    if (latitude is num && longitude is num) {
      geoFix = GeoFix(
        latitude: latitude.toDouble(),
        longitude: longitude.toDouble(),
        capturedAt: DateTime.now(),
      );
    }
  }

  bool get hasKhmerName => RegExp(r'[\u1780-\u17FF]').hasMatch(nameKh);

  bool hasAttachment(String kind) => attachments.any((a) => a.kind == kind);

  String get effectiveTelephone =>
      telephoneSameAsMobile ? mobilePhone : telephone;

  /// SAP's street line, carrying the two levels SAP has no field for.
  ///
  /// The BP structure has `city`, `district` and `postalCode` and stops there —
  /// there is no commune/sangkat field and no village field
  /// (`docs/features/create_BP/customer-mobile-registration/api.md`). Sending
  /// them as extra keys would leave them to be dropped by a middleware that
  /// does not model them, so the two levels are folded into the one free-text
  /// field that does reach SAP.
  ///
  /// Ordered street → village → commune because SAP's `STREET` is 60
  /// characters and this truncates from the end: what a delivery driver needs
  /// most is at the front. Province and district are deliberately absent —
  /// they already travel as their own fields, and repeating them would spend
  /// the character budget on data SAP already has.
  String get sapStreetLine {
    final parts = <String>[];
    final base = street.trim();
    if (base.isNotEmpty) parts.add(base);

    final village = geoAddress?.village;
    if (village != null) parts.add('Phum ${village.name.resolve('en')}');

    final commune = geoAddress?.commune;
    if (commune != null) {
      final word = commune.unit == 'Sangkat' ? 'Sangkat' : 'Khum';
      parts.add('$word ${commune.name.resolve('en')}');
    }

    final line = parts.join(', ');
    return line.length <= _sapStreetMaxLength
        ? line
        : line.substring(0, _sapStreetMaxLength).trimRight();
  }

  /// SAP `ADRC-STREET`.
  static const int _sapStreetMaxLength = 60;

  /// Keep the derived fields consistent whenever a driver field changes.
  /// [priceGroupResolver] resolves the price group from the customer group,
  /// normally `SapReferenceOptions.priceGroupFor`, which matches the two ERP
  /// catalogues by name.
  ///
  /// Optional so the model stays usable without the catalogues loaded; when it
  /// is absent the built-in pairing is used instead.
  void applyDerivations({String? Function(String?)? priceGroupResolver}) {
    // The postal code is NOT derived here any more. It comes from the selected
    // commune, via the gazetteer (`GeoAddress.postalCode`), and the selector
    // writes it onto the draft.
    //
    // The old rule — fill an empty postal code from a per-district table —
    // has to stay gone rather than act as a fallback. That table holds the
    // superseded five-digit Phnom Penh codes, and the case where it would now
    // fire is precisely the case it gets wrong: `postalCode` is empty exactly
    // when the chosen commune is one of the 99 Cambodia Post does not cover,
    // and filling it from the *district* would ship a code for a different
    // place. `validateStep` blocks submission instead, and the rep types the
    // real code — never a silently wrong one (§10).
    if (customerGroup != null) {
      // The resolver matches the ERP's own customer-group and price-group
      // catalogues by name, so a pairing added in SAP works without an app
      // release. The built-in map is the offline fallback.
      priceGroup = priceGroupResolver?.call(customerGroup) ??
          SapMasterData.priceGroupByCustomerGroup[customerGroup!];
    }
    if (searchTerm.isEmpty && nameEn.isNotEmpty) {
      searchTerm = nameEn.split(RegExp(r'\s+')).first.toUpperCase();
    }
  }

  // ---------------------------------------------------------------------
  // Per-step validation. Returns field-key -> i18n error key.
  // The UI blocks "Next" while the map is non-empty.
  // ---------------------------------------------------------------------
  Map<String, String> validateStep(BpFormStep step) {
    final e = <String, String>{};

    switch (step) {
      case BpFormStep.identity:
        if (grouping.isEmpty) e['grouping'] = 'error.required';
        if (title.isEmpty) e['title'] = 'error.required';
        if (nameEn.trim().isEmpty) {
          e['nameEn'] = 'error.required';
        } else if (nameEn.trim().length > 40) {
          e['nameEn'] = 'error.max_40'; // SAP NAME1 is 40 chars
        }
        if (nameKh.trim().isEmpty) {
          e['nameKh'] = 'error.required';
        } else if (!hasKhmerName) {
          e['nameKh'] = 'error.must_be_khmer';
        }
        break;

      case BpFormStep.address:
        if (cityCode == null || cityCode!.isEmpty) e['city'] = 'error.required';
        if (districtCode == null || districtCode!.isEmpty) {
          e['district'] = 'error.required';
        }
        if ((communeCode == null || communeCode!.isEmpty) &&
            geoAddress?.commune == null) {
          e['commune'] = 'error.required';
        }
        // Six digits is the current Cambodia Post scheme and what the
        // gazetteer supplies. Five is still accepted because a rep may be
        // editing a draft saved under the superseded scheme, and rejecting
        // their own stored value would strand them on this step.
        if (!RegExp(r'^\d{5,6}$').hasMatch(postalCode.trim())) {
          e['postalCode'] = 'error.postal_code';
        }
        if (geoFix == null) {
          e['geo'] = 'error.gps_required';
        } else if (!geoFix!.isInsideCambodia) {
          e['geo'] = 'error.gps_outside_kh';
        }
        break;

      case BpFormStep.contact:
        if (mobilePhone.trim().isEmpty) e['mobilePhone'] = 'error.required';
        if (!telephoneSameAsMobile && telephone.trim().isEmpty) {
          e['telephone'] = 'error.required';
        }
        if (contactPersonName.trim().isEmpty) {
          e['contactPersonName'] = 'error.required';
        }
        if (contactPersonRole == null) {
          e['contactPersonRole'] = 'error.required';
        }
        break;

      case BpFormStep.salesTerms:
        // Treated as required even though the server accepts them absent: a
        // record missing the sales area saves happily and can then never be
        // delivered to SAP, which is worse than a validation error the rep can
        // fix while still standing in the shop.
        if (salesOrg == null) e['salesOrg'] = 'error.required';
        if (salesOffice == null) e['salesOffice'] = 'error.required';
        if (salesGroupCode == null) e['salesGroup'] = 'error.required';
        if (distributionChannel == null) {
          e['distributionChannel'] = 'error.required';
        }
        if (divisionCode == null) e['division'] = 'error.required';
        if (customerGroup == null) e['customerGroup'] = 'error.required';
        if (deliveryPriority == null) e['deliveryPriority'] = 'error.required';
        if (shippingCondition == null) {
          e['shippingCondition'] = 'error.required';
        }
        if (paymentTerm == null) e['paymentTerm'] = 'error.required';
        if (taxClass == null) {
          e['taxClass'] = 'error.required';
        } else if (taxClass == '1' && vatTin.trim().isEmpty) {
          e['vatTin'] = 'error.vat_tin_required';
        }
        break;

      case BpFormStep.documents:
        if (!hasAttachment('outlet_front')) {
          e['outlet_front'] = 'error.photo_required';
        }
        if (!hasAttachment('outlet_inside')) {
          e['outlet_inside'] = 'error.photo_required';
        }
        if (!hasAttachment('id_card')) {
          e['id_card'] = 'error.photo_required';
        }
        if (taxClass == '1' && !hasAttachment('vat_cert')) {
          e['vat_cert'] = 'error.photo_required';
        }
        break;
    }
    return e;
  }

  bool isStepComplete(BpFormStep step) => validateStep(step).isEmpty;

  bool get isReadyToSubmit => BpFormStep.values.every(isStepComplete);

  // ---------------------------------------------------------------------
  // Outbound payload — mirrors the SAP BP structure so the middleware maps
  // 1:1 without guessing.
  // ---------------------------------------------------------------------
  Map<String, dynamic> toSapPayload(RepSalesContext rep) {
    applyDerivations();

    return {
      'name1': nameEn.trim(),
      'name2': name2.trim(),
      'name3': nameKh.trim(),
      'title': title,
      'partnerCategory': SapBpConst.partnerCategory,
      'partnerGroup': grouping,
      'bpRole': SapBpConst.bpRole,
      'accountGroup': grouping,
      'country': SapBpConst.country,
      'region': SapBpConst.region,
      'city': cityCode,
      'district': districtCode,
      'street': sapStreetLine,
      'houseNo': houseNumber.trim(),
      'postalCode': postalCode,
      'mobilePhone': mobilePhone,
      'telephone': effectiveTelephone,
      'faxNumber': faxNumber,
      'contactPersonName': contactPersonName.trim(),
      'contactPersonRole': contactPersonRole,
      'language': language,
      // The rep's own selection, falling back to their session's sales area.
      // This previously always sent the session value, so a rep registering a
      // shop outside their home office filed it against the wrong one.
      'salesOrg': salesOrg ?? rep.salesOrganization,
      'distributionChannel': distributionChannel,
      'division': divisionCode,
      'customerGroup': customerGroup,
      'deliveryPriority': deliveryPriority,
      'shippingCondition': shippingCondition,
      'salesOffice': salesOffice ?? rep.salesOffice,
      'salesGroup': salesGroupCode ?? SapBpConst.salesGroup,
      'currency': currency,
      'priceGroup': priceGroup,
      'paymentTerms': paymentTerm,
      'taxClass': taxClass,
      'vatTin': taxClass == '1' ? vatTin.trim() : null,
      'searchTerm1': searchTerm.trim(),
      'latitude': geoFix?.latitude,
      'longitude': geoFix?.longitude,
      'territory': null,
      'submitToSap': true,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'remark': remark.trim(),
    };
  }
}

// =============================================================================
// Read-only block. Populated from SAP after HQ approves; rendered on the
// customer detail screen, NOT inside the creation flow.
// =============================================================================
class BpSapEcho {
  final String? customerCode; // assigned by SAP number range
  final String? reconciliationAccount; // 11001010 - AR End User
  final String? companyCode; // ISI
  final String? paymentTermFi;
  final num? creditLimit; // 50000
  final DateTime? creditChangedOn;
  final bool salesOrderBlock;
  final bool salesSupportBlock;
  final bool deletionFlag;
  final String? createdBy;
  final DateTime? createdOn;
  final String? lastChangedBy;
  final DateTime? lastChangedOn;
  final String? bankKey;
  final String? bankAccount;
  final String? accountHolder;
  final String? financeInstitution;

  const BpSapEcho({
    this.customerCode,
    this.reconciliationAccount,
    this.companyCode,
    this.paymentTermFi,
    this.creditLimit,
    this.creditChangedOn,
    this.salesOrderBlock = false,
    this.salesSupportBlock = false,
    this.deletionFlag = false,
    this.createdBy,
    this.createdOn,
    this.lastChangedBy,
    this.lastChangedOn,
    this.bankKey,
    this.bankAccount,
    this.accountHolder,
    this.financeInstitution,
  });
}
