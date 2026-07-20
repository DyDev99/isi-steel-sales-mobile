/// Every SAP façade path, in one place.
///
/// Datasources compose paths through these builders instead of writing string
/// literals, so a route change is a single edit here rather than a search across
/// features — and the `conId` path segment cannot be forgotten, which is the
/// easiest mistake to make against this API (every data route embeds it).
///
/// Source: `SapAPI_Technical_Document_v1_BP.docx` §3–§5.
/// Shape: `{baseUrl}/api/{Controller}/{Action}/{parameters}`.
abstract final class SapEndpoints {
  const SapEndpoints._();

  // ── Auth (§3) ────────────────────────────────────────────────────────
  /// The only endpoint that accepts no bearer token.
  static const String login = '/api/Auth/Login';

  // ── Customer / Business Partner (§5) ─────────────────────────────────
  static const String _customer = '/api/Customer';

  /// `GET` one full BP record, ready to edit and PUT back.
  static String readCustomer(String conId, String customerNumber) =>
      '$_customer/Read/$conId/$customerNumber';

  /// `GET` BP detail rows. Filters: `customer`, `salesOrg`, `division`,
  /// `enName`. Slow on large result sets — prefer [customerPaging].
  static String customerDetail(String conId) => '$_customer/GetDetail/$conId';

  /// `GET` server-side paged BP rows. Adds `page` (default 1) and `pageSize`
  /// (default 50) to the [customerDetail] filters.
  static String customerPaging(String conId) => '$_customer/GetPaging/$conId';

  /// `POST` a new business partner. `name1` is the only mandatory field.
  static String createCustomer(String conId) => '$_customer/Create/$conId';

  /// `PUT` an existing business partner. The URL customer number is the key and
  /// overrides any `customerNumber` in the body.
  static String updateCustomer(String conId, String customerNumber) =>
      '$_customer/Update/$conId/$customerNumber';

  // ── Customer Helper — dropdown master data (§4) ───────────────────────
  //
  // All nine share one shape: GET, `conId` in the path, one optional filter,
  // and a JSON array of rows in reply.
  static const String _helper = '/api/CustHelper';

  static String salesOrg(String conId) => '$_helper/GetSalesOrg/$conId';
  static String salesGroup(String conId) => '$_helper/GetSalesGroup/$conId';
  static String salesOffice(String conId) => '$_helper/GetSalesOffice/$conId';
  static String priceGroup(String conId) => '$_helper/GetPriceGroup/$conId';
  static String shipping(String conId) => '$_helper/GetShipping/$conId';
  static String paymentTerm(String conId) => '$_helper/GetPaymentTerm/$conId';
  static String distributionChannel(String conId) =>
      '$_helper/GetDisChannel/$conId';
  static String customerGroup(String conId) => '$_helper/GetCustGroup/$conId';

  /// The only helper endpoint accepting two filters: `employeeId` and
  /// `employeeName`.
  static String salesEmployee(String conId) =>
      '$_helper/GetSalesEmployee/$conId';

  // ── Query parameter names ────────────────────────────────────────────
  //
  // Named constants because SAP treats an omitted filter as "return
  // everything": a typo'd key is not rejected, it silently widens the query to
  // the full customer master.
  static const String qCustomer = 'customer';
  static const String qSalesOrg = 'salesOrg';
  static const String qDivision = 'division';
  static const String qEnName = 'enName';
  static const String qPage = 'page';
  static const String qPageSize = 'pageSize';
}
