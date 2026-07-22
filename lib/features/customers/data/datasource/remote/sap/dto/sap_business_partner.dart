/// A customer/business-partner row as returned by the SAP façade's
/// `Customer/GetPaging` endpoint.
///
/// **Field names are taken from a captured live response (2026-07-22,
/// `GetPaging/Live110`)**, which supersedes the technical document's narrative
/// description. The live server sends PascalCase (`Customer`, `NameEn`,
/// `SALESBLOCK`…); the document showed camelCase. Candidate-key reading is kept
/// so a server-side serializer change cannot silently blank every customer, but
/// the live spelling now leads each candidate list.
///
/// Notable live-contract facts this DTO encodes:
/// * `Latitude`/`Longitude` exist and arrive as **strings** (`"11.383211"`,
///   or `""` for most walk-in customers) — the document claimed no geolocation.
/// * `NameKh` is the Khmer name key, not the document's `name3`.
/// * Every classification code ships with a display-name twin
///   (`PaymentTerms` = `T015`, `PaymentTermsName` = `15 days due net`).
/// * `CreationDate` is `yyyyMMdd`, with `"00000000"` meaning "none".
/// * Block state is spread over `OrderBlock`, `SALESBLOCK` and `BLOCKFLAG`
///   (`"X"` = set).
/// * There is **no currency field**.
/// * The same customer number appears once **per sales area** — a page of 50
///   rows is not 50 distinct customers.
class SapBusinessPartner {
  const SapBusinessPartner({
    required this.customerNumber,
    this.nameEn,
    this.nameKh,
    this.coName,
    this.street,
    this.city,
    this.country,
    this.region,
    this.searchTerm1,
    this.searchTerm2,
    this.latitude,
    this.longitude,
    this.mobilePhone,
    this.telephone,
    this.salesOrg,
    this.salesOrgName,
    this.distributionChannel,
    this.distributionChannelName,
    this.division,
    this.divisionName,
    this.customerGroup,
    this.customerGroupName,
    this.priceGroup,
    this.priceGroupName,
    this.paymentTerms,
    this.paymentTermsName,
    this.creditLimit,
    this.creationDate,
    this.orderBlock,
    this.salesBlock,
    this.blockFlag,
    this.salesEmployee,
    this.salesEmployeeName,
    this.parsedFieldCount = 0,
  });

  /// SAP business-partner number, e.g. `6100000000`. The only field the app
  /// treats as mandatory — a row without it cannot be keyed or updated.
  final String customerNumber;

  final String? nameEn;
  final String? nameKh;

  /// Care-of / co-operative name, e.g. `ISI KEY DEPOT`.
  final String? coName;

  final String? street;
  final String? city;
  final String? country;

  /// SAP region key (`R01`…), not a display name.
  final String? region;

  /// Uppercased province/branch name (`PHNOM PENH`, `BATTAMBANG`).
  final String? searchTerm1;

  /// Legacy human customer code (`IC00000001`) — what staff recognise.
  final String? searchTerm2;

  final double? latitude;
  final double? longitude;

  final String? mobilePhone;
  final String? telephone;

  final String? salesOrg;
  final String? salesOrgName;
  final String? distributionChannel;
  final String? distributionChannelName;
  final String? division;
  final String? divisionName;
  final String? customerGroup;
  final String? customerGroupName;
  final String? priceGroup;
  final String? priceGroupName;
  final String? paymentTerms;
  final String? paymentTermsName;

  final double? creditLimit;
  final DateTime? creationDate;

  final String? orderBlock;
  final String? salesBlock;
  final String? blockFlag;

  final String? salesEmployee;
  final String? salesEmployeeName;

  /// How many fields resolved to a non-null value. A smoke test asserts this is
  /// non-trivial so an unrecognised payload surfaces as a failure, not as a
  /// page of blank customers.
  final int parsedFieldCount;

  /// Best available display name.
  String? get displayName => _firstNonEmpty([nameEn, nameKh, coName]);

  /// Single-line address from the parts SAP populated (mostly empty for
  /// walk-in accounts).
  String get formattedAddress => [street, city, country]
      .whereType<String>()
      .where((s) => s.isNotEmpty)
      .join(', ');

  /// Whether SAP has this partner blocked in any of its three block fields.
  ///
  /// `X` is SAP's boolean-true; any non-empty value counts as blocked rather
  /// than allow-listing `X` alone, so a new block code fails safe.
  bool get isBlocked => [orderBlock, salesBlock, blockFlag]
      .any((flag) => flag != null && flag.isNotEmpty);

  factory SapBusinessPartner.fromJson(Map<String, dynamic> json) {
    var parsed = 0;

    String? str(List<String> keys) {
      final value = _readString(json, keys);
      if (value != null) parsed++;
      return value;
    }

    double? dbl(List<String> keys) {
      final value = _readDouble(json, keys);
      if (value != null) parsed++;
      return value;
    }

    final number = _readString(json, const [
          'Customer',
          'customer',
          'CustomerNumber',
          'customerNumber',
        ]) ??
        '';

    return SapBusinessPartner(
      customerNumber: number,
      nameEn: str(const ['NameEn', 'nameEn', 'Name1', 'name1']),
      nameKh: str(const ['NameKh', 'nameKh', 'Name3', 'name3']),
      coName: str(const ['CoName', 'coName']),
      street: str(const ['Street', 'street']),
      city: str(const ['City', 'city']),
      country: str(const ['Country', 'country']),
      region: str(const ['Region', 'region']),
      searchTerm1: str(const ['SearchTerm1', 'searchTerm1']),
      searchTerm2: str(const ['SearchTerm2', 'searchTerm2']),
      // Strings on the wire ("11.383211"); `_readDouble` parses them and reads
      // "" as absent — never as 0.0, which is a real place in the Gulf of
      // Guinea.
      latitude: dbl(const ['Latitude', 'latitude']),
      longitude: dbl(const ['Longitude', 'longitude']),
      mobilePhone: str(const ['MobilePhone', 'mobilePhone']),
      telephone: str(const ['Telephone', 'telephone']),
      salesOrg: str(const ['SalesOrg', 'salesOrg']),
      salesOrgName: str(const ['SalesOrgName', 'salesOrgName']),
      distributionChannel:
          str(const ['DistributionChannel', 'distributionChannel']),
      distributionChannelName:
          str(const ['DistributionChannelName', 'distributionChannelName']),
      division: str(const ['Division', 'division']),
      divisionName: str(const ['DivisionName', 'divisionName']),
      customerGroup: str(const ['CustomerGroup', 'customerGroup']),
      customerGroupName: str(const ['CustomerGroupName', 'customerGroupName']),
      priceGroup: str(const ['PriceGroup', 'priceGroup']),
      priceGroupName: str(const ['PriceGroupName', 'priceGroupName']),
      paymentTerms: str(const ['PaymentTerms', 'paymentTerms']),
      paymentTermsName: str(const ['PaymentTermsName', 'paymentTermsName']),
      creditLimit: dbl(const ['CreditLimit', 'creditLimit']),
      creationDate: _readSapDate(
          _readString(json, const ['CreationDate', 'creationDate'])),
      orderBlock: str(const ['OrderBlock', 'orderBlock']),
      // The live payload really does shout this one field.
      salesBlock: str(const ['SALESBLOCK', 'SalesBlock', 'salesBlock']),
      blockFlag: str(const ['BLOCKFLAG', 'BlockFlag', 'blockFlag']),
      salesEmployee: str(const ['SalesEmployee', 'salesEmployee']),
      salesEmployeeName: str(const ['SalesEmployeeName', 'salesEmployeeName']),
      parsedFieldCount: parsed,
    );
  }

  /// Reads the first key present and non-blank.
  ///
  /// Whitespace-only values are treated as absent: SAP pads fixed-width fields,
  /// and storing `"   "` renders as a mysterious gap rather than "unknown".
  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) return trimmed;
      } else if (value is num) {
        return value.toString();
      }
    }
    return null;
  }

  static double? _readDouble(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  /// Parses SAP's `yyyyMMdd` date, where `"00000000"` (and anything
  /// unparsable) means "no date".
  static DateTime? _readSapDate(String? raw) {
    if (raw == null || raw.length != 8 || raw == '00000000') return null;
    final year = int.tryParse(raw.substring(0, 4));
    final month = int.tryParse(raw.substring(4, 6));
    final day = int.tryParse(raw.substring(6, 8));
    if (year == null || month == null || day == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime.utc(year, month, day);
  }

  static String? _firstNonEmpty(List<String?> candidates) {
    for (final candidate in candidates) {
      if (candidate != null && candidate.isNotEmpty) return candidate;
    }
    return null;
  }
}

/// One page of `Customer/GetPaging`.
///
/// The live envelope is PascalCase — `{Page, PageSize, TotalCount, TotalPages,
/// Rows}` — where the document showed camelCase. The first integration attempt
/// read lowercase keys only, which parsed every real response as an empty page:
/// zero rows, zero pages, sync "succeeds" with nothing. [fromJson] therefore
/// reads both spellings, and the regression test pins the PascalCase one.
class SapCustomerPage {
  const SapCustomerPage({
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.rows,
  });

  final int page;
  final int pageSize;

  /// Row count, **not** distinct-customer count: SAP emits one row per sales
  /// area, so one customer can contribute several rows (the live capture shows
  /// eight for the Phnom Penh walk-in account).
  final int totalCount;
  final int totalPages;
  final List<SapBusinessPartner> rows;

  /// SAP pages are 1-based (`Page` starts at 1).
  bool get hasMore => page < totalPages;

  static const empty = SapCustomerPage(
    page: 1,
    pageSize: 0,
    totalCount: 0,
    totalPages: 0,
    rows: [],
  );

  factory SapCustomerPage.fromJson(Map<String, dynamic> json) {
    Object? read(String pascal, String camel) => json[pascal] ?? json[camel];

    final rows = read('Rows', 'rows');
    return SapCustomerPage(
      page: _int(read('Page', 'page')) ?? 1,
      pageSize: _int(read('PageSize', 'pageSize')) ?? 0,
      totalCount: _int(read('TotalCount', 'totalCount')) ?? 0,
      totalPages: _int(read('TotalPages', 'totalPages')) ?? 0,
      rows: rows is List
          ? rows
              .whereType<Map>()
              .map((r) =>
                  SapBusinessPartner.fromJson(Map<String, dynamic>.from(r)))
              .toList(growable: false)
          : const [],
    );
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
