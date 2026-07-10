import 'package:isi_steel_sales_mobile/features/my_visits/data/models/customer_stop_info_model.dart';
import 'package:isi_steel_sales_mobile/features/my_visits/data/models/route_plan_model.dart';

class RouteSyncPage {
  const RouteSyncPage(
      {required this.customers, required this.routes, required this.hasMore});
  final List<CustomerStopInfoModel> customers;
  final List<RoutePlanModel> routes;
  final bool hasMore;
}
