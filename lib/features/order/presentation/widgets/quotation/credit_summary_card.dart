import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/local/localization_services.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/credit_note_debit_note.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/credit_summary.dart';

/// Credit remaining + outstanding CN/DN list — shown on the Shop screen and
/// the Quotation Builder header. Credit remaining is computed by the
/// caller (`creditLimit - summary.outstandingBalance`), never stored.
class CreditSummaryCard extends StatelessWidget {
  const CreditSummaryCard({super.key, required this.creditLimit, required this.summary});

  final double creditLimit;
  final CreditSummary summary;

  @override
  Widget build(BuildContext context) {
    final remaining = creditLimit - summary.outstandingBalance;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Vibe.stroke)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('orders.shop.credit_remaining'.tr, style: const TextStyle(color: Vibe.muted, fontSize: 11.5)),
                    const SizedBox(height: 2),
                    Text('\$${remaining.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: remaining < 0 ? Vibe.danger : Vibe.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        )),
                  ],
                ),
              ),
              if (summary.notes.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration:
                      BoxDecoration(color: Vibe.amber.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
                  child: Text('${summary.notes.length} CN/DN', style: const TextStyle(color: Vibe.amber, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          if (summary.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(color: Vibe.divider, height: 1),
            const SizedBox(height: 8),
            Text('orders.shop.outstanding'.tr, style: const TextStyle(color: Vibe.muted, fontSize: 11.5)),
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
    final isCredit = note.type == CreditDebitNoteType.creditNote;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (isCredit ? Vibe.success : Vibe.danger).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(isCredit ? 'CN' : 'DN',
                style: TextStyle(color: isCredit ? Vibe.success : Vibe.danger, fontSize: 10, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${note.reference} · ${note.reason}',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Vibe.text, fontSize: 11.5)),
          ),
          Text('\$${note.amount.toStringAsFixed(2)}', style: const TextStyle(color: Vibe.muted, fontSize: 11.5)),
        ],
      ),
    );
  }
}
