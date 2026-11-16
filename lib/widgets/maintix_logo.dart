import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

/// Homaclo brand mark: house + solar panel + water drop + wave, rendered from
/// `assets/images/homaclo_logo.svg` (sharp on every screen density).
///
/// The class keeps its old name so every existing call site picks up the new
/// logo without touching imports.
class HomacloDrop extends StatelessWidget {
  /// Height of the mark. Width follows the logo ratio (1310 : 880).
  final double height;

  const HomacloDrop({super.key, this.height = 26});

  static const double _ratio = 1310 / 880;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/homaclo_logo.svg',
      width: height * _ratio,
      height: height,
      fit: BoxFit.contain,
    );
  }
}

/// Logo mark + "Homaclo" wordmark in Fraunces Bold. Pass [width] / [height] to
/// fit it into a box (it scales down, never distorts). With a near-square box
/// the mark is stacked above the text; otherwise they sit side by side.
class HomacloLogo extends StatelessWidget {
  final double? width;
  final double? height;

  /// Kept so existing call sites that passed a corner radius still compile.
  final double borderRadius;
  final BoxFit fit;

  /// Overrides the wordmark colour (defaults to the website ink colour for the
  /// current light / dark theme).
  final Color? color;

  /// Set false to show only the logo mark.
  final bool showText;

  const HomacloLogo({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 14,
    this.fit = BoxFit.contain,
    this.color,
    this.showText = true,
  });

  static const Color _inkLight = Color(0xFF0B1F3A);
  static const Color _inkDark = Color(0xFFEAF2FF);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = color ?? (dark ? _inkDark : _inkLight);

    final stacked =
        width != null && height != null && (width! / height!) < 1.6;

    final drop = const HomacloDrop(height: 32);
    final text = Text(
      'Homaclo',
      maxLines: 1,
      softWrap: false,
      style: GoogleFonts.fraunces(
        fontSize: 21.6,
        fontWeight: FontWeight.w700,
        color: ink,
        height: 1.2,
      ),
    );

    Widget content;
    if (!showText) {
      content = drop;
    } else if (stacked) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [drop, const SizedBox(height: 9), text],
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [drop, const SizedBox(width: 9), text],
      );
    }

    if (width == null && height == null) return content;
    return SizedBox(
      width: width,
      height: height,
      child: FittedBox(fit: fit, child: content),
    );
  }
}

/// Legacy class name used across the app. It now renders the Homaclo logo, so
/// every existing screen picks up the new branding without touching imports.
class MaintixLogo extends HomacloLogo {
  const MaintixLogo({
    super.key,
    super.width,
    super.height,
    super.borderRadius,
    super.fit,
    super.color,
    super.showText,
  });
}
