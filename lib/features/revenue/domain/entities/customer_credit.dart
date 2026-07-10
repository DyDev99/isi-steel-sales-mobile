import 'package:equatable/equatable.dart';

/// Customer Credit Summary shown at the top of the Revenue screen.
class CustomerCredit extends Equatable {
  const CustomerCredit({
    required this.customerId,
    required this.customerName,
    required this.creditLimit,
    required this.usedCredit,
    required this.outstandingBalance,
  });

  final String customerId;
  final String customerName;
  final double creditLimit;
  final double usedCredit;
  final double outstandingBalance;

  double get availableCredit =>
      (creditLimit - usedCredit).clamp(0, creditLimit);
  double get usageRatio =>
      creditLimit <= 0 ? 0 : (usedCredit / creditLimit).clamp(0, 1);

  @override
  List<Object?> get props =>
      [customerId, customerName, creditLimit, usedCredit, outstandingBalance];
}
