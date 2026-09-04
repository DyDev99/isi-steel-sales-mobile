import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Which ink the ISI Group wordmark is drawn in.
///
/// The two are the *same* artwork, not two logos: `ISI-Group-Logo-Dark.svg`
/// fills at `#15213A` and `ISI-Group-Logo-Light.svg` at `#E0E4EE`. Which one
/// is correct is a property of the surface behind it, never of the screen —
/// picking by surface is the whole reason this widget exists, because the
/// wrong choice does not look slightly off, it disappears.
enum BrandInk {
  /// Near-black navy. The default, and the one to use on white, on the
  /// canvas tint, and on any card.
  dark,

  /// Near-white. For dark surfaces only: photography, the sign-in backdrop,
  /// and dark-theme sheets.
  light,
}

/// The ISI Group wordmark (seal + "ISI GROUP"), drawn as vector.
///
/// Replaces the raster marks that used to be pasted per screen
/// (`isi_app_logo.png`, `isi_main_screen_logo.png`, `darkmood_logo.jpg`),
/// each at its own size and its own idea of the aspect ratio — one of them
/// with `BoxFit.cover` on a box narrower than the artwork, which silently
/// cropped the wordmark. Sizing here is one-dimensional on purpose: give it a
/// [width] *or* a [height] and the other is derived from the artwork, so the
/// mark cannot be squashed by a caller.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.width,
    this.height,
    this.ink,
    this.semanticsLabel = 'ISI Group',
  }) : assert(
          width != null || height != null,
          'BrandLogo needs a width or a height to size against.',
        );

  /// Target width. The height follows from the artwork's aspect ratio.
  final double? width;

  /// Target height, used when [width] is null.
  final double? height;

  /// Leave null to resolve from the ambient [Theme] brightness — dark ink on
  /// a light theme, light ink on a dark one. Pass it explicitly wherever the
  /// surface disagrees with the theme, which is exactly the case for anything
  /// sitting on the sign-in photograph.
  final BrandInk? ink;

  final String semanticsLabel;

  // From each file's own viewBox: the two exports are cropped slightly
  // differently, so they do not share a ratio and must not share a constant.
  static const _darkRatio = 780.832031 / 271.0; // ≈ 2.881
  static const _lightRatio = 533.535156 / 180.0; // ≈ 2.964

  static const _darkAsset = 'assets/logos/ISI-Group-Logo-Dark.svg';
  static const _lightAsset = 'assets/logos/ISI-Group-Logo-Light.svg';

  @override
  Widget build(BuildContext context) {
    final resolved = ink ??
        (Theme.of(context).brightness == Brightness.dark
            ? BrandInk.light
            : BrandInk.dark);
    final isDarkInk = resolved == BrandInk.dark;
    final ratio = isDarkInk ? _darkRatio : _lightRatio;

    // Both dimensions are given rather than one, so the box is known before
    // the picture decodes. With only a width the widget is unbounded
    // vertically for a frame and whatever sits under it jumps once.
    final w = width ?? height! * ratio;
    final h = height ?? width! / ratio;

    return SvgPicture.asset(
      isDarkInk ? _darkAsset : _lightAsset,
      width: w,
      height: h,
      fit: BoxFit.contain,
      semanticsLabel: semanticsLabel,
    );
  }
}
