/// A customer/business-partner row as returned by the SAP façade's
/// `Customer/Read`, `Customer/GetDetail` and `Customer/GetPaging` endpoints.
///
/// **Field-name caveat.** `SapAPI_Technical_Document_v1_BP.docx` specifies the
/// *Create* body exhaustively (§5.4) but describes the read responses only
/// narratively — §5.2 lists "customer, names, sales area, address, phone,
/// payment terms, credit limit, sales employee" and the one worked example
/// (§5.3) shows just `{ "customer": ..., "nameEn": ..., ... }`. The exact
/// response keys are therefore **not fully pinned down by the document**.
///
/// This DTO reads each field through a small list of candidate keys rather than
/// guessing one and breaking on contact with the real service. Every candidate
/// set is anchored on a name the document actually uses. **Verify against live
/// Swagger before production** — `parsedFieldCount` exists so a smoke test can
/// assert a payload was genuinely understood rather than silently read as nulls.
class SapBusinessPartner {
  const SapBusinessPartner({
    required this.customerNumber,
    this.name1,
    this.nameEn,
    this.name3,
    this.street,
    this.city,
    this.country,
    this.district,
    this.mobilePhone,
    this.telephone,
    this.email,
    this.salesOrg,
    this.distributionChannel,
    this.division,
    this.customerGroup,
    this.paymentTerms,
    this.currency,
    this.creditLimit,
    this.salesEmployee,
    this.salesEmployeeName,
    this.parsedFieldCount = 0,
  });

  /// SAP business-partner number, e.g. `0001000123`. The only field the app
  /// treats as mandatory — a row without it cannot be keyed or updated.
  final String customerNumber;

  final String? name1;
  final String? nameEn;
  final String? name3;

  final String? street;
  final String? city;
  final String? country;
  final String? district;

  final String? mobilePhone;
  final String? telephone;
  final String? email;

  final String? salesOrg;
  final String? distributionChannel;
  final String? division;
  final String? customerGroup;
  final String? paymentTerms;
  final String? currency;

  final double? creditLimit;

  final String? salesEmployee;
  final String? salesEmployeeName;

  /// How many fields were resolved to a non-null value. Used by the smoke test
  /// to catch a response whose keys do not match any candidate — which would
  /// otherwise present as a page of blank customers rather than an error.
  final int parsedFieldCount;

  /// Best available display name, preferring the English name.
  String? get displayName => _firstNonEmpty([nameEn, name1, name3]);

  /// Single-line address assembled from the parts SAP returns.
  String get formattedAddress => [street, city, country]
      .whereType<String>()
      .where((s) => s.isNotEmpty)
      .join(', ');

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
          'customer',
          'customerNumber',
          'Customer',
          'CustomerNumber',
          'kunnr',
        ]) ??
        '';

    return SapBusinessPartner(
      customerNumber: number,
      name1: str(const ['name1', 'Name1']),
      nameEn: str(const ['nameEn', 'NameEn', 'enName', 'EnName']),
      name3: str(const ['name3', 'Name3']),
      street: str(const ['street', 'Street']),
      city: str(const ['city', 'City']),
      country: str(const ['country', 'Country']),
      district: str(const ['district', 'District']),
      mobilePhone: str(const ['mobilePhone', 'MobilePhone', 'mobile']),
      telephone: str(const ['telephone', 'Telephone', 'phone', 'Phone']),
      email: str(const ['email', 'Email', 'smtpAddr']),
      salesOrg: str(const ['salesOrg', 'SalesOrg']),
      distributionChannel: str(
          const ['distributionChannel', 'DistributionChannel', 'disChannel']),
      division: str(const ['division', 'Division']),
      customerGroup: str(const ['customerGroup', 'CustomerGroup', 'custGroup']),
      paymentTerms: str(const ['paymentTerms', 'PaymentTerms', 'paymentTerm']),
      currency: str(const ['currency', 'Currency']),
      creditLimit: dbl(const ['creditLimit', 'CreditLimit']),
      salesEmployee: str(const ['salesEmployee', 'SalesEmployee']),
      salesEmployeeName: str(const ['salesEmployeeName', 'SalesEmployeeName']),
      parsedFieldCount: parsed,
    );
  }

  /// Reads the first key present and non-blank.
  ///
  /// Trailing/leading whitespace is stripped and blanks are treated as absent:
  /// SAP pads fixed-width character fields, so `"     "` is how an empty value
  /// commonly arrives, and storing that would render as a mysterious gap in the
  /// UI rather than as "unknown".
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

  static String? _firstNonEmpty(List<String?> candidates) {
    for (final candidate in candidates) {
      if (candidate != null && candidate.isNotEmpty) return candidate;
    }
    return null;
  }
}

/// One page of `Customer/GetPaging` (technical document §5.3).
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
  final int totalCount;
  final int totalPages;
  final List<SapBusinessPartner> rows;

  /// SAP pages are 1-based (`page` defaults to 1), unlike the app's existing
  /// 0-based sync loop. The conversion happens in the datasource, so this stays
  /// a faithful representation of what SAP sent.
  bool get hasMore => page < totalPages;

  static const empty = SapCustomerPage(
    page: 1,
    pageSize: 0,
    totalCount: 0,
    totalPages: 0,
    rows: [],
  );

  factory SapCustomerPage.fromJson(Map<String, dynamic> json) {
    final rows = json['rows'];
    return SapCustomerPage(
      page: _int(json['page']) ?? 1,
      pageSize: _int(json['pageSize']) ?? 0,
      totalCount: _int(json['totalCount']) ?? 0,
      totalPages: _int(json['totalPages']) ?? 0,
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
