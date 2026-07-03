import 'package:equatable/equatable.dart';

/// The signed-in field rep's profile — identity, contact details, and
/// work context (territory/region). Mirrors `RoutePlan`/`RouteStop`'s
/// entity shape from the routes feature (plain Equatable value object).
class WorkerProfile extends Equatable {
  const WorkerProfile({
    required this.id,
    required this.fullName,
    required this.employeeCode,
    required this.role,
    required this.email,
    required this.phone,
    required this.territory,
    required this.region,
    required this.joinedAt,
    this.avatarUrl,
    this.isActive = true,
  });

  final String id;
  final String fullName;
  final String employeeCode;
  final String role;
  final String email;
  final String phone;
  final String territory;
  final String region;
  final DateTime joinedAt;
  final String? avatarUrl;
  final bool isActive;

  WorkerProfile copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? territory,
    String? region,
    String? avatarUrl,
    bool? isActive,
  }) {
    return WorkerProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      employeeCode: employeeCode,
      role: role,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      territory: territory ?? this.territory,
      region: region ?? this.region,
      joinedAt: joinedAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props =>
      [id, fullName, employeeCode, role, email, phone, territory, region, joinedAt, avatarUrl, isActive];
}
