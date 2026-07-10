import 'package:isi_steel_sales_mobile/features/lead/domain/entities/notification_item.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/repositories/lead_repository.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/usecases/lead_usecase.dart';

class FetchNotifications extends LeadUseCase<List<NotificationItem>, NoParams> {
  const FetchNotifications(this._repository);
  final LeadRepository _repository;

  @override
  Future<List<NotificationItem>> call(NoParams params) =>
      _repository.fetchNotifications();
}
