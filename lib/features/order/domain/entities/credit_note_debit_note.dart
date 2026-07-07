import 'package:equatable/equatable.dart';

enum CreditDebitNoteType { creditNote, debitNote }

/// A mocked SAP credit/debit note against a customer's account — shown as
/// informational context during shop selection and order entry, never
/// editable from the app.
class CreditNoteDebitNote extends Equatable {
  const CreditNoteDebitNote({
    required this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    required this.reference,
    required this.reason,
    required this.issuedDate,
    required this.settled,
  });

  final String id;
  final String customerId;
  final CreditDebitNoteType type;
  final double amount;
  final String reference;
  final String reason;
  final DateTime issuedDate;
  final bool settled;

  @override
  List<Object?> get props => [id, customerId, type, amount, reference, reason, issuedDate, settled];
}
