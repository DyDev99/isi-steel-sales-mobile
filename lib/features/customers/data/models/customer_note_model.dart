import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/customers/domain/entities/customer_note.dart';

class CustomerNoteModel extends CustomerNote {
  const CustomerNoteModel({
    required super.id,
    required super.customerId,
    required super.body,
    required super.createdAt,
    super.synced,
  });

  factory CustomerNoteModel.fromRow(DataMap row) => CustomerNoteModel(
        id: row['id'] as String,
        customerId: row['customer_id'] as String,
        body: row['body'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
        synced: (row['synced'] as int? ?? 0) == 1,
      );

  DataMap toRow() => {
        'id': id,
        'customer_id': customerId,
        'body': body,
        'created_at': createdAt.toIso8601String(),
        'synced': synced ? 1 : 0,
      };
}
