import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../presentation/home_screen/widgets/web_tokens.dart';
import 'site_header.dart' show SiteLogo;
import 'tap_scale.dart';

/// Homaclo footer: brand, contact buttons and services. Dark navy gradient in
/// both light and dark mode. Shown ONLY at the end of the Home screen.
class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  static const Color _link = Color(0xFF94A3B8);
  static const String _site = 'https://homaclo.in/';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF030712), Color(0xFF0F172A)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SiteLogo(light: true, scale: 1.1),
          const SizedBox(height: 10),
          Text(
            'Trusted water tank cleaning for homes and businesses across Satna, Madhya Pradesh.',
            style: WT.sans(14, color: _link, h: 1.6),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ContactBtn(
                  'WhatsApp',
                  whatsapp: true,
                  onTap: () => wOpen('https://wa.me/${WT.waNumber}'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ContactBtn(
                  'Call',
                  onTap: () => wOpen('tel:+916262262913'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ContactBtn(
                  'Email',
                  onTap: () => wOpen('mailto:${WT.mail}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _SocialBtn(
                tooltip: 'Instagram',
                onTap: () => wOpen('https://www.instagram.com/homaclo/'),
                painter: _InstagramPainter(),
              ),
              const SizedBox(width: 10),
              _SocialBtn(
                tooltip: 'YouTube',
                onTap: () => wOpen('https://www.youtube.com/@homaclo'),
                painter: _YoutubePainter(),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _head('Services in Satna'),
          _Link(
            'Water tank cleaning',
            () => wOpen('${_site}water-tank-cleaning-satna/'),
          ),
          _Link(
            'Solar panel cleaning',
            () => wOpen('${_site}solar-panel-cleaning-satna/'),
          ),
          _Link(
            'Solar repair & maintenance',
            () => wOpen('${_site}solar-repair-maintenance-satna/'),
          ),
          const SizedBox(height: 22),
          Text(
            '© 2026 Homaclo. Payments secured by Razorpay.',
            style: WT.sans(12.5, color: _link, h: 1.5),
          ),
        ],
      ),
    );
  }

  static Widget _head(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      t,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    ),
  );
}

class _Link extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const _Link(this.text, this.onTap);

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: WT.sans(14.5, color: SiteFooter._link, h: 1.4),
        ),
      ),
    );
    if (onTap == null) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }
}

class _ContactBtn extends StatelessWidget {
  final String label;
  final bool whatsapp;
  final VoidCallback onTap;
  const _ContactBtn(this.label, {this.whatsapp = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      scale: 0.95,
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: whatsapp ? const Color(0xFF10B981) : const Color(0x12FFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: whatsapp ? const Color(0xFF10B981) : const Color(0x24FFFFFF),
          ),
        ),
        child: Text(
          label,
          style: WT.sans(
            14,
            color: whatsapp ? const Color(0xFF04201A) : Colors.white,
            w: FontWeight.w700,
            h: 1.2,
          ),
        ),
      ),
    );
  }
}

/// Square social button, same look as the website footer (42px, 12px radius).
class _SocialBtn extends StatelessWidget {
  final String tooltip;
  final VoidCallback onTap;
  final CustomPainter painter;
  const _SocialBtn({
    required this.tooltip,
    required this.onTap,
    required this.painter,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: TapScale(
        scale: 0.92,
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0x1A7F7F7F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x597F7F7F)),
          ),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CustomPaint(painter: painter),
          ),
        ),
      ),
    );
  }
}

/// Instagram glyph (24x24 viewBox, same shapes as the website icon).
class _InstagramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(3 * k, 3 * k, 18 * k, 18 * k),
        Radius.circular(5 * k),
      ),
      stroke,
    );
    canvas.drawCircle(Offset(12 * k, 12 * k), 4 * k, stroke);
    canvas.drawCircle(
      Offset(17.5 * k, 6.5 * k),
      1 * k,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// YouTube glyph (24x24 viewBox): rounded rectangle with a play triangle cut out.
class _YoutubePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final body = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(0, 3.6 * k, 24 * k, 20.4 * k),
          Radius.circular(5 * k),
        ),
      );
    final play = Path()
      ..moveTo(9.6 * k, 8.4 * k)
      ..lineTo(15.8 * k, 12 * k)
      ..lineTo(9.6 * k, 15.6 * k)
      ..close();
    canvas.drawPath(
      Path.combine(PathOperation.difference, body, play),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
