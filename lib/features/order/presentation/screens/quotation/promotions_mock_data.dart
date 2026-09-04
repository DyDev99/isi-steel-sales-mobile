import 'package:isi_steel_sales_mobile/shared/widgets/promotions/promo_view.dart';

/// TODO(release-gate): placeholder promotion groups for the quotation builder.
///
/// Same standing as `my_visits/.../promotions_mock_data.dart`: the BRD's
/// promotion tables (§7) have no Drift schema yet, so there is nothing to read
/// from. Extracted out of the widget it used to be inlined in, both so the
/// section is reviewable as layout and so this data cannot ship unnoticed.
final DateTime _today = DateTime.now();

DateTime _inDays(int days) =>
    DateTime(_today.year, _today.month, _today.day + days);

/// One labelled group of promotions, as the quotation builder lists them.
class PromoGroup {
  const PromoGroup({
    required this.titleKey,
    required this.promos,
  });

  /// Translation key for the group heading.
  final String titleKey;
  final List<PromoView> promos;
}

final List<PromoGroup> mockQuotationPromoGroups = [
  PromoGroup(
    titleKey: 'promotions.group.depot_discount',
    promos: [
      PromoView(
        id: 'Q-DD-1',
        title: 'On-Invoice Discount — Rebar',
        summary: 'Applies to every rebar line on the invoice.',
        kind: PromoKind.onInvoice,
        value: const PromoPercent(2),
        status: PromoStatus.active,
        endsOn: _inDays(26),
        category: 'Rebar',
        depots: 'All Depots',
      ),
      PromoView(
        id: 'Q-DD-2',
        title: 'On-Invoice Discount — Roofing Profile',
        kind: PromoKind.onInvoice,
        value: const PromoPercent(1.5),
        status: PromoStatus.active,
        endsOn: _inDays(26),
        category: 'Roofing Profile',
        depots: 'All Depots',
      ),
      PromoView(
        id: 'Q-DD-3',
        title: 'On-Invoice Discount — PU Eco',
        kind: PromoKind.onInvoice,
        value: const PromoPercent(1.25),
        status: PromoStatus.active,
        endsOn: _inDays(58),
        category: 'PU Eco',
        depots: 'PP, ST Depots',
      ),
      PromoView(
        id: 'Q-DD-4',
        title: 'On-Invoice Discount — ISI 295',
        kind: PromoKind.onInvoice,
        value: const PromoPercent(3),
        status: PromoStatus.active,
        endsOn: _inDays(12),
        category: 'ISI 295',
        depots: 'All Depots',
      ),
    ],
  ),
  PromoGroup(
    titleKey: 'promotions.group.cod_pickup',
    promos: [
      PromoView(
        id: 'Q-CD-1',
        title: 'COD / Pickup Discount — All Categories',
        summary: 'Earned by paying on delivery or collecting from the depot.',
        kind: PromoKind.paymentTerm,
        requires: const {PromoRequirement.pickup},
        value: const PromoPercent(1),
        status: PromoStatus.active,
        endsOn: _inDays(26),
        category: 'All Categories',
        depots: 'All Depots',
      ),
      PromoView(
        id: 'Q-CD-2',
        title: 'COD Discount — Coil',
        kind: PromoKind.paymentTerm,
        requires: const {PromoRequirement.pickup},
        value: const PromoPercent(1.5),
        status: PromoStatus.active,
        endsOn: _inDays(5),
        category: 'Coil',
        depots: 'PP Depot',
      ),
      PromoView(
        id: 'Q-CD-3',
        title: 'Pickup Discount — Profile',
        kind: PromoKind.paymentTerm,
        requires: const {PromoRequirement.pickup},
        value: const PromoPercent(0.75),
        status: PromoStatus.active,
        endsOn: _inDays(40),
        category: 'Profile',
        depots: 'KPS Depot',
      ),
    ],
  ),
  PromoGroup(
    titleKey: 'promotions.group.depot_requests',
    promos: [
      PromoView(
        id: 'Q-RQ-1',
        title: 'Pipe Discount Request',
        summary: 'Waiting on the Regional Sales Manager.',
        kind: PromoKind.depotRequest,
        value: const PromoPercent(1.5),
        status: PromoStatus.pending,
        endsOn: _inDays(26),
        category: 'Pipe',
        depots: 'PP, ST, KPS Depots',
      ),
      PromoView(
        id: 'Q-RQ-2',
        title: 'K Pipe Discount Request',
        kind: PromoKind.depotRequest,
        value: const PromoPercent(1.5),
        status: PromoStatus.approved,
        endsOn: _inDays(26),
        category: 'K Pipe',
        depots: 'PP, ST, KPS Depots',
      ),
      PromoView(
        id: 'Q-RQ-3',
        title: 'Coil Discount Request',
        kind: PromoKind.depotRequest,
        value: const PromoPercent(1),
        status: PromoStatus.approved,
        endsOn: _inDays(26),
        category: 'Coil',
        depots: 'PP, ST, KPS Depots',
      ),
      PromoView(
        id: 'Q-RQ-4',
        title: 'Profile Discount Request',
        kind: PromoKind.depotRequest,
        value: const PromoPercent(2),
        status: PromoStatus.pending,
        endsOn: _inDays(26),
        category: 'Profile',
        depots: 'PP, ST, KPS Depots',
      ),
    ],
  ),
  PromoGroup(
    titleKey: 'promotions.group.free_goods',
    promos: [
      PromoView(
        id: 'Q-FG-1',
        title: 'Camstar Cement Promotion',
        summary: 'Free bags are added to the delivery, not the invoice total.',
        kind: PromoKind.buyXGetY,
        value: const PromoBuyGet(buy: 40, get: 3, unit: 'BAGS'),
        status: PromoStatus.active,
        endsOn: _inDays(26),
        depots: 'All Depots',
      ),
      PromoView(
        id: 'Q-FG-2',
        title: 'Camstar Cement Promotion — Bulk',
        kind: PromoKind.buyXGetY,
        value: const PromoBuyGet(buy: 100, get: 10, unit: 'BAGS'),
        status: PromoStatus.active,
        endsOn: _inDays(26),
        depots: 'All Depots',
      ),
    ],
  ),
];
