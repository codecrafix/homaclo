import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../routes/app_routes.dart';
import '../../../services/solar_cart.dart';
import '../../../services/supabase_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/premium_ui.dart';
import './home_services_widget.dart';

/// Home page sections that mirror the Homaclo website home page
/// (hero photo, stats, services, how it works, why Homaclo, real work proof,
/// how we keep water safe, reviews, call to action).
/// Services and reviews are read from the same Supabase tables as the website,
/// and the photos are the same files the website uses (homaclo.in/img).

/// Lets the hero's "See pricing" button scroll to the services section.
final GlobalKey homeServicesKey = GlobalKey();

const String _imgBase = 'https://homaclo.in/img/maintix-';
const String _imgVer = '?v=20261023';

/// A website photo (maintix-N.png). Shows [fallback] (or nothing) if it cannot load.
Widget _webImage(
  int n, {
  BoxFit fit = BoxFit.cover,
  Widget? fallback,
  double? height,
}) {
  return Image.network(
    '$_imgBase$n.png$_imgVer',
    fit: fit,
    width: double.infinity,
    height: height,
    gaplessPlayback: true,
    loadingBuilder: (context, child, progress) {
      if (progress == null) return child;
      return Container(
        height: height,
        color: const Color(0xFF0B2A52).withOpacity(0.25),
      );
    },
    errorBuilder: (_, __, ___) => fallback ?? const SizedBox.shrink(),
  );
}

TextStyle _head(double size, {Color? color}) => GoogleFonts.fraunces(
  fontSize: size,
  fontWeight: FontWeight.w700,
  height: 1.15,
  color: color ?? AppTheme.textPrimary,
);

TextStyle _body(double size, {Color? color, FontWeight? weight, double? height}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight ?? FontWeight.w500,
      height: height,
      color: color ?? AppTheme.textSecondary,
    );

BoxDecoration _card({double radius = 20}) => BoxDecoration(
  color: AppTheme.surfaceWhite,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: AppTheme.divider),
  boxShadow: [
    BoxShadow(
      color: AppTheme.cardShadow,
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ],
);

Widget _sectionHead(String title, String sub, {String? kicker}) {
  return Column(
    children: [
      if (kicker != null) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.tealAccent.withOpacity(0.14),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            kicker,
            style: _body(
              11,
              color: AppTheme.tealAccent,
              weight: FontWeight.w800,
            ).copyWith(letterSpacing: 1.1),
          ),
        ),
        const SizedBox(height: 12),
      ],
      Text(title, textAlign: TextAlign.center, style: _head(24)),
      const SizedBox(height: 8),
      Text(
        sub,
        textAlign: TextAlign.center,
        style: _body(13, height: 1.5),
      ),
    ],
  );
}

// ---------------------------------------------------------------- hero

class HomeWebHero extends StatefulWidget {
  const HomeWebHero({super.key});

  @override
  State<HomeWebHero> createState() => _HomeWebHeroState();
}

class _HomeWebHeroState extends State<HomeWebHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

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

  Widget _tankArt() => Center(
    child: SizedBox(
      width: 230,
      height: 230,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(painter: _TankPainter(_c.value)),
      ),
    ),
  );

  Widget _badge(String text, {required Alignment at}) => Align(
    alignment: at,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          style: _body(
            12,
            color: const Color(0xFF072654),
            weight: FontWeight.w800,
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF04132E), Color(0xFF072654), Color(0xFF0A3B66)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNavy.withOpacity(0.35),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Text(
              '💧 SATNA’S TRUSTED HOME SERVICES',
              style: _body(
                11,
                color: Colors.white,
                weight: FontWeight.w800,
              ).copyWith(letterSpacing: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              style: _head(36, color: Colors.white),
              children: [
                const TextSpan(text: 'Clean tank. '),
                TextSpan(
                  text: 'Clean water. ',
                  style: _head(36, color: AppGradients.cyan),
                ),
                const TextSpan(text: 'Healthy home.'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Professional, hygienic water tank cleaning, plus solar panel cleaning and repair, with transparent pricing and doorstep service. Book in under two minutes.',
            style: _body(14, color: const Color(0xFFC5D6EE), height: 1.55),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go(AppRoutes.bookingScreen),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tealAccent,
                foregroundColor: const Color(0xFF04202A),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Book a cleaning →',
                style: _body(
                  15,
                  color: const Color(0xFF04202A),
                  weight: FontWeight.w800,
                ),
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
                style: _body(
                  15,
                  color: Colors.white,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Same photo as the website hero (falls back to the animated tank).
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: const Color(0xFF0B2A52)),
                  _webImage(8, fallback: _tankArt()),
                  _badge('Starting ₹1,000', at: Alignment.topLeft),
                  _badge('Fixed, upfront pricing', at: Alignment.bottomRight),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
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
                    12.5,
                    color: const Color(0xFFA9C0E2),
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

class _TankPainter extends CustomPainter {
  final double t;
  _TankPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final water = r * 0.64;

    canvas.drawCircle(
      c,
      r * 0.95,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF22D3EE).withOpacity(0.18),
    );
    canvas.drawCircle(c, r * 0.825, Paint()..color = const Color(0xFF0B2A52));
    canvas.drawCircle(
      c,
      r * 0.825,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.05
        ..color = const Color(0xFF1D4F86),
    );
    canvas.drawCircle(
      c,
      water,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF67E8F9), Color(0xFF0E9AA8)],
        ).createShader(Rect.fromCircle(center: c, radius: water)),
    );

    for (final o in const [0.0, 0.5]) {
      final p = (t + o) % 1.0;
      canvas.drawCircle(
        c,
        water * (0.3 + 0.7 * p),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withOpacity((1 - p) * 0.8),
      );
    }

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(t * 2 * math.pi);
    final sweep = Path()
      ..moveTo(0, 0)
      ..lineTo(0, -water)
      ..arcTo(
        Rect.fromCircle(center: Offset.zero, radius: water),
        -math.pi / 2,
        math.pi / 2,
        false,
      )
      ..close();
    canvas.drawPath(sweep, Paint()..color = Colors.white.withOpacity(0.22));
    canvas.restore();

    canvas.drawCircle(
      c,
      water,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withOpacity(0.5),
    );
    final dot = Paint()..color = const Color(0xFF22D3EE);
    for (final o in [
      Offset(0, -r * 0.915),
      Offset(r * 0.915, 0),
      Offset(0, r * 0.915),
      Offset(-r * 0.915, 0),
    ]) {
      canvas.drawCircle(c + o, r * 0.045, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _TankPainter old) => old.t != t;
}

// --------------------------------------------------------------- stats

class HomeWebStats extends StatelessWidget {
  const HomeWebStats({super.key});

  @override
  Widget build(BuildContext context) {
    Widget row(Widget a, Widget b) => Row(
      children: [
        Expanded(child: a),
        const SizedBox(width: 12),
        Expanded(child: b),
      ],
    );
    return Column(
      children: [
        row(
          const _Stat(prefix: '₹', value: 1000, label: 'Starting price'),
          const _Stat(value: 5, label: 'Tank sizes'),
        ),
        const SizedBox(height: 12),
        row(
          const _Stat(value: 2, suffix: ' hr', label: 'Pick your time slot'),
          const _Stat(prefix: '₹', value: 500, label: 'Off on 3+ tanks'),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String prefix;
  final String suffix;
  final int value;
  final String label;
  const _Stat({
    this.prefix = '',
    this.suffix = '',
    required this.value,
    required this.label,
  });

  static String _fmt(int n) => n >= 1000
      ? '${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}'
      : '$n';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: _card(),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text(
              '$prefix${_fmt(v.round())}$suffix',
              style: _head(28, color: AppTheme.tealAccent),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: _body(12)),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ services

class HomeWebServices extends StatefulWidget {
  const HomeWebServices({super.key});

  @override
  State<HomeWebServices> createState() => _HomeWebServicesState();
}

class _HomeWebServicesState extends State<HomeWebServices> {
  late Future<List<Map<String, dynamic>>> _f = _load();

  Future<List<Map<String, dynamic>>> _load() async {
    try {
      final data = await SupabaseService.instance.client
          .from('services')
          .select()
          .order('price', ascending: true);
      return (data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static BookingMode _modeFor(String text) {
    final t = text.toLowerCase();
    if (t.contains('repair') || t.contains('maintenance')) {
      return BookingMode.repair;
    }
    if (t.contains('solar')) return BookingMode.solar;
    return BookingMode.water;
  }

  /// Same picture the website puts on each service card:
  /// tank cleaning = 10, solar panel cleaning = 9, other solar (repair) = 7.
  static int _imageFor(String title, String category) {
    final t = '$title $category'.toLowerCase();
    final solar = t.contains('solar');
    if (solar) {
      final cleaning = t.contains('cleaning') &&
          !t.contains('maintenance') &&
          !t.contains('repair');
      return cleaning ? 9 : 7;
    }
    return 10;
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: homeServicesKey,
      child: Column(
        children: [
          _sectionHead(
            'Complete care for your water and solar systems',
            'Book trusted, professionally handled services online, with clear pricing and secure payment.',
            kicker: 'OUR SERVICES',
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _f,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return Column(
                  children: List.generate(
                    3,
                    (_) => Container(
                      height: 260,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: _card(),
                    ),
                  ),
                );
              }
              final list = snap.data ?? const [];
              if (list.isEmpty) {
                // Offline / empty: fall back to the built-in service cards.
                return const HomeServicesWidget();
              }
              return Column(
                children: [
                  for (final s in list) _serviceCard(context, s),
                  const SizedBox(height: 6),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 18,
                    runSpacing: 6,
                    children: [
                      for (final t in const [
                        '✔ Fixed, upfront pricing',
                        '✔ Trained technicians',
                        '✔ Secure Razorpay payments',
                        '✔ Doorstep service in Satna',
                      ])
                        Text(t, style: _body(12, weight: FontWeight.w600)),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _serviceCard(BuildContext context, Map<String, dynamic> s) {
    final title = (s['title'] ?? '').toString();
    final category = (s['category'] ?? '').toString();
    final desc = (s['description'] ?? '').toString();
    final price = (s['price'] as num?)?.toInt() ?? 0;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Container(
              color: const Color(0xFF0B2A52),
              child: _webImage(_imageFor(title, category)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (category.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      category,
                      style: _body(
                        11,
                        color: AppTheme.success,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Text(title, style: _head(19)),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(desc, style: _body(13, height: 1.5)),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text('from ', style: _body(12)),
                    Text(
                      '₹${_Stat._fmt(price)}',
                      style: _head(24, color: AppTheme.tealAccent),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        SolarCart.instance.setMode(
                          _modeFor('$title $category'),
                        );
                        context.go(AppRoutes.bookingScreen);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.tealAccent,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Book now',
                        style: _body(
                          13,
                          color: Colors.white,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------- how it works

class HomeWebHowItWorks extends StatelessWidget {
  const HomeWebHowItWorks({super.key});

  static const _steps = [
    ['Choose', 'Pick your tank size and quantity.'],
    ['Schedule', 'Select a date and 2-hour time slot.'],
    ['Pay securely', 'Pay online with UPI, card or netbanking.'],
    ['We clean', 'Our trained team arrives and cleans.'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _sectionHead(
          'How it works',
          'Four simple steps from tap to sparkling tank.',
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < _steps.length; i++)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: _card(),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.tealAccent, AppGradients.cyan],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: _body(
                      16,
                      color: const Color(0xFF04202A),
                      weight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _steps[i][0],
                        style: _body(
                          15,
                          color: AppTheme.textPrimary,
                          weight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(_steps[i][1], style: _body(13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ----------------------------------------------------------------- why

class HomeWebWhy extends StatelessWidget {
  const HomeWebWhy({super.key});

  static const _items = [
    ['🧪', 'Eco-friendly, food-grade agents', 'Safe for drinking water storage and your family.'],
    ['💰', 'Transparent pricing', 'Fixed price per tank size. What you see is what you pay.'],
    ['📅', 'Same-day & scheduled slots', 'Pick the date and time that suits you.'],
    ['🛡️', 'Trained professionals', 'Careful, hygienic cleaning at your doorstep.'],
    ['🪙', 'Rewards wallet', 'Earn coins on signup and reviews, redeem on bookings.'],
    ['📍', 'Local to Satna', 'A neighbourhood team, quick to reach you.'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _sectionHead(
          'Why families choose Homaclo',
          'Simple, safe and fully transparent.',
        ),
        const SizedBox(height: 16),
        for (final it in _items)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: _card(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(it[0], style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        it[1],
                        style: _body(
                          15,
                          color: AppTheme.textPrimary,
                          weight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(it[2], style: _body(13, height: 1.45)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// --------------------------------------------------------------- story

/// "How we keep your water safe": the website's four photo rows.
class HomeWebStory extends StatelessWidget {
  const HomeWebStory({super.key});

  static const _rows = <Map<String, Object>>[
    {
      'n': 2,
      'title': 'Trained, uniformed professionals',
      'text':
          'Every visit is handled by a uniformed Homaclo technician with gloves and proper gear, so your tank is cleaned carefully and hygienically.',
      'points': [
        'Careful, step-by-step cleaning',
        'Safety gear on every job',
        'Respectful of your home',
      ],
    },
    {
      'n': 3,
      'title': 'Professional equipment, no shortcuts',
      'text':
          'High-pressure washer, wet-and-dry vacuum, cleaning agents, boots, gloves and a safety harness all arrive with the team.',
      'points': [
        'High-pressure washing',
        'Sludge vacuum removal',
        'Safety-first rooftop work',
      ],
    },
    {
      'n': 5,
      'title': 'Tested after cleaning',
      'text':
          'We check your water with a TDS meter after the clean, so you can see the result and not just take our word for it.',
      'points': [
        'TDS meter reading shown',
        'Clean, clear sample',
        'Transparent process',
      ],
    },
    {
      'n': 6,
      'title': 'A tank you can trust again',
      'text':
          'Scrubbed walls, flushed pipes and fresh water, ready to store safe drinking water for your family.',
      'points': [
        'Spotless inner walls',
        'Clean inlet and outlet pipes',
        'Fresh-water ready',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _sectionHead(
          'How we keep your water safe',
          'Real people, real tools, a result you can see.',
        ),
        const SizedBox(height: 16),
        for (final r in _rows)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            clipBehavior: Clip.antiAlias,
            decoration: _card(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Container(
                    color: const Color(0xFF0B2A52),
                    child: _webImage(r['n'] as int),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r['title'] as String, style: _head(19)),
                      const SizedBox(height: 8),
                      Text(r['text'] as String, style: _body(13, height: 1.55)),
                      const SizedBox(height: 12),
                      for (final p in r['points'] as List<String>)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '✓ ',
                                style: _body(
                                  13,
                                  color: AppTheme.tealAccent,
                                  weight: FontWeight.w800,
                                ),
                              ),
                              Expanded(child: Text(p, style: _body(13))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ------------------------------------------------------------- reviews

class HomeWebReviews extends StatefulWidget {
  const HomeWebReviews({super.key});

  @override
  State<HomeWebReviews> createState() => _HomeWebReviewsState();
}

class _HomeWebReviewsState extends State<HomeWebReviews> {
  late final Future<List<Map<String, dynamic>>> _f = _load();

  Future<List<Map<String, dynamic>>> _load() async {
    try {
      final data = await SupabaseService.instance.client
          .from('reviews')
          .select()
          .eq('is_approved', true)
          .order('created_at', ascending: false)
          .limit(3);
      return (data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static const _colors = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFEC4899),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFF0D9488),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _sectionHead('What customers say', 'Real reviews from Satna homes.'),
        const SizedBox(height: 16),
        // Same family photo the website shows above the reviews.
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          clipBehavior: Clip.antiAlias,
          decoration: _card(),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Container(
                  color: const Color(0xFF0B2A52),
                  child: _webImage(1),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 26, 16, 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                  child: Text(
                    'Clean water for the people you love',
                    style: _body(
                      13,
                      color: Colors.white,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _f,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return Container(height: 110, decoration: _card());
            }
            final list = snap.data ?? const [];
            if (list.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: _card(),
                child: Text(
                  'Be the first to review after your cleaning.',
                  textAlign: TextAlign.center,
                  style: _body(13),
                ),
              );
            }
            return Column(children: [for (final r in list) _card1(r)]);
          },
        ),
      ],
    );
  }

  Widget _card1(Map<String, dynamic> r) {
    final name = ((r['user_name'] ?? '') as String).trim().isEmpty
        ? 'Customer'
        : (r['user_name'] as String).trim();
    final rating = ((r['rating'] as num?)?.round() ?? 5).clamp(1, 5);
    final text = (r['review_text'] ?? '').toString();
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: _colors[name.codeUnitAt(0) % _colors.length],
                child: Text(
                  initials,
                  style: _body(
                    14,
                    color: Colors.white,
                    weight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: _body(
                        14,
                        color: AppTheme.textPrimary,
                        weight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '★' * rating + '☆' * (5 - rating),
                      style: const TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 13,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('“$text”', style: _body(13, height: 1.55)),
          const SizedBox(height: 10),
          Text(
            '✔ Verified Satna customer',
            style: _body(
              11.5,
              color: AppTheme.success,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- cta

class HomeWebCta extends StatelessWidget {
  const HomeWebCta({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF072654), Color(0xFF0A3B66)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Ready for cleaner water?',
            textAlign: TextAlign.center,
            style: _head(26, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            'New here? Sign up and get 50 bonus coins plus ₹100 off with code WEL100 on your first booking.',
            textAlign: TextAlign.center,
            style: _body(13.5, color: const Color(0xFFC5D6EE), height: 1.5),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.bookingScreen),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tealAccent,
              foregroundColor: const Color(0xFF04202A),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Book now',
              style: _body(
                15,
                color: const Color(0xFF04202A),
                weight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
