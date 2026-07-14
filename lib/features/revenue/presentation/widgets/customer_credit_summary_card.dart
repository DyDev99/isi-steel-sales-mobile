import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/shared/widgets/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/mapper/revenue_view_model_mapper.dart';

class CustomerCreditSummaryCard extends StatelessWidget {
  const CustomerCreditSummaryCard({super.key, required this.viewModel});

  final CreditSummaryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final errorColor = Theme.of(context).colorScheme.error;

    final barColor = viewModel.isOverLimit
        ? errorColor // Replaced Vibe.danger
        : viewModel.usageRatio > 0.8
            ? colors.warning // Replaced Vibe.amber
            : colors.accentPurple; // Replaced Vibe.violet

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  viewModel.customerName,
                  style: TextStyle(
                      color: colors.textPrimary, // Replaced Vibe.text
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (viewModel.isOverLimit)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: errorColor.withValues(alpha: 0.12), // Replaced Vibe.danger
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    'revenue.credit.over_limit'.tr,
                    style: TextStyle(
                        color: errorColor, // Replaced Vibe.danger
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text('revenue.credit.available'.tr,
              style: TextStyle(color: colors.textSecondary, fontSize: 11.5)), // Replaced Vibe.muted
          const SizedBox(height: 2),
          Text(
            viewModel.formattedAvailableCredit,
            style: TextStyle(
              color: viewModel.isOverLimit ? errorColor : colors.textPrimary, // Replaced Vibe.danger/text
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: viewModel.usageRatio,
              minHeight: 6,
              backgroundColor: colors.divider, // Replaced Vibe.divider
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MetricLabel(
                  label: 'revenue.credit.limit'.tr,
                  value: viewModel.formattedCreditLimit),
              _MetricLabel(
                  label: 'revenue.credit.used'.tr,
                  value: viewModel.formattedUsedCredit),
              _MetricLabel(
                  label: 'revenue.credit.outstanding'.tr,
                  value: viewModel.formattedOutstandingBalance),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricLabel extends StatelessWidget {
  const _MetricLabel({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 10.5)), // Replaced Vibe.muted
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)), // Replaced Vibe.text
      ],
    );
  }
}