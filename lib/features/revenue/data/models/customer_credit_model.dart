import 'package:isi_steel_sales_mobile/core/utils/typedefs.dart';
import 'package:isi_steel_sales_mobile/features/revenue/domain/entities/customer_credit.dart';

class CustomerCreditModel extends CustomerCredit {
  const CustomerCreditModel({
    required super.customerId,
    required super.customerName,
    required super.creditLimit,
    required super.usedCredit,
    required super.outstandingBalance,
  });

  factory CustomerCreditModel.fromJson(DataMap json) => CustomerCreditModel(
        customerId: json['customerId'] as String,
        customerName: json['customerName'] as String,
        creditLimit: (json['creditLimit'] as num).toDouble(),
        usedCredit: (json['usedCredit'] as num).toDouble(),
        outstandingBalance: (json['outstandingBalance'] as num).toDouble(),
      );
}
