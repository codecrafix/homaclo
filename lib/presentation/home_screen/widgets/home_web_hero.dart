import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/premium_ui.dart';
import './home_web_sections.dart' show homeServicesKey;

/// Home hero, laid out like the website: full-width navy section (no extra
/// card margin), 24 px side padding and a landscape photo with the two
/// website badges ("Fixed, upfront pricing" top right, "Starting ₹1,000"
/// bottom left).
class HomeHero extends StatelessWidget {
  const HomeHero({super.key});

  static const String _photo =
      'https://homaclo.in/img/maintix-8.png?v=20261023';

  TextStyle _head(double size, Color color) => GoogleFonts.fraunces(
    fontSize: size,
    fontWeight: FontWeight.w700,
    height: 1.15,
    color: color,
  );

  TextStyle _body(
    double size,
    Color color, {
    FontWeight weight = FontWeight.w500,
    double? height,
  }) => GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    height: height,
    color: color,
  );

  void _toServices() {
    final ctx = homeServicesKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Widget _badge(
    String text, {
    required Alignment at,
    required Color bg,
    required Color fg,
  }) => Align(
    alignment: at,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          text,
          style: _body(13, fg, weight: FontWeight.w800, height: 1.2),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF04202A);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF04132E), Color(0xFF072654), Color(0xFF0A3B66)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Colors.white.withAlpha(46)),
            ),
            child: Text(
              '💧 SATNA’S TRUSTED HOME SERVICES',
              style: _body(
                11.5,
                Colors.white,
                weight: FontWeight.w800,
              ).copyWith(letterSpacing: 0.5),
            ),
          ),
          const SizedBox(height: 18),
          Text.rich(
            TextSpan(
              style: _head(33, Colors.white),
              children: [
                const TextSpan(text: 'Clean tank. '),
                TextSpan(
                  text: 'Clean water. ',
                  style: _head(33, AppGradients.cyan),
                ),
                const TextSpan(text: 'Healthy home.'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Professional, hygienic water tank cleaning, plus solar panel cleaning and repair, with transparent pricing and doorstep service. Book in under two minutes.',
            style: _body(
              15,
              const Color(0xFFC5D6EE),
              weight: FontWeight.w500,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go(AppRoutes.bookingScreen),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tealAccent,
                foregroundColor: ink,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Book a cleaning →',
                style: _body(15, ink, weight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _toServices,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'See pricing',
                style: _body(15, Colors.white, weight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: AspectRatio(
              aspectRatio: 1.45,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Color(0xFF0B2A52)),
                  // Disk-cached: downloaded once, instant on every next launch.
                  CachedNetworkImage(
                    imageUrl: _photo,
                    fit: BoxFit.cover,
                    memCacheWidth: 900,
                    fadeInDuration: const Duration(milliseconds: 120),
                    fadeOutDuration: Duration.zero,
                    placeholder: (_, __) => const SizedBox.shrink(),
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                  _badge(
                    'Fixed, upfront pricing',
                    at: Alignment.topRight,
                    bg: const Color(0xCC0A1424),
                    fg: Colors.white,
                  ),
                  _badge(
                    'Starting ₹1,000',
                    at: Alignment.bottomLeft,
                    bg: const Color(0xFF10B981),
                    fg: ink,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              for (final t in const [
                '✔ Food-grade cleaning agents',
                '✔ No hidden charges',
                '✔ Secure Razorpay payment',
              ])
                Text(
                  t,
                  style: _body(
                    13,
                    const Color(0xFFA9C0E2),
                    weight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
