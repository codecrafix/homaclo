import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Homaclo brand logo, identical to the website header logo
/// (`.logo` + `.drop` in web/site/styles.css): a teal/cyan water-drop mark
/// followed by the "Homaclo" wordmark in Fraunces Bold.
///
/// Drawn in code (no image asset), so it is sharp on every screen density and
/// follows light / dark theme automatically.
class HomacloDrop extends StatelessWidget {
  /// Height of the drop. Width follows the website ratio (20 : 26).
  final double height;

  const HomacloDrop({super.key, this.height = 26});

  @override
  Widget build(BuildContext context) {
    final h = height;
    final w = h * 20 / 26;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.34, -0.94),
          end: Alignment(0.34, 0.94),
          colors: [Color(0xFF22D3EE), Color(0xFF0FB9A8)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.elliptical(w / 2, h * 0.62),
          topRight: Radius.elliptical(w / 2, h * 0.62),
          bottomLeft: Radius.elliptical(w / 2, h * 0.38),
          bottomRight: Radius.elliptical(w / 2, h * 0.38),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(15, 185, 168, 0.45),
            offset: Offset(0, h * 4 / 26),
            blurRadius: h * 12 / 26,
          ),
        ],
      ),
    );
  }
}

/// Drop + "Homaclo" wordmark. Pass [width] / [height] to fit it into a box
/// (it scales down, never distorts). With a near-square box the drop is
/// stacked above the text; otherwise they sit side by side like the website.
class HomacloLogo extends StatelessWidget {
  final double? width;
  final double? height;

  /// Kept so existing call sites that passed a corner radius still compile.
  final double borderRadius;
  final BoxFit fit;

  /// Overrides the wordmark colour (defaults to the website ink colour for the
  /// current light / dark theme).
  final Color? color;

  /// Set false to show only the drop mark.
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

    final drop = const HomacloDrop(height: 26);
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
