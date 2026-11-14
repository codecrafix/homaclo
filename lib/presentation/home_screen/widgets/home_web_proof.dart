import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

/// "Real work proof" section of the Homaclo website home page: the drag
/// slider (muddy tank before, hygienic tank after) plus the two cards
/// "Dirty water risks" and "Clean water benefits".
/// Uses the same photos as the website (homaclo.in/img/before.png, after.png).
const String _imgBase = 'https://homaclo.in/img/';

class HomeWebProof extends StatefulWidget {
  const HomeWebProof({super.key});

  @override
  State<HomeWebProof> createState() => _HomeWebProofState();
}

class _HomeWebProofState extends State<HomeWebProof> {
  double _p = 0.5;

  static const _risks = [
    'Hair fall and scalp damage from minerals and bacteria',
    'Skin allergies and rashes',
    'Typhoid, jaundice and stomach illness risk',
    'Bad odour and limescale on taps',
  ];
  static const _benefits = [
    'Healthier hair and skin',
    'Safe, bacteria-free drinking water',
    'Longer plumbing life, less clogging',
    'Fresh taste, zero foul odour',
  ];

  TextStyle _head(double size) => GoogleFonts.fraunces(
    fontSize: size,
    fontWeight: FontWeight.w700,
    height: 1.15,
    color: AppTheme.textPrimary,
  );

  TextStyle _body(double size, {Color? color, FontWeight? w}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: w ?? FontWeight.w500,
        height: 1.45,
        color: color ?? AppTheme.textSecondary,
      );

  Widget _photo(String file) => Image.network(
    '$_imgBase$file',
    fit: BoxFit.cover,
    width: double.infinity,
    height: double.infinity,
    gaplessPlayback: true,
    errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0B2A52)),
  );

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.9),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: _body(11, color: Colors.white, w: FontWeight.w800),
    ),
  );

  Widget _slider() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final h = c.maxHeight;
            void setFrom(double dx) =>
                setState(() => _p = (dx / w).clamp(0.0, 1.0));
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => setFrom(d.localPosition.dx),
              onHorizontalDragStart: (d) => setFrom(d.localPosition.dx),
              onHorizontalDragUpdate: (d) => setFrom(d.localPosition.dx),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: const Color(0xFF0B2A52)),
                  _photo('after.png'),
                  ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: _p,
                      child: SizedBox(
                        width: w,
                        height: h,
                        child: _photo('before.png'),
                      ),
                    ),
                  ),
                  Positioned(
                    left: w * _p - 1.5,
                    top: 0,
                    bottom: 0,
                    width: 3,
                    child: const ColoredBox(color: Colors.white),
                  ),
                  Positioned(
                    left: w * _p - 21,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.compare_arrows_rounded,
                          color: Color(0xFF072654),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _tag('BEFORE', AppTheme.error),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _tag('AFTER ✨', AppTheme.success),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _listCard(String title, List<String> items, String mark, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _body(15, color: color, w: FontWeight.w800)),
          const SizedBox(height: 10),
          for (final t in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$mark ',
                    style: _body(13, color: color, w: FontWeight.w800),
                  ),
                  Expanded(child: Text(t, style: _body(13))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Real work proof', textAlign: TextAlign.center, style: _head(24)),
        const SizedBox(height: 8),
        Text(
          'Drag the slider: muddy tank before, hygienic tank after.',
          textAlign: TextAlign.center,
          style: _body(13),
        ),
        const SizedBox(height: 16),
        _slider(),
        const SizedBox(height: 32),
        Text(
          'Why tank cleaning matters',
          textAlign: TextAlign.center,
          style: _head(22),
        ),
        const SizedBox(height: 16),
        _listCard('✕ Dirty water risks', _risks, '✕', AppTheme.error),
        const SizedBox(height: 12),
        _listCard('✓ Clean water benefits', _benefits, '✓', AppTheme.success),
      ],
    );
  }
}
