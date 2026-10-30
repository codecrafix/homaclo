import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/solar_cart.dart';

class SolarStep1Widget extends StatelessWidget {
  final VoidCallback onNext;
  const SolarStep1Widget({required this.onNext, super.key});

  String _fmt(int p) {
    final s = p.toString();
    if (s.length > 3) {
      return '₹${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
    }
    return '₹$s';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SolarCart.instance,
      builder: (context, _) {
        final s = SolarCart.instance;
        final ready = s.panels > 0;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Solar Panel Cleaning',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select system size & number of panels (₹100 per panel)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'SOLAR SYSTEM SIZE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: s.kw,
                dropdownColor: AppTheme.surfaceWhite,
                isExpanded: true,
                menuMaxHeight: 320,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.surfaceWhite,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  prefixIcon: Icon(
                    Icons.solar_power_rounded,
                    color: AppTheme.warning,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppTheme.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppTheme.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppTheme.tealAccent, width: 1.5),
                  ),
                ),
                items: SolarCart.kwOptions
                    .map(
                      (k) => DropdownMenuItem<int>(
                        value: k,
                        child: Text(
                          '$k kW',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) s.setKw(v);
                },
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ready ? AppTheme.tealAccent : AppTheme.divider,
                    width: ready ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.cardShadow,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withAlpha(26),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.wb_sunny_rounded,
                        color: AppTheme.warning,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Number of Panels',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_fmt(SolarCart.pricePerPanel)} per panel',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.tealAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _btn(Icons.remove_rounded, s.panels > 0 ? () => s.changePanels(-1) : null),
                    SizedBox(
                      width: 40,
                      child: Center(
                        child: Text(
                          '${s.panels}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: ready ? AppTheme.tealAccent : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                    _btn(Icons.add_rounded, s.panels < SolarCart.maxPanels ? () => s.changePanels(1) : null, add: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    if (ready) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${s.kw}kW • ${s.panels} panel${s.panels == 1 ? '' : 's'} × ${_fmt(SolarCart.pricePerPanel)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: Colors.white.withAlpha(179),
                            ),
                          ),
                          Text(
                            _fmt(s.total),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: Colors.white.withAlpha(179),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 16),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          ready ? _fmt(s.total) : '₹0',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.tealAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: ready ? onNext : null,
                child: Container(
                  width: double.infinity,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ready ? AppTheme.tealAccent : AppTheme.divider,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Next — Select Date & Time',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: ready ? Colors.white : AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: ready ? Colors.white : AppTheme.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _btn(IconData icon, VoidCallback? onTap, {bool add = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap == null
              ? AppTheme.divider
              : (add ? AppTheme.tealAccent : AppTheme.primaryNavy),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}
