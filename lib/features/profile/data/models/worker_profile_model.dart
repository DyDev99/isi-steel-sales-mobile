import 'package:isi_steel_sales_mobile/features/profile/domain/entities/worker_profile.dart';

/// JSON-serializable version of `WorkerProfile`. Swap the field names in
/// `fromJson`/`toJson` to match your actual API payload once the real
/// endpoint is wired up in `ProfileRemoteDataSource`.
class WorkerProfileModel extends WorkerProfile {
  const WorkerProfileModel({
    required super.id,
    required super.fullName,
    required super.employeeCode,
    required super.role,
    required super.email,
    required super.phone,
    required super.territory,
    required super.region,
    required super.joinedAt,
    super.avatarUrl,
    super.isActive,
  });

  factory WorkerProfileModel.fromJson(Map<String, dynamic> json) {
    return WorkerProfileModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      employeeCode: json['employeeCode'] as String,
      role: json['role'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      territory: json['territory'] as String,
      region: json['region'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      avatarUrl: json['avatarUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  factory WorkerProfileModel.fromEntity(WorkerProfile p) => WorkerProfileModel(
        id: p.id,
        fullName: p.fullName,
        employeeCode: p.employeeCode,
        role: p.role,
        email: p.email,
        phone: p.phone,
        territory: p.territory,
        region: p.region,
        joinedAt: p.joinedAt,
        avatarUrl: p.avatarUrl,
        isActive: p.isActive,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'employeeCode': employeeCode,
        'role': role,
        'email': email,
        'phone': phone,
        'territory': territory,
        'region': region,
        'joinedAt': joinedAt.toIso8601String(),
        'avatarUrl': avatarUrl,
        'isActive': isActive,
      };
}
