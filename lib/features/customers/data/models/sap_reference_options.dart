import 'package:isi_steel_sales_mobile/features/customers/data/models/bp_customer_form_data.dart';
import 'package:isi_steel_sales_mobile/features/customers/data/remote/customer_datasources.dart';

/// The catalogue names the registration form reads, as the server spells them.
///
/// These are the nine catalogues `GET references` returns. Sales employees are
/// deliberately absent: there are 5,809 of them, which would make the
/// form-open response 252 KB, so they are a search box rather than a dropdown
/// (`docs/feature/customer/registration/README.md` §3).
///
/// The remaining dropdowns (grouping, title, delivery priority, tax class,
/// currency) have no server catalogue and stay on the built-in lists — see
/// [SapReferenceOptions.forCatalogue].
abstract final class SapCatalogue {
  /// BP grouping / account group, as `GET references` spells it.
  ///
  /// Note this catalogue is the **whole** BP grouping table — 11 entries
  /// covering customers, suppliers, loans and employees. Only the customer
  /// groupings belong in this form; see
  /// [SapReferenceOptions.partnerGroup].
  static const String partnerGroup = 'PartnerGroup';

  static const String salesOrg = 'SalesOrg';
  static const String salesOffice = 'SalesOffice';
  static const String salesGroup = 'SalesGroup';
  static const String distributionChannel = 'DistributionChannel';
  static const String division = 'Division';
  static const String customerGroup = 'CustomerGroup';
  static const String priceGroup = 'PriceGroup';
  static const String paymentTerm = 'PaymentTerm';
  static const String shippingCondition = 'ShippingCondition';
}

/// Resolves a dropdown's options, preferring the ERP's own catalogue over the
/// built-in list.
///
/// ## Why the built-in lists cannot simply be deleted
///
/// They are the offline fallback. A rep opening the registration form for the
/// first time with no signal has no cached catalogues, and an empty dropdown
/// blocks the registration entirely — which is exactly the failure the whole
/// offline-first design exists to prevent.
///
/// ## Why the ERP copy must win when it exists
///
/// The built-in lists are materially shorter than the ERP's, so a rep picking
/// from them chooses codes SAP will reject on the push: **PaymentTerm 4 vs 28,
/// CustomerGroup 5 vs 8, PriceGroup 5 vs 9** at the time of writing. A
/// registration rejected for an invalid payment term is indistinguishable, from
/// the field, from one rejected for a real reason.
class SapReferenceOptions {
  const SapReferenceOptions(this._catalogue);

  /// Null until the catalogues have been loaded — every lookup then falls back.
  final CustomerReferenceCatalogue? _catalogue;

  /// No catalogues loaded; everything resolves to the built-in lists.
  static const SapReferenceOptions empty = SapReferenceOptions(null);

  DateTime? get synchronisedAt => _catalogue?.synchronisedAt;

  /// True when the options came from the ERP rather than the built-in lists.
  bool get isFromErp => !(_catalogue?.isEmpty ?? true);

  /// Options for [catalogue], falling back to [fallback] when the ERP copy is
  /// absent or empty.
  List<SapOption> forCatalogue(
    String catalogue, {
    required List<SapOption> fallback,
  }) {
    final options = _catalogue?.optionsFor(catalogue) ?? const <SapOption>[];
    return options.isEmpty ? fallback : options;
  }

  /// Grouping options for **customer** registration.
  ///
  /// The ERP catalogue is the full BP grouping table, so it also offers
  /// `ZBP1 Local Supplier`, `ZSL4 Employee`, `ZSL1 Term Loan` and five more.
  /// Those are real groupings — for other BP roles. This form creates
  /// `BpRole: ZFLCU1` (Customer) and sends the grouping as both
  /// `PartnerGroup` and `AccountGroup`, so offering them here would let a rep
  /// register a steel shop as a term loan. SAP would reject the push, and the
  /// rep would have no way to tell that from any other rejection.
  ///
  /// Filtered rather than truncated to the three known codes, so a customer
  /// grouping added in SAP appears without an app release.
  List<SapOption> get partnerGroup {
    final all = forCatalogue(
      SapCatalogue.partnerGroup,
      fallback: SapMasterData.grouping,
    );
    final customerOnly = all.where(_isCustomerGrouping).toList();
    // If the filter matches nothing the catalogue has been reorganised in a
    // way this build does not understand. Falling back to the built-in list
    // beats an empty dropdown, which blocks the registration outright.
    return customerOnly.isEmpty ? SapMasterData.grouping : customerOnly;
  }

  /// Every grouping the ERP published, unfiltered. For screens that are not
  /// customer registration.
  List<SapOption> get allPartnerGroups => forCatalogue(
        SapCatalogue.partnerGroup,
        fallback: SapMasterData.grouping,
      );

  /// A grouping usable for a customer BP.
  ///
  /// Matched on the built-in customer codes **or** the word "customer" in the
  /// ERP's own name, so `Z00n Project Customer` added later is picked up
  /// automatically. `Z003 Group Member` has no such word and is included by
  /// code — it is an intercompany customer, not a supplier.
  static bool _isCustomerGrouping(SapOption option) {
    const knownCustomerCodes = {'Z001', 'Z002', 'Z003'};
    return knownCustomerCodes.contains(option.code) ||
        option.labelEn.toLowerCase().contains('customer');
  }

  List<SapOption> get salesOrg =>
      forCatalogue(SapCatalogue.salesOrg, fallback: SapMasterData.salesOrg);

  List<SapOption> get salesOffice => forCatalogue(SapCatalogue.salesOffice,
      fallback: SapMasterData.salesOffice);

  List<SapOption> get salesGroup =>
      forCatalogue(SapCatalogue.salesGroup, fallback: SapMasterData.salesGroup);

  List<SapOption> get distributionChannel =>
      forCatalogue(SapCatalogue.distributionChannel,
          fallback: SapMasterData.distributionChannel);

  List<SapOption> get division =>
      forCatalogue(SapCatalogue.division, fallback: SapMasterData.division);

  List<SapOption> get customerGroup => forCatalogue(SapCatalogue.customerGroup,
      fallback: SapMasterData.customerGroup);

  List<SapOption> get priceGroup =>
      forCatalogue(SapCatalogue.priceGroup, fallback: SapMasterData.priceGroup);

  List<SapOption> get paymentTerm => forCatalogue(SapCatalogue.paymentTerm,
      fallback: SapMasterData.paymentTerm);

  List<SapOption> get shippingCondition =>
      forCatalogue(SapCatalogue.shippingCondition,
          fallback: SapMasterData.shippingCondition);

  /// The price group that pairs with [customerGroupCode], or null when SAP
  /// publishes none.
  ///
  /// Matched on the **name**, not by arithmetic on the code: customer group
  /// `05 Contractor` pairs with price group `51 Contractor`, and the two code
  /// sequences do not line up (`01…08` against `11, 21, 31, 41, 51, 52, 53,
  /// 61, 71`). Matching on the name means a pairing added in SAP works without
  /// an app release.
  ///
  /// Falls back to the built-in map when the catalogues are not loaded, and
  /// accepts that answer only if the code actually exists in the catalogue in
  /// hand. Returns null for `08 Exporter`, which genuinely has no counterpart —
  /// an unset price group beats an invented code the push is rejected for.
  String? priceGroupFor(String? customerGroupCode) {
    if (customerGroupCode == null) return null;

    final prices = priceGroup;
    final group =
        _firstWhereOrNull(customerGroup, (o) => o.code == customerGroupCode);

    if (group != null) {
      final wanted = group.labelEn.toLowerCase();
      final byName =
          _firstWhereOrNull(prices, (p) => p.labelEn.toLowerCase() == wanted);
      if (byName != null) return byName.code;
    }

    final mapped = SapMasterData.priceGroupByCustomerGroup[customerGroupCode];
    if (mapped == null) return null;
    return prices.any((p) => p.code == mapped) ? mapped : null;
  }
}

/// `firstWhere` with a null result instead of a throw.
///
/// A local helper rather than a dependency on `package:collection` for one
/// call — `CLAUDE.md` §26 is explicit about not adding dependencies that earn
/// nothing.
SapOption? _firstWhereOrNull(
  List<SapOption> options,
  bool Function(SapOption) test,
) {
  for (final option in options) {
    if (test(option)) return option;
  }
  return null;
}
