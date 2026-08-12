import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';
import 'package:isi_steel_sales_mobile/features/profile/domain/entities/worker_profile.dart';
import 'package:isi_steel_sales_mobile/core/responsive/responsive_sizing.dart';

/// A calm, premium profile header.
///
/// Pairs a soft gradient "aura" behind the avatar (the modern touch) with a
/// small gold verified/premium badge (the classic, trustworthy touch) so the
/// same component reads well to both a younger, design-forward audience and
/// a more traditional "premium member" audience.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.profile, this.isTablet = false});

  final WorkerProfile profile;
  final bool isTablet;

  static const _gold = Color(0xFFC9A959);

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

    const defaultAvatarUrl =
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSNjUdsOFxJmaz8TZrILnv6OrfDw86WBWVQUkwMUKCakA&s=10';
    final imageUrl = profile.avatarUrl ?? defaultAvatarUrl;

    final avatarSize = isTablet ? 128.0 : 92.0;
    final ringPadding = isTablet ? 6.0 : 4.0;
    final badgeSize = isTablet ? 34.0 : 26.0;

    return Column(
      children: [
        SizedBox(
          width: avatarSize + 16,
          height: avatarSize + 16,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Soft gradient aura — the "relax" / modern touch behind the ring.
              Container(
                width: avatarSize + 16,
                height: avatarSize + 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      scheme.primary.withValues(alpha: 0.20),
                      scheme.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              // Gradient ring + avatar.
              Container(
                width: avatarSize,
                height: avatarSize,
                padding: EdgeInsets.all(ringPadding),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary.withValues(alpha: 0.9),
                      _gold.withValues(alpha: 0.85),
                    ],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surfaceStrong,
                  ),
                  child: ClipOval(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          _initials,
                          style: TextStyle(
                            color: scheme.primary,
                            fontSize: isTablet ? 34 : context.rsp(26),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: Text(
                            _initials,
                            style: TextStyle(
                              color: scheme.primary.withValues(alpha: 0.5),
                              fontSize: isTablet ? 34 : context.rsp(26),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Small premium/verified badge — classic, trust-building detail.
              Positioned(
                right: 2,
                bottom: 4,
                child: Container(
                  width: badgeSize,
                  height: badgeSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surfaceSoft,
                    border: Border.all(color: colors.surfaceSoft, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.verified_rounded,
                    size: badgeSize * 0.72,
                    color: _gold,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isTablet ? 18 : context.rh(14)),
        Text(
          profile.fullName,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: isTablet ? 22 : context.rsp(18),
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
        SizedBox(height: isTablet ? 10 : context.rh(6)),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 14 : 10,
            vertical: isTablet ? 6 : 4,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.primary.withValues(alpha: 0.16),
                _gold.withValues(alpha: 0.16),
              ],
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
          ),
          child: Text(
            profile.role,
            style: TextStyle(
              color: scheme.primary,
              fontSize: isTablet ? 13 : context.rsp(12),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        SizedBox(height: isTablet ? 8 : context.rh(4)),
        Text(
          '#${profile.employeeCode}',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: isTablet ? 13 : context.rsp(12),
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}