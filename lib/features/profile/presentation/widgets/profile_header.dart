import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    // 1. FIXED URL (Stripped formatting breaks and spaces)
    const defaultAvatarUrl = 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSNjUdsOFxJmaz8TZrILnv6OrfDw86WBWVQUkwMUKCakA&s=10';
    final imageUrl = profile.avatarUrl ?? defaultAvatarUrl;

    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: colors.surfaceStrong,
            shape: BoxShape.circle,
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.4), 
              width: 2,
            ),
          ),
          // 2. Safe clipping with built-in runtime exception management
          child: ClipRRect(
            borderRadius: BorderRadius.circular(42),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              // Catches Handshake/SSL exceptions seamlessly
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Text(
                    _initials,
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: Text(
                    _initials,
                    style: TextStyle(
                      color: scheme.primary.withValues(alpha: 0.5),
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          profile.fullName,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colors.surfaceStrong.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
          ),
          child: Text(
            profile.role,
            style: TextStyle(
              color: scheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '#${profile.employeeCode}',
          style: TextStyle(color: colors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}