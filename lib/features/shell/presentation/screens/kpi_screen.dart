import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_content_frame.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

class KpiScreen extends StatefulWidget {
  const KpiScreen({super.key});

  @override
  State<KpiScreen> createState() => _KpiScreenState();
}

class _KpiScreenState extends State<KpiScreen> {
  // Multi-select state for Month and Year filters
  List<String> _selectedMonths = ['August'];
  List<String> _selectedYears = ['2026'];

  final List<String> _allMonths = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  final List<String> _allYears = ['2024', '2025', '2026'];

  void _openMultiSelectSheet({
    required String title,
    required List<String> options,
    required List<String> selectedValues,
    required ValueChanged<List<String>> onConfirm,
  }) {
    List<String> tempSelected = List.from(selectedValues);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.rr(20)),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final scheme = Theme.of(context).colorScheme;
            return Container(
              padding: EdgeInsets.all(context.rw(16)),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select $title',
                        style: TextStyle(
                          fontSize: context.rsp(16),
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          onConfirm(tempSelected);
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Done',
                          style: TextStyle(
                            fontSize: context.rsp(14),
                            fontWeight: FontWeight.w700,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final item = options[index];
                        final isChecked = tempSelected.contains(item);
                        return CheckboxListTile(
                          title: Text(
                            item,
                            style: TextStyle(
                              fontSize: context.rsp(14),
                              fontWeight:
                                  isChecked ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                          value: isChecked,
                          activeColor: scheme.primary,
                          onChanged: (bool? checked) {
                            setModalState(() {
                              if (checked == true) {
                                tempSelected.add(item);
                              } else {
                                if (tempSelected.length > 1) {
                                  tempSelected.remove(item);
                                }
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final appColors = context.appColors;
    final isCompact = context.responsive(
      compact: true,
      medium: false,
      expanded: false,
    );

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'kpi.title'.tr,
          style: TextStyle(
            fontSize: context.rsp(18),
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: scheme.surface,
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              color: scheme.onSurface,
              size: context.rr(20),
            ),
            onPressed: () {
              _openMultiSelectSheet(
                title: 'Month',
                options: _allMonths,
                selectedValues: _selectedMonths,
                onConfirm: (val) => setState(() => _selectedMonths = val),
              );
            },
          ),
          SizedBox(width: context.rw(8)),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(context.pagePadding),
        child: ResponsiveContentFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Month & Year Filter Dropdown Bar
              _buildFilterDropdownBar(scheme, appColors),
              SizedBox(height: context.rh(16)),

              // 2. Primary Target Banner
              _buildPrimaryTargetCard(scheme, appColors, theme),
              SizedBox(height: context.rh(16)),

              // 3. KPI Incentive Cards Section
              _buildKpiIncentivesSection(scheme, appColors, theme),
              SizedBox(height: context.rh(20)),

              // 4. Section Title: Sales Performance Overview
              Text(
                'Sales Performance Overview',
                style: TextStyle(
                  fontSize: context.rsp(16),
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: context.rh(12)),

              // 5. Sales Performance Metrics Grid (2 columns top, full width bottom)
              _buildMetricsGrid(scheme, appColors, theme),
              SizedBox(height: context.rh(24)),

              // 6. Product Category & Pipeline
              if (isCompact) ...[
                _buildCategoryBreakdown(scheme, appColors, theme),
                SizedBox(height: context.rh(24)),
                _buildPipelineFunnel(scheme, appColors, theme),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildCategoryBreakdown(scheme, appColors, theme),
                    ),
                    SizedBox(width: context.rw(16)),
                    Expanded(
                      child: _buildPipelineFunnel(scheme, appColors, theme),
                    ),
                  ],
                ),
              ],
              SizedBox(height: context.rh(24)),
            ],
          ),
        ),
      ),
    );
  }

  /// Multi-select Month and Year Filter Bar
  Widget _buildFilterDropdownBar(ColorScheme scheme, dynamic appColors) {
    final monthLabel = _selectedMonths.length == 1
        ? _selectedMonths.first
        : '${_selectedMonths.length} Months';
    final yearLabel = _selectedYears.length == 1
        ? _selectedYears.first
        : '${_selectedYears.length} Years';

    return Row(
      children: [
        Expanded(
          child: _FilterChipButton(
            label: 'Month',
            value: monthLabel,
            icon: Icons.calendar_month_outlined,
            onTap: () {
              _openMultiSelectSheet(
                title: 'Month',
                options: _allMonths,
                selectedValues: _selectedMonths,
                onConfirm: (val) => setState(() => _selectedMonths = val),
              );
            },
          ),
        ),
        SizedBox(width: context.rw(12)),
        Expanded(
          child: _FilterChipButton(
            label: 'Year',
            value: yearLabel,
            icon: Icons.date_range_outlined,
            onTap: () {
              _openMultiSelectSheet(
                title: 'Year',
                options: _allYears,
                selectedValues: _selectedYears,
                onConfirm: (val) => setState(() => _selectedYears = val),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryTargetCard(
      ColorScheme scheme, dynamic appColors, ThemeData theme) {
    const double target = 150000;
    const double achieved = 122400;
    final progress = (achieved / target).clamp(0.0, 1.0);
    final percentage = (progress * 100).round();

    return Container(
      padding: EdgeInsets.all(context.rw(18)),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(context.rr(20)),
        border: Border.all(color: appColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.25 : 0.04,
            ),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(context.rw(8)),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(context.rr(10)),
                      ),
                      child: Icon(
                        Icons.stars_rounded,
                        size: context.rr(18),
                        color: scheme.primary,
                      ),
                    ),
                    SizedBox(width: context.rw(10)),
                    Flexible(
                      child: Text(
                        'kpi.revenue_target'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.rsp(14),
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.rw(8)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.rw(10),
                  vertical: context.rh(4),
                ),
                decoration: BoxDecoration(
                  color: appColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(context.rr(20)),
                ),
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: context.rsp(12),
                    fontWeight: FontWeight.w800,
                    color: appColors.success,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.rh(16)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  '\$${achieved.toInt()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.rsp(24),
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              SizedBox(width: context.rw(6)),
              Flexible(
                child: Text(
                  '/ \$${target.toInt()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.rsp(14),
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.rh(12)),
          Stack(
            children: [
              Container(
                height: context.rh(10),
                decoration: BoxDecoration(
                  color: appColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(context.rr(10)),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: context.rh(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        appColors.success.withValues(alpha: 0.8),
                        appColors.success,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(context.rr(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Incentive cards for Payment Collection, Product Mix, Call Compliance
  Widget _buildKpiIncentivesSection(
      ColorScheme scheme, dynamic appColors, ThemeData theme) {
    return Column(
      children: [
        _IncentiveCard(
          title: 'Payment Collection',
          achievedText: '\$45,000',
          targetText: '/ \$50,000',
          percentage: 90,
          progress: 0.90,
          icon: Icons.payments_outlined,
        ),
        SizedBox(height: context.rh(12)),
        _IncentiveCard(
          title: 'Product Mix',
          achievedText: '7 Categories',
          targetText: '/ 10 Target',
          percentage: 70,
          progress: 0.70,
          icon: Icons.category_outlined,
        ),
        SizedBox(height: context.rh(12)),
        _IncentiveCard(
          title: 'Call Compliance',
          subtitle: 'Visited / (Target - Skipped)',
          achievedText: '0% COMPLIANCE',
          targetText: 'Target 0',
          percentage: 0,
          progress: 0.0,
          icon: Icons.phone_callback_outlined,
          isCallCompliance: true,
        ),
      ],
    );
  }

  /// Grid containing the 4 standard tiles in 2 columns + full-width Order Breakdown card
  Widget _buildMetricsGrid(
      ColorScheme scheme, dynamic appColors, ThemeData theme) {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(
              child: _MetricTile(
                title: '# of Active Outlets',
                subtitle: 'PO within 3 months',
                value: '124',
                growth: '+8.2%',
                isPositive: true,
                icon: Icons.store_outlined,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                title: '# of Inactive Outlets',
                value: '18',
                growth: '-2.1%',
                isPositive: true,
                icon: Icons.storefront_outlined,
              ),
            ),
          ],
        ),
        SizedBox(height: context.rh(12)),
        Row(
          children: const [
            Expanded(
              child: _MetricTile(
                title: '# of ASO',
                value: '12',
                growth: '0.0%',
                isPositive: true,
                icon: Icons.badge_outlined,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                title: 'Conversion Rate',
                subtitle: 'Strike Rate',
                value: '34.8%',
                growth: '+3.1%',
                isPositive: true,
                icon: Icons.pie_chart_outline_rounded,
              ),
            ),
          ],
        ),
        SizedBox(height: context.rh(12)),
        // In-visit vs Ad-hoc Orders Detailed Card
        const _InVisitVsAdHocCard(
          totalOrders: 74,
          inVisitCount: 9,
          inVisitPercentage: 12,
          adHocCount: 65,
          adHocPercentage: 88,
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(
      ColorScheme scheme, dynamic appColors, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(context.rw(16)),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(context.rr(20)),
        border: Border.all(color: appColors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'kpi.category_breakdown'.tr,
            style: TextStyle(
              fontSize: context.rsp(15),
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          SizedBox(height: context.rh(16)),
          _CategoryProgressRow(
            title: 'ISI Roofing & Cladding',
            amount: '\$68,400',
            progress: 0.85,
            color: scheme.primary,
          ),
          SizedBox(height: context.rh(14)),
          _CategoryProgressRow(
            title: 'ISI Structural Steel',
            amount: '\$34,200',
            progress: 0.60,
            color: appColors.success,
          ),
          SizedBox(height: context.rh(14)),
          _CategoryProgressRow(
            title: 'ISI Decking & Pipes',
            amount: '\$19,800',
            progress: 0.45,
            color: Colors.amber.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineFunnel(
      ColorScheme scheme, dynamic appColors, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(context.rw(16)),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(context.rr(20)),
        border: Border.all(color: appColors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'kpi.pipeline_funnel'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.rsp(15),
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              SizedBox(width: context.rw(8)),
              Text(
                '184 Leads',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.rsp(12),
                  color: scheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: context.rh(16)),
          _PipelineStepRow(
              stage: 'kpi.stage_leads'.tr, count: '184', percent: '100%'),
          _PipelineStepRow(
              stage: 'kpi.stage_contacted'.tr, count: '112', percent: '60%'),
          _PipelineStepRow(
              stage: 'kpi.stage_quotation'.tr, count: '64', percent: '34%'),
          _PipelineStepRow(
              stage: 'kpi.stage_won'.tr,
              count: '42',
              percent: '22%',
              isLast: true),
        ],
      ),
    );
  }
}

/// New Component matching the exact design from the reference image
class _InVisitVsAdHocCard extends StatelessWidget {
  const _InVisitVsAdHocCard({
    required this.totalOrders,
    required this.inVisitCount,
    required this.inVisitPercentage,
    required this.adHocCount,
    required this.adHocPercentage,
  });

  final int totalOrders;
  final int inVisitCount;
  final int inVisitPercentage;
  final int adHocCount;
  final int adHocPercentage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Container(
      padding: EdgeInsets.all(context.rw(16)),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(context.rr(16)),
        border: Border.all(color: appColors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'In-visit vs Ad-hoc Orders',
            style: TextStyle(
              fontSize: context.rsp(14),
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          SizedBox(height: context.rh(8)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$totalOrders',
                style: TextStyle(
                  fontSize: context.rsp(20),
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface,
                ),
              ),
              SizedBox(width: context.rw(6)),
              Text(
                'TOTAL ORDERS',
                style: TextStyle(
                  fontSize: context.rsp(11),
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.45),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: context.rh(12)),
          // Segmented Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(context.rr(6)),
            child: SizedBox(
              height: context.rh(8),
              child: Row(
                children: [
                  Expanded(
                    flex: inVisitPercentage,
                    child: Container(color: Colors.green.shade600),
                  ),
                  SizedBox(width: context.rw(4)),
                  Expanded(
                    flex: adHocPercentage,
                    child: Container(color: const Color(0xFF5B4EFF)),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: context.rh(14)),
          // Sub-metrics Box
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.rw(12),
              vertical: context.rh(10),
            ),
            decoration: BoxDecoration(
              color: appColors.surfaceSoft,
              borderRadius: BorderRadius.circular(context.rr(12)),
            ),
            child: Row(
              children: [
                // In-visit Column
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(context.rw(6)),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: context.rr(14),
                          color: Colors.green.shade700,
                        ),
                      ),
                      SizedBox(width: context.rw(8)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '$inVisitCount',
                                style: TextStyle(
                                  fontSize: context.rsp(14),
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onSurface,
                                ),
                              ),
                              SizedBox(width: context.rw(4)),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.rw(6),
                                  vertical: context.rh(2),
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      scheme.onSurface.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(
                                    context.rr(10),
                                  ),
                                ),
                                child: Text(
                                  '$inVisitPercentage%',
                                  style: TextStyle(
                                    fontSize: context.rsp(10),
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'In-visit',
                            style: TextStyle(
                              fontSize: context.rsp(11),
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  height: context.rh(28),
                  width: 1,
                  color: scheme.onSurface.withValues(alpha: 0.12),
                ),
                SizedBox(width: context.rw(12)),
                // Ad-hoc Column
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(context.rw(6)),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.exit_to_app_rounded,
                          size: context.rr(14),
                          color: const Color(0xFF5B4EFF),
                        ),
                      ),
                      SizedBox(width: context.rw(8)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '$adHocCount',
                                style: TextStyle(
                                  fontSize: context.rsp(14),
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onSurface,
                                ),
                              ),
                              SizedBox(width: context.rw(4)),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.rw(6),
                                  vertical: context.rh(2),
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      scheme.onSurface.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(
                                    context.rr(10),
                                  ),
                                ),
                                child: Text(
                                  '$adHocPercentage%',
                                  style: TextStyle(
                                    fontSize: context.rsp(10),
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Ad-hoc',
                            style: TextStyle(
                              fontSize: context.rsp(11),
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter chip button widget
class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.rr(12)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.rw(12),
          vertical: context.rh(10),
        ),
        decoration: BoxDecoration(
          color: appColors.surfaceSoft,
          borderRadius: BorderRadius.circular(context.rr(12)),
          border: Border.all(color: appColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: context.rr(16), color: scheme.primary),
                SizedBox(width: context.rw(8)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: context.rsp(13),
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: context.rr(18),
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

/// Incentive Card for Payment Collection, Product Mix, Call Compliance
class _IncentiveCard extends StatelessWidget {
  const _IncentiveCard({
    required this.title,
    this.subtitle,
    required this.achievedText,
    required this.targetText,
    required this.percentage,
    required this.progress,
    required this.icon,
    this.isCallCompliance = false,
  });

  final String title;
  final String? subtitle;
  final String achievedText;
  final String targetText;
  final int percentage;
  final double progress;
  final IconData icon;
  final bool isCallCompliance;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Container(
      padding: EdgeInsets.all(context.rw(14)),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(context.rr(16)),
        border: Border.all(color: appColors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: context.rr(18),
                      color: scheme.primary,
                    ),
                    SizedBox(width: context.rw(8)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: context.rsp(13),
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: TextStyle(
                                fontSize: context.rsp(10),
                                fontWeight: FontWeight.w500,
                                color: scheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isCallCompliance)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.rw(8),
                    vertical: context.rh(2),
                  ),
                  decoration: BoxDecoration(
                    color: appColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(context.rr(12)),
                  ),
                  child: Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: context.rsp(11),
                      fontWeight: FontWeight.w800,
                      color: appColors.success,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: context.rh(10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                achievedText,
                style: TextStyle(
                  fontSize:
                      isCallCompliance ? context.rsp(11) : context.rsp(16),
                  fontWeight: FontWeight.w800,
                  color: isCallCompliance
                      ? scheme.onSurface.withValues(alpha: 0.5)
                      : scheme.onSurface,
                ),
              ),
              Text(
                targetText,
                style: TextStyle(
                  fontSize: context.rsp(12),
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          SizedBox(height: context.rh(8)),
          Stack(
            children: [
              Container(
                height: context.rh(8),
                decoration: BoxDecoration(
                  color: appColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(context.rr(8)),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: context.rh(8),
                  decoration: BoxDecoration(
                    color: appColors.success,
                    borderRadius: BorderRadius.circular(context.rr(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    this.subtitle,
    required this.value,
    required this.growth,
    required this.isPositive,
    required this.icon,
  });

  final String title;
  final String? subtitle;
  final String value;
  final String growth;
  final bool isPositive;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final appColors = context.appColors;

    return Container(
      padding: EdgeInsets.all(context.rw(12)),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(context.rr(16)),
        border: Border.all(color: appColors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                size: context.rr(18),
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.rw(6),
                    vertical: context.rh(2),
                  ),
                  decoration: BoxDecoration(
                    color: (isPositive ? appColors.success : scheme.error)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(context.rr(12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: context.rr(10),
                        color: isPositive ? appColors.success : scheme.error,
                      ),
                      SizedBox(width: context.rw(2)),
                      Flexible(
                        child: Text(
                          growth,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.rsp(10),
                            fontWeight: FontWeight.w700,
                            color:
                                isPositive ? appColors.success : scheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.rh(10)),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.rsp(18),
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: context.rh(4)),
          Text(
            title,
            maxLines: 2,
            softWrap: true,
            style: TextStyle(
              fontSize: context.rsp(11),
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              maxLines: 2,
              softWrap: true,
              style: TextStyle(
                fontSize: context.rsp(9.5),
                color: scheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryProgressRow extends StatelessWidget {
  const _CategoryProgressRow({
    required this.title,
    required this.amount,
    required this.progress,
    required this.color,
  });

  final String title;
  final String amount;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.rsp(13),
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ),
            SizedBox(width: context.rw(8)),
            Text(
              amount,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: context.rsp(13),
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: context.rh(6)),
        Stack(
          children: [
            Container(
              height: context.rh(6),
              decoration: BoxDecoration(
                color: appColors.surfaceSoft,
                borderRadius: BorderRadius.circular(context.rr(6)),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: context.rh(6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(context.rr(6)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PipelineStepRow extends StatelessWidget {
  const _PipelineStepRow({
    required this.stage,
    required this.count,
    required this.percent,
    this.isLast = false,
  });

  final String stage;
  final String count;
  final String percent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : context.rh(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              stage,
              maxLines: 2,
              softWrap: true,
              style: TextStyle(
                fontSize: context.rsp(12),
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          SizedBox(width: context.rw(10)),
          Expanded(
            flex: 3,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.rw(10),
                vertical: context.rh(6),
              ),
              decoration: BoxDecoration(
                color: appColors.surfaceSoft,
                borderRadius: BorderRadius.circular(context.rr(8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$count leads',
                    style: TextStyle(
                      fontSize: context.rsp(11),
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    percent,
                    style: TextStyle(
                      fontSize: context.rsp(11),
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
