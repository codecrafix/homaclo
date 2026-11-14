import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../presentation/home_screen/widgets/web_tokens.dart';
import '../routes/app_routes.dart';
import 'site_header.dart' show SiteLogo;
import 'tap_scale.dart';

/// The Homaclo website footer (web/site `.foot`). Like the website it is a
/// dark navy gradient in both light and dark mode. Put it at the end of a
/// scrolling screen.
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
          const SizedBox(height: 16),
          Row(
            children: [
              _SocialBtn(
                icon: Icons.camera_alt_outlined,
                label: 'Instagram',
                hover: const Color(0xFFDC2743),
                onTap: () => wOpen('https://www.instagram.com/homaclo/'),
              ),
              const SizedBox(width: 10),
              _SocialBtn(
                icon: Icons.play_arrow_rounded,
                label: 'YouTube',
                hover: const Color(0xFFFF0000),
                onTap: () => wOpen('https://www.youtube.com/@homaclo'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _head('Company'),
          _Link('About Homaclo', () => wOpen('${_site}homaclo/')),
          _Link('About', () => context.push(AppRoutes.aboutUsScreen)),
          _Link('Reviews', () => context.go(AppRoutes.reviewsScreen)),
          _Link('Blog', () => wOpen('${_site}blog/')),
          _Link('Privacy Policy', () => context.push(AppRoutes.privacyPolicyScreen)),
          _Link('Terms', () => context.push(AppRoutes.termsScreen)),
          const SizedBox(height: 22),
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
          _head('Contact'),
          _Link(WT.mail, () => wOpen('mailto:${WT.mail}')),
          _Link('+91 62622 62913', () => wOpen('tel:+916262262913')),
          _Link('Satna, Madhya Pradesh', null),
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

class _SocialBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color hover;
  final VoidCallback onTap;
  const _SocialBtn({
    required this.icon,
    required this.label,
    required this.hover,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
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
          child: Icon(icon, size: 21, color: Colors.white),
        ),
      ),
    );
  }
}
