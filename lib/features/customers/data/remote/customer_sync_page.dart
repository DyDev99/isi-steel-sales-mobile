import 'package:isi_steel_sales_mobile/features/customers/data/models/customer_model.dart';

class CustomerInitialPage {
  const CustomerInitialPage({required this.items, required this.hasMore});
  final List<CustomerModel> items;
  final bool hasMore;
}

class CustomerDeltaPage {
  const CustomerDeltaPage({required this.upserted, required this.deletedIds});
  final List<CustomerModel> upserted;
  final List<String> deletedIds;
}
