import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
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

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'kpi.title'.tr,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: scheme.surface,
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined,
                color: scheme.onSurface, size: 20.sp),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.filter_list_rounded,
                color: scheme.onSurface, size: 20.sp),
            onPressed: () {},
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Period Selector (Segmented Control)
            _buildPeriodSelector(scheme, appColors),
            SizedBox(height: 16.h),

            // 2. Primary Target Banner
            _buildPrimaryTargetCard(scheme, appColors, theme),
            SizedBox(height: 20.h),

            // 3. Section Title: Performance Overview
            Text(
              'kpi.overview_heading'.tr,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 12.h),

            // 4. 2x2 Metric Grid
            _buildMetricsGrid(scheme, appColors, theme),
            SizedBox(height: 24.h),

            // 5. Product Category Progress Breakdown
            _buildCategoryBreakdown(scheme, appColors, theme),
            SizedBox(height: 24.h),

            // 6. Sales Pipeline Conversion Funnel
            _buildPipelineFunnel(scheme, appColors, theme),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Period Selector Widget
  // ---------------------------------------------------------------------------
  Widget _buildPeriodSelector(ColorScheme scheme, dynamic appColors) {
    return Container(
      height: 44.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: appColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12.r),
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
                  borderRadius: BorderRadius.circular(10.r),
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
                child: Text(
                  labelKey.tr,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? scheme.primary
                        : scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Primary Target Hero Card
  // ---------------------------------------------------------------------------
  Widget _buildPrimaryTargetCard(
      ColorScheme scheme, dynamic appColors, ThemeData theme) {
    const double target = 150000;
    const double achieved = 122400;
    final progress = (achieved / target).clamp(0.0, 1.0);
    final percentage = (progress * 100).round();

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20.r),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.stars_rounded,
                        size: 18.sp, color: scheme.primary),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'kpi.revenue_target'.tr,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: appColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: appColors.success,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\$${achieved.toInt()}',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                '/ \$${target.toInt()}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Stack(
            children: [
              Container(
                height: 10.h,
                decoration: BoxDecoration(
                  color: appColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 10.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        appColors.success.withValues(alpha: 0.8),
                        appColors.success,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. 2x2 Key Metric Grid
  // ---------------------------------------------------------------------------
  Widget _buildMetricsGrid(
      ColorScheme scheme, dynamic appColors, ThemeData theme) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      shrinkWrap: true,
      childAspectRatio: 1.35,
      physics: const NeverScrollableScrollPhysics(),
      children: [
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
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Product Category Breakdown
  // ---------------------------------------------------------------------------
  Widget _buildCategoryBreakdown(
      ColorScheme scheme, dynamic appColors, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: appColors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'kpi.category_breakdown'.tr,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          SizedBox(height: 16.h),
          _CategoryProgressRow(
            title: 'ISI Roofing & Cladding',
            amount: '\$68,400',
            progress: 0.85,
            color: scheme.primary,
          ),
          SizedBox(height: 14.h),
          _CategoryProgressRow(
            title: 'ISI Structural Steel',
            amount: '\$34,200',
            progress: 0.60,
            color: appColors.success,
          ),
          SizedBox(height: 14.h),
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

  // ---------------------------------------------------------------------------
  // 5. Sales Pipeline Conversion Funnel
  // ---------------------------------------------------------------------------
  Widget _buildPipelineFunnel(
      ColorScheme scheme, dynamic appColors, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: appColors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'kpi.pipeline_funnel'.tr,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              Text(
                '184 Leads',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
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

// =============================================================================
// Helper Widgets
// =============================================================================

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

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: appColors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon,
                  size: 18.sp, color: scheme.onSurface.withValues(alpha: 0.6)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: (isPositive ? appColors.success : scheme.error)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 10.sp,
                      color: isPositive ? appColors.success : scheme.error,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      growth,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: isPositive ? appColors.success : scheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Stack(
          children: [
            Container(
              height: 6.h,
              decoration: BoxDecoration(
                color: appColors.surfaceSoft,
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 6.h,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6.r),
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
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10.h),
      child: Row(
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              stage,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: appColors.surfaceSoft,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$count leads',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    percent,
                    style: TextStyle(
                      fontSize: 11.sp,
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
