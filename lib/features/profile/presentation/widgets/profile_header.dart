import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/utils/app_vibe.dart';
import 'package:isi_steel_sales_mobile/features/profile/domain/entities/worker_profile.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.profile});
  final WorkerProfile profile;

  String get _initials {
    final parts = profile.fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Vibe.primaryLight,
            shape: BoxShape.circle,
            border:
                Border.all(color: Vibe.violet.withValues(alpha: 0.4), width: 2),
            image: profile.avatarUrl != null
                ? DecorationImage(
                    image: NetworkImage(profile.avatarUrl!), fit: BoxFit.cover)
                : null,
          ),
          child: profile.avatarUrl == null
              ? Text(_initials,
                  style: const TextStyle(
                      color: Vibe.violet,
                      fontSize: 26,
                      fontWeight: FontWeight.w800))
              : null,
        ),
        const SizedBox(height: 12),
        Text(profile.fullName,
            style: const TextStyle(
                color: Vibe.text, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Vibe.primaryLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Vibe.violet.withValues(alpha: 0.3)),
          ),
          child: Text(profile.role,
              style: const TextStyle(
                  color: Vibe.violet,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 2),
        Text('#${profile.employeeCode}',
            style: const TextStyle(color: Vibe.muted, fontSize: 12)),
      ],
    );
  }
}
