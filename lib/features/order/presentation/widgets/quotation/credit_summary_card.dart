import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/localization/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/credit_note_debit_note.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/credit_summary.dart';

class CreditSummaryCard extends StatelessWidget {
  const CreditSummaryCard({
    super.key,
    required this.creditLimit,
    required this.summary,
  });

  final double creditLimit;
  final CreditSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final remaining = creditLimit - summary.outstandingBalance;
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'orders.shop.credit_remaining'.tr,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${remaining.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (summary.notes.isNotEmpty) ...[
            Divider(color: colors.divider, height: 20),
            Text(
              'Outstanding Notes',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            for (final note in summary.notes) _NoteRow(note: note),
          ],
        ],
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note});
  final CreditNoteDebitNote note;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    final isCredit = note.type == CreditDebitNoteType.creditNote;
    final statusColor = isCredit ? colors.success : colors.warning;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isCredit ? 'CN' : 'DN',
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${note.reference} · ${note.reason}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 11.5,
              ),
            ),
          ),
          Text(
            '\$${note.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}