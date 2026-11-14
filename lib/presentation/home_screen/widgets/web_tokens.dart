import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../providers/app_state.dart';
import '../../../services/solar_cart.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/tap_scale.dart';

/// Design tokens copied from the Homaclo website (homaclo.in).
class WT {
  WT._();

  static bool get dark => AppTheme.isDark;

  static const Color navy = Color(0xFF050C1A);
  static const Color teal = Color(0xFF06B6D4);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color ok = Color(0xFF10B981);
  static const Color btnText = Color(0xFF04202A);

  static const LinearGradient btn = LinearGradient(
    colors: [teal, cyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color get bg =>
      dark ? const Color(0xFF06142A) : const Color(0xFFF5F8FC);
  static Color get sf => dark ? const Color(0xFF0C2142) : Colors.white;
  static Color get ink =>
      dark ? const Color(0xFFEAF2FF) : const Color(0xFF0B1F3A);
  static Color get mut =>
      dark ? const Color(0xFF9DB0CC) : const Color(0xFF5B6B82);
  static Color get line =>
      dark ? const Color(0xFF1B3359) : const Color(0xFFE2E9F2);
  static Color get shadow =>
      dark ? const Color(0x59000000) : const Color(0x17072654);

  static const String imgBase = 'https://homaclo.in/img/';
  static String img(String n) => '$imgBase$n?v=20261023';

  static const String routeLogin = '/sign-up-login-screen';
  static const String routeBook = '/booking-screen';
  static const String routeNotifications = '/notifications-screen';

  static const String waNumber = '916262262913';
  static const String mail = 'homaclo.official@gmail.com';

  static TextStyle serif(double size, {Color? color, double h = 1.15}) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? ink,
        height: h,
      );

  static TextStyle sans(
    double size, {
    Color? color,
    FontWeight w = FontWeight.w400,
    double h = 1.5,
    double? ls,
  }) => GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: w,
    color: color ?? ink,
    height: h,
    letterSpacing: ls,
  );
}

Future<void> wOpen(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
}

Future<void> wWhatsApp(String text) =>
    wOpen('https://wa.me/${WT.waNumber}?text=${Uri.encodeComponent(text)}');

/// Opens the Book tab (fresh cart), optionally on the Solar Panel tab.
void goBook(BuildContext context, {bool solar = false}) {
  context.read<AppState>().resetCart();
  SolarCart.instance.setSolar(solar);
  context.go(WT.routeBook);
}

class WImg extends StatelessWidget {
  final String name;
  final BoxFit fit;
  const WImg(this.name, {super.key, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: WT.img(name),
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      placeholder: (c, u) => Container(color: WT.line),
      errorWidget: (c, u, e) => Container(
        color: WT.line,
        child: Icon(Icons.image_outlined, color: WT.mut),
      ),
    );
  }
}

class WBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool ghost;
  final Color? ghostColor;
  final bool small;
  final bool full;
  final Color? fill;
  final Color? fillText;

  const WBtn(
    this.label, {
    super.key,
    required this.onTap,
    this.ghost = false,
    this.ghostColor,
    this.small = false,
    this.full = true,
    this.fill,
    this.fillText,
  });

  @override
  Widget build(BuildContext context) {
    final h = small ? 44.0 : 52.0;
    final radius = BorderRadius.circular(14);
    final fs = small ? 14.0 : 15.5;
    final pad = EdgeInsets.symmetric(horizontal: small ? 18 : 22);
    Widget child;
    if (ghost) {
      final c = ghostColor ?? WT.ink;
      child = Container(
        height: h,
        alignment: Alignment.center,
        padding: pad,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: c, width: 1.5),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: WT.sans(fs, color: c, w: FontWeight.w700, h: 1.2),
        ),
      );
    } else {
      child = Container(
        height: h,
        alignment: Alignment.center,
        padding: pad,
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: fill == null ? WT.btn : null,
          color: fill,
          boxShadow: fill == null
              ? [
                  BoxShadow(
                    color: const Color(0x5906B6D4),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: WT.sans(
            fs,
            color: fillText ?? WT.btnText,
            w: FontWeight.w700,
            h: 1.2,
          ),
        ),
      );
    }
    final btn = TapScale(scale: 0.96, onTap: onTap, child: child);
    return full
        ? SizedBox(width: double.infinity, child: btn)
        : IntrinsicWidth(child: btn);
  }
}

class WCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;
  final double radius;

  const WCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.borderColor,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? WT.sf,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? WT.line),
        boxShadow: [
          BoxShadow(
            color: WT.shadow,
            blurRadius: 34,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class WHead extends StatelessWidget {
  final String title;
  final String? sub;
  final String? kick;
  final bool center;

  const WHead({
    super.key,
    required this.title,
    this.sub,
    this.kick,
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    final align = center ? TextAlign.center : TextAlign.start;
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: center
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          if (kick != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: WT.teal.withAlpha(36),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                kick!,
                style: WT.sans(
                  12.5,
                  color: WT.teal,
                  w: FontWeight.w800,
                  ls: 1.4,
                  h: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(title, textAlign: align, style: WT.serif(25)),
          if (sub != null) ...[
            const SizedBox(height: 10),
            Text(
              sub!,
              textAlign: align,
              style: WT.sans(15, color: WT.mut, h: 1.6),
            ),
          ],
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

/// Two cards per row, equal height.
Widget wGrid2(List<Widget> items, {double gap = 12}) {
  final rows = <Widget>[];
  for (var i = 0; i < items.length; i += 2) {
    final a = items[i];
    final b = i + 1 < items.length ? items[i + 1] : const SizedBox.shrink();
    rows.add(
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: a),
            SizedBox(width: gap),
            Expanded(child: b),
          ],
        ),
      ),
    );
    if (i + 2 < items.length) rows.add(SizedBox(height: gap));
  }
  return Column(children: rows);
}
