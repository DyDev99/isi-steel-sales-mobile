import 'package:isi_steel_sales_mobile/core/usecase/usecase.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/entities/notification_item.dart';
import 'package:isi_steel_sales_mobile/features/notification/domain/repositories/notification_repository.dart';

/// The rep's notifications, newest first.
///
/// Returns a plain [Future] rather than the app-wide `ResultFuture`, matching
/// the `LeadUseCase` shape this replaced: the callers are `FutureBuilder`s with
/// their own try/catch, and converting them to `Result` is a separate change
/// from removing the lead feature.
class FetchNotifications {
  const FetchNotifications(this._repository);

  final NotificationRepository _repository;

  Future<List<NotificationItem>> call(NoParams params) =>
      _repository.fetchNotifications();
}
