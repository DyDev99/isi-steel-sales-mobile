import 'package:flutter/material.dart';
import 'package:isi_steel_sales_mobile/core/theme/theme_extensions.dart';

/// Circular avatar for a lead, showing the initials of [name] over a tinted
/// disc.
///
/// Initials rather than a generic person glyph: a board shows ~6 cards at once
/// and identical grey silhouettes are useless for scanning. [seed] (normally the
/// lead id) picks a stable tint from the theme palette, so the same company
/// keeps the same colour across rebuilds and sort changes.
class LeadAvatar extends StatelessWidget {
  const LeadAvatar({
    super.key,
    required this.name,
    this.seed,
    this.size = 32,
  });

  final String name;
  final String? seed;
  final double size;

  /// Up to two initials from the first and last word.
  static String initialsOf(String name) {
    final words = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      final w = words.first;
      return (w.length == 1 ? w : w.substring(0, 2)).toUpperCase();
    }
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  Color _tint(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.appColors;
    final palette = [
      scheme.primary,
      colors.accentPurple,
      colors.success,
      colors.info,
      colors.warning,
      colors.brandNavy,
    ];
    // Stable, not random: the same lead must not change colour on rebuild.
    final key = (seed ?? name).hashCode.abs();
    return palette[key % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final tint = _tint(context);
    final initials = initialsOf(name);

    return Semantics(
      // The initials are decorative shorthand; the name is already announced by
      // the card's own text, so this is excluded from the reading order.
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        child: Text(
          initials,
          maxLines: 1,
          style: TextStyle(
            color: tint,
            // Scales with the disc so a larger avatar doesn't clip its text.
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}
