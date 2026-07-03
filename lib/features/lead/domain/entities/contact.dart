import 'package:equatable/equatable.dart';

class Contact extends Equatable {
  const Contact({
    required this.name,
    required this.role,
    required this.phone,
    this.email,
    this.isPrimary = false,
  });

  final String name;
  final String role;
  final String phone;
  final String? email;
  final bool isPrimary;

  @override
  List<Object?> get props => [name, role, phone, email, isPrimary];
}
