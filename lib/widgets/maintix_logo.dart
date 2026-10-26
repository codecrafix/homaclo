import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Homaclo brand logo (new design) — rounded square tile.
///
/// Rendered from the vector asset `assets/images/maintix_logo.svg`
/// (already covered by the `assets/images/` entry in pubspec.yaml), so it is
/// pixel-sharp at ANY size / screen density (FHD, QHD, 4K) and can never be
/// corrupted by a bad copy-paste like the old embedded-base64 approach.
///
/// The artwork is a square with its own white background, so the widget always
/// draws a true square with rounded corners. Callers keep the same
/// `width` / `height` / `borderRadius` / `fit` parameters as before.
class MaintixLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;

  const MaintixLogo({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 14,
    this.fit = BoxFit.contain,
  });

  static const String _assetPath = 'assets/images/maintix_logo.svg';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SvgPicture.asset(
        _assetPath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          // Visible fallback instead of a silent blank box.
          return Container(
            width: width,
            height: height,
            color: const Color(0xFF00A8CC),
            alignment: Alignment.center,
            child: const Text(
              'H',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 24,
              ),
            ),
          );
        },
      ),
    );
  }
}
