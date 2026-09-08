import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Which ink the ISI Group wordmark is drawn in.
///
/// The two are the *same* artwork, not two logos: one fills navy (`#011E41`),
/// the other near-white (`#DCE3EB`). Which one is correct is a property of the
/// surface behind it, never of the screen — picking by surface is the whole
/// reason this widget exists, because the wrong choice does not look slightly
/// off, it disappears.
///
/// The filenames name the **ink**, matching this enum: `isi-steel-dark.svg` is
/// the navy mark and `isi-steel-light.svg` the near-white one. Each file's
/// `<title>` states the surface it belongs on, which is the thing to read if
/// there is ever any doubt.
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

  // Both exports share `viewBox="409.45 340 1101.1 400"`, so unlike the
  // previous pair — which were cropped differently and needed a ratio each —
  // one constant covers both. Re-read the viewBox if the artwork is replaced.
  static const _ratio = 1101.1 / 400.0; // ≈ 2.753

  // Named for the ink, so these map straight across. Getting them the wrong
  // way round does not look slightly off — a near-white mark on a white card
  // is simply gone — so `brand_logo_asset_test.dart` asserts each file's fill
  // rather than trusting the filename.
  static const _darkInkAsset = 'assets/logos/isi-steel-dark.svg'; // #011E41
  static const _lightInkAsset = 'assets/logos/isi-steel-light.svg'; // #DCE3EB

  @override
  Widget build(BuildContext context) {
    final resolved = ink ??
        (Theme.of(context).brightness == Brightness.dark
            ? BrandInk.light
            : BrandInk.dark);
    final isDarkInk = resolved == BrandInk.dark;

    // Both dimensions are given rather than one, so the box is known before
    // the picture decodes. With only a width the widget is unbounded
    // vertically for a frame and whatever sits under it jumps once.
    final w = width ?? height! * _ratio;
    final h = height ?? width! / _ratio;

    return SvgPicture.asset(
      isDarkInk ? _darkInkAsset : _lightInkAsset,
      width: w,
      height: h,
      fit: BoxFit.contain,
      semanticsLabel: semanticsLabel,
    );
  }
}
