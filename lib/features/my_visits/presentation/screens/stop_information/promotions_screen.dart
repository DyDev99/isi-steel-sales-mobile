import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isi_steel_sales_mobile/core/localization/localized_builder.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_content_frame.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

enum PromoType { onInvoice, offInvoice, contract }

class PromoItem {
  const PromoItem({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.discountLabel,
    required this.type,
    required this.validUntil,
    required this.minOrderValue,
    this.appliedCategory,
  });

  final String id;
  final String code;
  final String title;
  final String description;
  final String discountLabel;
  final PromoType type;
  final String validUntil;
  final String minOrderValue;
  final String? appliedCategory;
}

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({
    super.key,
    this.outletName,
  });

  static const String routeName = 'promotions';
  final String? outletName;

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  PromoType? _selectedTypeFilter;

  // Mock promotion dataset representing active outlet promotions
  static const List<PromoItem> _promotions = [
    PromoItem(
      id: 'P001',
      code: 'ISI-ONINV-5',
      title: '5% Instant On-Invoice Discount',
      description:
          'Get an instant 5% price reduction on all Roofing & Wave Tiles orders over \$2,000.',
      discountLabel: '5% OFF',
      type: PromoType.onInvoice,
      validUntil: '31 Aug 2026',
      minOrderValue: '\$2,000',
      appliedCategory: 'Roofing & Tiles',
    ),
    PromoItem(
      id: 'P002',
      code: 'STEEL-BOX-10',
      title: 'Square Box Pipe Rebate',
      description:
          'Receive \$10 cashback rebate per ton on galvanized square & box pipes.',
      discountLabel: '\$10/Ton',
      type: PromoType.onInvoice,
      validUntil: '15 Sep 2026',
      minOrderValue: '\$5,000',
      appliedCategory: 'Pipes & Tubing',
    ),
    PromoItem(
      id: 'P003',
      code: 'CONTRACT-Q3-ISI',
      title: 'Q3 Volume Tier Bonus',
      description:
          'Quarterly contractual incentive for Diamond tier outlets achieving >50 Tons.',
      discountLabel: '\$1,500 Rebate',
      type: PromoType.contract,
      validUntil: '30 Sep 2026',
      minOrderValue: '\$25,000',
      appliedCategory: 'All Structural Steel',
    ),
    PromoItem(
      id: 'P004',
      code: 'C-PURLIN-SPECIAL',
      title: 'C-Purlin Direct Discount',
      description:
          'Special contractor incentive on high-grade C-Purlin and Z-Purlin orders.',
      discountLabel: '3% OFF',
      type: PromoType.onInvoice,
      validUntil: '20 Sep 2026',
      minOrderValue: '\$1,500',
      appliedCategory: 'Structural Steel',
    ),
    PromoItem(
      id: 'P005',
      code: 'CONTRACT-REBAR-2026',
      title: 'Deformed Bar Annual Agreement',
      description:
          'Special agreed contractual rate for high-volume deformed steel bar purchasing.',
      discountLabel: 'Special Rate',
      type: PromoType.contract,
      validUntil: '31 Dec 2026',
      minOrderValue: '\$10,000',
      appliedCategory: 'Rebar & Mesh',
    ),
  ];

  @override
  Widget build(BuildContext context) =>
      LocalizedBuilder(builder: _buildContent);

  Widget _buildContent(BuildContext context) {
    final colors = context.appColors;

    final filteredList = _selectedTypeFilter == null
        ? _promotions
        : _promotions.where((p) => p.type == _selectedTypeFilter).toList();

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: context.rh(56),
        iconTheme: IconThemeData(
          color: colors.textPrimary,
          size: context.rr(24),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Promotions',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: context.rsp(17),
                fontWeight: FontWeight.w800,
              ),
            ),
            if (widget.outletName != null) ...[
              SizedBox(height: context.rh(2)),
              Text(
                widget.outletName!,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: context.rsp(11.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
      body: SafeArea(
        child: ResponsiveContentFrame(
          child: Column(
            children: [
              // Filter Category Chips
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.pagePadding,
                  vertical: context.rh(8),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'ALL (${_promotions.length})',
                        isSelected: _selectedTypeFilter == null,
                        onTap: () => setState(() => _selectedTypeFilter = null),
                      ),
                      SizedBox(width: context.rw(8)),
                      _FilterChip(
                        label:
                            'ON-INVOICE (${_promotions.where((p) => p.type == PromoType.onInvoice).length})',
                        isSelected: _selectedTypeFilter == PromoType.onInvoice,
                        onTap: () => setState(
                            () => _selectedTypeFilter = PromoType.onInvoice),
                      ),
                      SizedBox(width: context.rw(8)),
                      _FilterChip(
                        label:
                            'OFF-INVOICE (${_promotions.where((p) => p.type == PromoType.offInvoice).length})',
                        isSelected: _selectedTypeFilter == PromoType.offInvoice,
                        onTap: () => setState(
                            () => _selectedTypeFilter = PromoType.offInvoice),
                      ),
                      SizedBox(width: context.rw(8)),
                      _FilterChip(
                        label:
                            'CONTRACT (${_promotions.where((p) => p.type == PromoType.contract).length})',
                        isSelected: _selectedTypeFilter == PromoType.contract,
                        onTap: () => setState(
                            () => _selectedTypeFilter = PromoType.contract),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: context.rh(4)),

              // Promotion List
              Expanded(
                child: filteredList.isEmpty
                    ? Center(
                        child: Text(
                          'No promotions available for this category.',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: context.rsp(14),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          context.pagePadding,
                          context.rh(8),
                          context.pagePadding,
                          context.rh(24),
                        ),
                        itemCount: filteredList.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: context.rh(14)),
                        itemBuilder: (context, index) {
                          final promo = filteredList[index];
                          return _PromotionCard(promo: promo);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(context.rr(10)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: context.rw(14),
          vertical: context.rh(8),
        ),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary : colors.card,
          borderRadius: BorderRadius.circular(context.rr(10)),
          border: Border.all(
            color: isSelected ? scheme.primary : colors.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? scheme.onPrimary : colors.textPrimary,
            fontSize: context.rsp(11.5),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({required this.promo});

  final PromoItem promo;

  Color _badgeBgColor(PromoType type) {
    switch (type) {
      case PromoType.onInvoice:
        return Colors.blue.shade100;
      case PromoType.offInvoice:
        return Colors.grey.shade200;
      case PromoType.contract:
        return Colors.teal.shade100;
    }
  }

  Color _badgeTextColor(PromoType type) {
    switch (type) {
      case PromoType.onInvoice:
        return Colors.blue.shade900;
      case PromoType.offInvoice:
        return Colors.grey.shade800;
      case PromoType.contract:
        return Colors.teal.shade900;
    }
  }

  String _typeLabel(PromoType type) {
    switch (type) {
      case PromoType.onInvoice:
        return 'ON-INVOICE';
      case PromoType.offInvoice:
        return 'OFF-INVOICE';
      case PromoType.contract:
        return 'CONTRACT';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(context.rr(16)),
        border: Border.all(color: colors.border),
        boxShadow: colors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header with Type Badge & Discount Label
          Container(
            padding: EdgeInsets.all(context.rr(14)),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(context.rr(16)),
              ),
              border:
                  Border(bottom: BorderSide(color: colors.border, width: 0.8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.rw(10),
                    vertical: context.rh(4),
                  ),
                  decoration: BoxDecoration(
                    color: _badgeBgColor(promo.type),
                    borderRadius: BorderRadius.circular(context.rr(6)),
                  ),
                  child: Text(
                    _typeLabel(promo.type),
                    style: TextStyle(
                      color: _badgeTextColor(promo.type),
                      fontSize: context.rsp(11),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.rw(10),
                    vertical: context.rh(4),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(context.rr(6)),
                  ),
                  child: Text(
                    promo.discountLabel,
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontSize: context.rsp(12),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content Body
          Padding(
            padding: EdgeInsets.all(context.rr(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promo.title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: context.rsp(15.5),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: context.rh(6)),
                Text(
                  promo.description,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: context.rsp(13),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: context.rh(14)),

                // Promo Code Copy Box
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.rw(12),
                    vertical: context.rh(8),
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceSoft,
                    borderRadius: BorderRadius.circular(context.rr(10)),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_offer_outlined,
                            size: context.rr(18),
                            color: scheme.primary,
                          ),
                          SizedBox(width: context.rw(8)),
                          Text(
                            promo.code,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: context.rsp(13),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: promo.code));
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Promo code ${promo.code} copied!'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.all(context.rr(4)),
                          child: Row(
                            children: [
                              Text(
                                'COPY',
                                style: TextStyle(
                                  color: scheme.primary,
                                  fontSize: context.rsp(11.5),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: context.rw(4)),
                              Icon(
                                Icons.copy_rounded,
                                size: context.rr(14),
                                color: scheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.rh(14)),

                // Footer Metadata Details
                Row(
                  children: [
                    Expanded(
                      child: _MetaItem(
                        icon: Icons.calendar_today_outlined,
                        label: 'Valid Until',
                        value: promo.validUntil,
                      ),
                    ),
                    Expanded(
                      child: _MetaItem(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Min Spend',
                        value: promo.minOrderValue,
                      ),
                    ),
                    if (promo.appliedCategory != null)
                      Expanded(
                        child: _MetaItem(
                          icon: Icons.category_outlined,
                          label: 'Applies To',
                          value: promo.appliedCategory!,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: context.rr(12), color: colors.textSecondary),
            SizedBox(width: context.rw(4)),
            Text(
              label,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: context.rsp(10.5),
              ),
            ),
          ],
        ),
        SizedBox(height: context.rh(2)),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: context.rsp(12),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
