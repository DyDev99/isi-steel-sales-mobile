import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/order/domain/entities/credit_note_debit_note.dart';

/// Mocked SAP credit position for one customer. `creditRemaining` is
/// deliberately not stored here — callers compute it as
/// `customer.creditLimit - outstandingBalance`, since `creditLimit` already
/// lives on `Customer` and shouldn't be duplicated.
class CreditSummary extends Equatable {
  const CreditSummary({required this.outstandingBalance, required this.notes});

  final double outstandingBalance;
  final List<CreditNoteDebitNote> notes;

  bool get hasOpenNotes => notes.any((n) => !n.settled);

  @override
  List<Object?> get props => [outstandingBalance, notes];
}
