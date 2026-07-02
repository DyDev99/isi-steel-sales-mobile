import 'dart:async';

import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user_role.dart';

/// Single source of truth for "who is signed in right now", kept in memory.
///
/// [AuthBloc] pushes updates here on every auth change; route middleware,
/// guards, and any widget can read the current user/roles synchronously.
/// This is a plain singleton (registered in DI) — not tied to any router.
class SessionManager {
  User? _user;

  User? get currentUser => _user;
  bool get isAuthenticated => _user != null;

  Set<UserRole> get roles => _user?.roles ?? const {UserRole.guest};
  UserRole get primaryRole => _user?.primaryRole ?? UserRole.guest;

  bool can(UserRole role) => _user?.hasRole(role) ?? false;
  bool canAny(Iterable<UserRole> any) => _user?.hasAnyRole(any) ?? false;
  bool canAll(Iterable<UserRole> all) => _user?.hasAllRoles(all) ?? false;

  final _controller = StreamController<User?>.broadcast();

  /// Emits on every session change — feed this to a router's refresh
  /// listenable so redirects re-run on login/logout.
  Stream<User?> get changes => _controller.stream;

  void setUser(User user) {
    _user = user;
    _controller.add(user);
  }

  void clear() {
    _user = null;
    _controller.add(null);
  }

  void dispose() => _controller.close();
}