import 'package:equatable/equatable.dart';

/// The five evidence slots a customer registration can carry.
///
/// **Application data, not SAP master data.** SAP owns the customer record;
/// this platform owns the photographs, keyed to the customer. Nothing here is
/// pushed to the ERP and SAP supplies no images of its own
/// (`docs/feature/customer/mobile/customer-documents.md`).
///
/// One live document per slot: uploading a slot again replaces the previous
/// one, deletes its file and issues a new public token.
enum CustomerDocumentType {
  storefront('STOREFRONT'),
  insideStore('INSIDE_STORE'),
  idCard('ID_CARD'),
  patentTax('PATENT_TAX'),
  vatCertificate('VAT_CERTIFICATE');

  const CustomerDocumentType(this.code);

  /// The wire value. **Codes, not display strings** — the API never accepts
  /// `"Storefront photo"`. The label comes back from the server as
  /// `typeDisplay`, already localised.
  final String code;

  /// Always required, regardless of anything else on the form.
  ///
  /// [vatCertificate] is deliberately absent: it is required only when the
  /// customer's tax class is VAT, which is a form-state question rather than a
  /// property of the slot — see [isRequiredFor].
  bool get isAlwaysRequired =>
      this == storefront || this == insideStore || this == idCard;

  /// Whether this slot must be filled for a customer whose tax class is
  /// [isVatRegistered].
  bool isRequiredFor({required bool isVatRegistered}) =>
      isAlwaysRequired || (this == vatCertificate && isVatRegistered);

  /// PDF is accepted only by the two document slots. Sending one to a photo
  /// slot is `Customer.DocumentExtensionNotAllowed` (400).
  bool get acceptsPdf => this == patentTax || this == vatCertificate;

  /// Whether the server will mint an unauthenticated `publicUrl` for this slot.
  ///
  /// False for [idCard], [patentTax] and [vatCertificate]: they carry personal
  /// and financial data, and a URL needing no credentials is a breach waiting
  /// for the link to leak. The server decides this from the slot — no
  /// parameter overrides it, and the public route answers 404 for them.
  bool get isPubliclyVisible => this == storefront || this == insideStore;

  /// Parses a server code, tolerating the legacy enumeration names still
  /// accepted on input (`StorefrontPhoto`, `IdCardPhoto`, …).
  ///
  /// Returns null rather than throwing on an unfamiliar value: a server that
  /// gains a sixth slot must not crash an app that has not shipped yet.
  static CustomerDocumentType? fromCode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final normalised = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    for (final type in values) {
      if (type.code.replaceAll('_', '') == normalised) return type;
    }
    return switch (normalised) {
      'STOREFRONTPHOTO' => storefront,
      'INSIDESTOREPHOTO' => insideStore,
      'IDCARDPHOTO' => idCard,
      'PATENTTAXDOCUMENT' => patentTax,
      'VATCERTIFICATE' => vatCertificate,
      _ => null,
    };
  }
}

/// One stored evidence file.
class CustomerDocument extends Equatable {
  const CustomerDocument({
    required this.id,
    required this.type,
    required this.fileName,
    this.typeDisplay,
    this.contentType,
    this.sizeBytes,
    this.url,
    this.publicUrl,
    this.isPubliclyVisible = false,
    this.capturedAt,
    this.uploadedAt,
  });

  final String id;
  final CustomerDocumentType type;

  /// Server-localised label. Rendered as-is; the screen's text comes from the
  /// server so a new slot needs no client release to read correctly.
  final String? typeDisplay;

  final String fileName;
  final String? contentType;
  final int? sizeBytes;

  /// In-app URL. Needs the bearer token and `customers.read`. Always present.
  final String? url;

  /// Unauthenticated URL, or null for a slot the server does not publish.
  ///
  /// **Never surface this for an ID card** — it is null there by design, and
  /// UI that offers to share without checking [isPubliclyVisible] first will
  /// hand out a broken link at best.
  final String? publicUrl;

  final bool isPubliclyVisible;

  /// When the photograph was taken, not when it reached the server. A queued
  /// upload can arrive hours after the visit.
  final DateTime? capturedAt;
  final DateTime? uploadedAt;

  @override
  List<Object?> get props => [id, type, fileName, url, publicUrl];
}

/// What the server holds for one customer, and what is still missing.
///
/// **Drive the UI from this, not from app state.** It survives an app restart,
/// a device swap and a partially failed upload.
class CustomerDocumentsState extends Equatable {
  const CustomerDocumentsState({
    this.byType = const {},
    this.missingRequired = const {},
    this.isComplete = false,
  });

  /// At most one live document per slot.
  final Map<CustomerDocumentType, CustomerDocument> byType;

  /// Required slots with nothing in them, as the server sees it.
  final Set<CustomerDocumentType> missingRequired;

  /// True when [missingRequired] is empty. **This is what a Send button should
  /// read** — never a locally-counted tally.
  final bool isComplete;

  /// Nothing uploaded yet — the state before the customer exists.
  static const CustomerDocumentsState empty = CustomerDocumentsState();

  CustomerDocument? operator [](CustomerDocumentType type) => byType[type];

  @override
  List<Object?> get props => [byType, missingRequired, isComplete];
}
