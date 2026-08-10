import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_content_frame.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

enum KpiPeriod { monthly, quarterly, yearly }

class KpiScreen extends StatefulWidget {
  const KpiScreen({super.key});

  @override
  State<KpiScreen> createState() => _KpiScreenState();
}

class _KpiScreenState extends State<KpiScreen> {
  KpiPeriod _selectedPeriod = KpiPeriod.monthly;

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
              Icons.share_outlined,
              color: scheme.onSurface,
              size: context.rr(20),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              color: scheme.onSurface,
              size: context.rr(20),
            ),
            onPressed: () {},
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
              // 1. Period Selector (Segmented Control)
              _buildPeriodSelector(scheme, appColors),
              SizedBox(height: context.rh(16)),

              // 2. Primary Target Banner
              _buildPrimaryTargetCard(scheme, appColors, theme),
              SizedBox(height: context.rh(20)),

              // 3. Section Title: Performance Overview
              Text(
                'kpi.overview_heading'.tr,
                style: TextStyle(
                  fontSize: context.rsp(16),
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: context.rh(12)),

              // 4. Metric grid — column count is derived from available
              // width, not the device class, so it also does the right
              // thing in a split-view pane or a resized desktop window
              // (FS-RSP-1, FS-NXT-8).
              _buildMetricsGrid(scheme, appColors, theme),
              SizedBox(height: context.rh(24)),

              // 5. Product Category & Pipeline (stacked on phone, side-by-side on tablet)
              if (isCompact) ...[
                _buildCategoryBreakdown(scheme, appColors, theme),
                SizedBox(height: context.rh(24)),
                _buildPipelineFunnel(scheme, appColors, theme),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child:
                          _buildCategoryBreakdown(scheme, appColors, theme),
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

  Widget _buildPeriodSelector(ColorScheme scheme, dynamic appColors) {
    return ConstrainedBox(
      // Min height keeps the 48dp touch target (FS-UX-3); the selector is
      // allowed to grow taller than that if a locale (e.g. Khmer) needs a
      // second line — it must never clip text (FS-VIS-3, FS-LOC-4).
      constraints: BoxConstraints(minHeight: context.rh(48)),
      child: Container(
        padding: EdgeInsets.all(context.rw(4)),
        decoration: BoxDecoration(
          color: appColors.surfaceSoft,
          borderRadius: BorderRadius.circular(context.rr(12)),
        ),
        child: Row(
          children: KpiPeriod.values.map((period) {
          final isSelected = _selectedPeriod == period;
          String labelKey;
          switch (period) {
            case KpiPeriod.monthly:
              labelKey = 'kpi.period_monthly';
              break;
            case KpiPeriod.quarterly:
              labelKey = 'kpi.period_quarterly';
              break;
            case KpiPeriod.yearly:
              labelKey = 'kpi.period_yearly';
              break;
          }

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? scheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(context.rr(10)),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: context.rh(4),
                    horizontal: context.rw(4),
                  ),
                  child: Text(
                    labelKey.tr,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    softWrap: true,
                    style: TextStyle(
                      fontSize: context.rsp(13),
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? scheme.primary
                          : scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
          );
          }).toList(),
        ),
      ),
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

  Widget _buildMetricsGrid(
      ColorScheme scheme, dynamic appColors, ThemeData theme) {
    final tiles = [
      _MetricTile(
        title: 'kpi.total_orders'.tr,
        value: '142',
        growth: '+12.4%',
        isPositive: true,
        icon: Icons.shopping_bag_outlined,
      ),
      _MetricTile(
        title: 'kpi.conversion_rate'.tr,
        value: '34.8%',
        growth: '+3.1%',
        isPositive: true,
        icon: Icons.pie_chart_outline_rounded,
      ),
      _MetricTile(
        title: 'kpi.avg_order_value'.tr,
        value: '\$862',
        growth: '-1.8%',
        isPositive: false,
        icon: Icons.payments_outlined,
      ),
      _MetricTile(
        title: 'kpi.active_clients'.tr,
        value: '28',
        growth: '+5.0%',
        isPositive: true,
        icon: Icons.people_outline_rounded,
      ),
    ];

    final spacing = context.rw(12);
    // Target tile width, not a target column count — columns fall out of
    // available width (FS-RSP-1, FS-RSP-4). A hardcoded crossAxisCount here
    // would either cram 4 tight columns into a 600pt split-view pane or
    // leave 4 tiles floating in a sea of whitespace on a 1440pt window
    // (FS-RSP-7), and a fixed childAspectRatio clips text the moment any
    // locale or value string runs long (FS-VIS-3's fit-not-ratio rule).
    final targetTileWidth = context.rw(168);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            (constraints.maxWidth / (targetTileWidth + spacing))
                .floor()
                .clamp(2, 6);
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: context.rh(12),
          children: [
            for (final tile in tiles)
              SizedBox(width: tileWidth, child: tile),
          ],
        );
      },
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

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.value,
    required this.growth,
    required this.isPositive,
    required this.icon,
  });

  final String title;
  final String value;
  final String growth;
  final bool isPositive;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final appColors = context.appColors;

    // Compact keeps a tight single-line title (space is scarce on a 390pt
    // phone); medium/expanded get a second line instead of an ellipsis, per
    // the fit-not-ratio guard in FS-VIS-3 — the card grows to fit the text,
    // the text is never shrunk or cut to fit the card.
    final titleMaxLines = context.responsive(
      compact: 1,
      medium: 2,
      expanded: 2,
    );

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
                            color: isPositive
                                ? appColors.success
                                : scheme.error,
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
          SizedBox(height: context.rh(2)),
          Text(
            title,
            maxLines: titleMaxLines,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.rsp(11),
              color: scheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
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
          // A fixed pixel width clips the moment a stage name runs longer
          // in English or (routinely) in Khmer (FS-LOC-4). A flex share of
          // the row scales with the tablet width and still lets the label
          // wrap to a second line rather than clip (FS-VIS-3).
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