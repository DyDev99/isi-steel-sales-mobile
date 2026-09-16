import 'package:equatable/equatable.dart';

enum CustomerType { retail, wholesale, contractor }

class Customer extends Equatable {
  const Customer({
    this.id,
    required this.name,
    required this.phone,
    required this.type,
    required this.creditLimit,
  });

  final String? id;
  final String name;
  final String phone;
  final CustomerType type;
  final double creditLimit;

  @override
  List<Object?> get props => [id, name, phone, type, creditLimit];
}
