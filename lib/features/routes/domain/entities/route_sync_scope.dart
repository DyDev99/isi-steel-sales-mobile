import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/core/session/session_manager.dart';

/// Narrows sync to the signed-in rep's own routes — mirrors
/// `order`'s `SyncScope.forCurrentUser` shape/rationale exactly (the
/// current `User` entity has no territory field yet, so this fills in a
/// stable mock default keyed off the rep).
class RouteSyncScope extends Equatable {
  const RouteSyncScope({required this.repId, required this.territory});

  final String repId;
  final String territory;

  factory RouteSyncScope.forCurrentUser(SessionManager sessionManager) {
    final user = sessionManager.currentUser;
    return RouteSyncScope(repId: user?.id ?? 'guest', territory: 'Phnom Penh');
  }

  @override
  List<Object?> get props => [repId, territory];
}
