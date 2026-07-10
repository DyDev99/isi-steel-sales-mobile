import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/core/utils/glass_card.dart';
import 'package:isi_steel_sales_mobile/features/revenue/presentation/mapper/revenue_view_model_mapper.dart';

/// Customer Credit Summary — available credit, limit and outstanding
/// balance, with a usage progress bar.
class CustomerCreditSummaryCard extends StatelessWidget {
  const CustomerCreditSummaryCard({super.key, required this.viewModel});

  final CreditSummaryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final barColor = viewModel.isOverLimit
        ? Vibe.danger
        : viewModel.usageRatio > 0.8
            ? Vibe.amber
            : Vibe.violet;

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
                  style: const TextStyle(
                      color: Vibe.text,
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
                      color: Vibe.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    'revenue.credit.over_limit'.tr,
                    style: const TextStyle(
                        color: Vibe.danger,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text('revenue.credit.available'.tr,
              style: const TextStyle(color: Vibe.muted, fontSize: 11.5)),
          const SizedBox(height: 2),
          Text(
            viewModel.formattedAvailableCredit,
            style: TextStyle(
              color: viewModel.isOverLimit ? Vibe.danger : Vibe.text,
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
              backgroundColor: Vibe.divider,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Vibe.muted, fontSize: 10.5)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Vibe.text, fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
