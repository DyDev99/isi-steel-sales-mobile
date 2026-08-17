import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user.dart';
import 'package:isi_steel_sales_mobile/features/authentication/domain/entities/user_role.dart';

/// The signed-in employee, as returned by `GET /auth/me`.
///
/// This is deliberately richer than [User] and deliberately separate from it.
/// The `id_token` returned at sign-in is an OIDC identity token that the app
/// does not need: it does not carry [territoryCode], [depotCode] or
/// [featureFlags], and those decide what the rep actually sees. Read the
/// profile from `/auth/me` instead.
class AuthProfile extends Equatable {
  const AuthProfile({
    required this.id,
    required this.employeeId,
    required this.email,
    required this.fullName,
    this.roles = const {},
    this.permissions = const {},
    this.featureFlags = const {},
    this.territoryCode,
    this.depotCode,
    this.language,
    this.timeZone,
    this.theme,
    this.passwordExpiresAt,
    this.company,
    this.avatarUrl,
    this.phoneNumber,
    this.position,
    this.department,
    this.lastLoginAt,
  });

  final String id;

  /// The personnel number on the rep's badge and payslip. Field staff sign in
  /// with this; portal users sign in with [email]. The server resolves
  /// whichever arrives, so the login form needs one field.
  final String employeeId;

  final String email;
  final String fullName;
  final Set<UserRole> roles;

  /// Fine-grained grants, e.g. `customers.create`, `customers.readall`.
  ///
  /// **Client-side permission checks are a courtesy, never a security
  /// control.** The server re-checks every one. Use these to hide a button a
  /// user cannot press, not to protect anything.
  final Set<String> permissions;

  /// Absent flags mean off, so a client built against a newer server degrades
  /// quietly instead of throwing.
  final Map<String, bool> featureFlags;

  final String? territoryCode;
  final String? depotCode;

  /// The user's own language preference. Prefer this over the device locale on
  /// first launch — a rep whose handset is in English may well work in Khmer.
  final String? language;

  final String? timeZone;
  final String? theme;

  /// When set and near, route the user to the change-password screen before
  /// they are locked out mid-shift.
  final DateTime? passwordExpiresAt;

  final String? company;
  final String? avatarUrl;

  /// Contact number as held by HR. The profile screen shows it; nothing
  /// branches on it, and it is never used to identify the account.
  final String? phoneNumber;

  /// Job title, e.g. "Sales Representative". Distinct from [roles]: [position]
  /// is what HR calls the job and is display-only, whereas a [UserRole] is a
  /// coarse authorisation bucket. They usually read the same but are not the
  /// same thing, and the server can change one without the other.
  final String? position;

  final String? department;

  /// Previous successful sign-in. Useful on the profile screen as a passive
  /// "was this you?" signal.
  final DateTime? lastLoginAt;

  /// The best available human-readable job label, preferring what HR calls the
  /// job over the coarse authorisation bucket.
  String? get positionOrRoleLabel {
    if (position != null && position!.trim().isNotEmpty) return position;
    if (roles.isEmpty) return null;
    return roles.first.name;
  }

  bool can(String permission) => permissions.contains(permission);

  bool canAny(Iterable<String> any) => any.any(permissions.contains);

  /// Convenience for the customer capabilities, which span two namespaces.
  bool get canReadCustomers => canAny(Permissions.canReadCustomers);
  bool get canCreateCustomers => canAny(Permissions.canCreateCustomers);
  bool get canUpdateCustomers => canAny(Permissions.canUpdateCustomers);

  /// Reads a feature flag, treating an absent flag as off.
  bool flag(String name) => featureFlags[name] ?? false;

  /// Row-level scope: a plain rep sees only their own customers, a holder of
  /// `customers.readall` sees the whole territory. Enforced server-side in the
  /// query handler; this only decides whether to offer the "all customers"
  /// filter in the UI.
  bool get canSeeAllCustomers => can(Permissions.customersReadAll);

  /// True once [passwordExpiresAt] is within [window].
  bool passwordExpiringWithin(Duration window) {
    final expiry = passwordExpiresAt;
    if (expiry == null) return false;
    return expiry.difference(DateTime.now().toUtc()) <= window;
  }

  /// The narrower shape the existing session plumbing consumes.
  User toUser() => User(
        id: id,
        email: email,
        fullName: fullName,
        roles: roles,
        company: company,
        avatarUrl: avatarUrl,
      );

  @override
  List<Object?> get props => [id, employeeId, email, fullName, roles,
      permissions, featureFlags, territoryCode, depotCode];
}

/// The permission strings the app actually branches on. Kept together so a
/// typo is a compile error rather than a silently hidden button.
abstract final class Permissions {
  static const customersRead = 'customers.read';
  static const customersCreate = 'customers.create';
  static const customersUpdate = 'customers.update';

  // ── The `outlets.*` namespace ──────────────────────────────────────
  //
  // The running backend grants sales representatives `outlets.read`,
  // `outlets.create` and `outlets.update` — the same capability under a
  // different name. There is no `/mobile/outlets` route (it 404s), so these
  // are the customer permissions, not a separate feature.
  //
  // Both spellings are therefore accepted wherever a customer capability is
  // required. Checking only the `customers.*` spelling hid the directory from
  // every rep whose role uses the other one, which is the whole population.
  static const outletsRead = 'outlets.read';
  static const outletsCreate = 'outlets.create';
  static const outletsUpdate = 'outlets.update';

  /// Any of these means "may read the customer directory".
  static const canReadCustomers = {customersRead, outletsRead};

  /// Any of these means "may register a customer". The created record lands in
  /// `Draft` regardless — activating it needs [customersApprove], which reps
  /// deliberately do not hold.
  static const canCreateCustomers = {customersCreate, outletsCreate};

  /// Any of these means "may edit a customer".
  static const canUpdateCustomers = {customersUpdate, outletsUpdate};

  /// **Sales representatives do not hold this.** A rep pressing Delete gets a
  /// 403. Hide the action rather than letting them discover that.
  static const customersDelete = 'customers.delete';

  /// Widens row-level scope from "assigned to me" to the whole territory.
  static const customersReadAll = 'customers.readall';

  /// Gates `createdBy` / `updatedBy` on the customer detail payload — everyone
  /// else receives null, so do not render an empty "Last edited by" row.
  static const customersAudit = 'customers.audit';

  /// Moves a customer out of `Draft` so it can trade.
  static const customersApprove = 'customers.approve';
}
