import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The ISI Group wordmark (seal + "ISI GROUP") in light/near-white.
///
/// Use this version on dark surfaces such as photography, sign-in
/// backgrounds, dark sheets, or dark-themed screens.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.width,
    this.height,
    this.semanticsLabel = 'ISI Group',
  }) : assert(
          width != null || height != null,
          'BrandLogo needs a width or a height to size against.',
        );

  /// Target width. The height follows from the artwork's aspect ratio.
  final double? width;

  /// Target height. Used when [width] is null.
  final double? height;

  final String semanticsLabel;

  // Both exports share viewBox="409.45 340 1101.1 400".
  static const _ratio = 1101.1 / 400.0;

  static const _asset = 'assets/logos/isi-steel-light.svg';

  @override
  Widget build(BuildContext context) {
    final w = width ?? height! * _ratio;
    final h = height ?? width! / _ratio;

    return Semantics(
      label: semanticsLabel,
      image: true,
      child: SizedBox(
        width: w,
        height: h,
        child: SvgPicture.asset(
          _asset,
          width: w,
          height: h,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}