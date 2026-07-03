import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_activity.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_activity_type.dart';

class CustomerActivityModel extends CustomerActivity {
  const CustomerActivityModel({
    required super.id,
    required super.customerId,
    required super.type,
    required super.summary,
    required super.createdAt,
    super.synced,
  });

  factory CustomerActivityModel.fromRow(DataMap row) => CustomerActivityModel(
        id: row['id'] as String,
        customerId: row['customer_id'] as String,
        type: CustomerActivityType.fromValue(row['type'] as String),
        summary: row['summary'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
        synced: (row['synced'] as int? ?? 0) == 1,
      );

  DataMap toRow() => {
        'id': id,
        'customer_id': customerId,
        'type': type.value,
        'summary': summary,
        'created_at': createdAt.toIso8601String(),
        'synced': synced ? 1 : 0,
      };
}
