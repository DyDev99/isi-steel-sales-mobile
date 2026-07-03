import 'package:equatable/equatable.dart';

/// A secondary contact (buyer, storekeeper, accountant) reps add themselves.
/// The primary legal contact lives on [Customer] itself and is SAP-owned.
class CustomerContact extends Equatable {
  const CustomerContact({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    this.email,
  });

  final String id;
  final String name;
  final String role;
  final String phone;
  final String? email;

  @override
  List<Object?> get props => [id, name, role, phone, email];
}
