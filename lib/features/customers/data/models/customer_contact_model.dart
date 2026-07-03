import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_contact.dart';

class CustomerContactModel extends CustomerContact {
  const CustomerContactModel({
    required super.id,
    required super.name,
    required super.role,
    required super.phone,
    super.email,
  });

  factory CustomerContactModel.fromRow(DataMap row) => CustomerContactModel(
        id: row['id'] as String,
        name: row['name'] as String,
        role: row['role'] as String,
        phone: row['phone'] as String,
        email: row['email'] as String?,
      );

  DataMap toRow(String customerId) => {
        'id': id,
        'customer_id': customerId,
        'name': name,
        'role': role,
        'phone': phone,
        'email': email,
      };
}
