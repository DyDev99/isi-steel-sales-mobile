import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

/// A locked, sign-in-gated feature shown to a guest as a teaser.
class GuestLockedFeature {
  const GuestLockedFeature(
      {required this.icon, required this.title, required this.blurb});

  final IconData icon;
  final String title;
  final String blurb;
}

/// "Feature preview" — a vertical list of the tools a guest unlocks by signing
/// in (CRM, dashboard, analytics …), each blurred with a "Login required" badge.
///
/// The blur is real ([ImageFilter], via [BackdropFilter]) so the preview *shows*
/// there is something behind the lock — the conversion lever the brief asks for
/// — rather than an opaque placeholder that reads as "empty".
///
/// Tapping any card calls [onLocked], which the screen wires to the same login
/// prompt the rest of the app uses (`AuthGuard`), so there is no dead end.
class GuestFeaturePreview extends StatelessWidget {
  const GuestFeaturePreview({super.key, required this.onLocked, this.features});

  static const List<GuestLockedFeature> defaults = [
    GuestLockedFeature(
        icon: Icons.dashboard_rounded,
        title: 'Sales dashboard',
        blurb: 'Live targets, revenue and pipeline health'),
    GuestLockedFeature(
        icon: Icons.people_alt_rounded,
        title: 'CRM & leads',
        blurb: 'Manage customers and move deals to won'),
    GuestLockedFeature(
        icon: Icons.insights_rounded,
        title: 'Analytics & reports',
        blurb: 'Trends, forecasts and exportable reports'),
  ];

  final List<GuestLockedFeature>? features;
  final VoidCallback onLocked;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final f in features ?? defaults)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _LockedCard(feature: f, onTap: onLocked),
          ),
      ],
    );
  }
}

class _LockedCard extends StatelessWidget {
  const _LockedCard({required this.feature, required this.onTap});

  final GuestLockedFeature feature;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;

    return Semantics(
      button: true,
      label: '${feature.title}. Login required.',
      child: Material(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border),
              boxShadow: colors.cardShadow,
            ),
            child: Stack(
              children: [
                // The real content, slightly de-emphasised, sits under the blur.
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child:
                            Icon(feature.icon, color: scheme.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(feature.title,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                )),
                            const SizedBox(height: 3),
                            Text(feature.blurb,
                                maxLines: 2,
                                style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 12,
                                    height: 1.25)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Frosted veil over the blurb area only — a light blur keeps the
                // card legible enough to be enticing while clearly "locked".
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 2.2, sigmaY: 2.2),
                      child: const SizedBox(),
                    ),
                  ),
                ),
                Positioned(
                    top: 10, right: 10, child: _LockBadge(scheme: scheme)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LockBadge extends StatelessWidget {
  const _LockBadge({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: 11, color: scheme.onPrimary),
          const SizedBox(width: 4),
          Text('Login required',
              style: TextStyle(
                color: scheme.onPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}
