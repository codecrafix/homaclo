import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/solar_cart.dart';
import '../../../theme/app_theme.dart';

/// Step 1 (solar): system size dropdown + number of panels (typed or +/-),
/// ₹100 per panel, minimum 5 panels — same as the website.
class SolarStep1Widget extends StatefulWidget {
  final VoidCallback onNext;
  const SolarStep1Widget({required this.onNext, super.key});

  @override
  State<SolarStep1Widget> createState() => _SolarStep1WidgetState();
}

class _SolarStep1WidgetState extends State<SolarStep1Widget> {
  final SolarCart _cart = SolarCart.instance;
  late final TextEditingController _c;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: _cart.panels == 0 ? '' : '${_cart.panels}');
    _cart.addListener(_sync);
  }

  void _sync() {
    if (int.tryParse(_c.text) != _cart.panels && mounted) {
      final t = _cart.panels == 0 ? '' : '${_cart.panels}';
      _c.value = TextEditingValue(
        text: t,
        selection: TextSelection.collapsed(offset: t.length),
      );
    }
  }

  @override
  void dispose() {
    _cart.removeListener(_sync);
    _c.dispose();
    super.dispose();
  }

  String _inr(int n) {
    final s = n.toString();
    if (s.length <= 3) return '₹$s';
    final head = s.substring(0, s.length - 3);
    final withCommas = head.replaceAllMapped(
      RegExp(r'\B(?=(\d{2})+(?!\d))'),
      (m) => ',',
    );
    return '₹$withCommas,${s.substring(s.length - 3)}';
  }

  Widget _stepBtn(IconData icon, bool primary, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: primary ? AppTheme.tealAccent : AppTheme.primaryNavy,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _cart,
      builder: (context, _) {
        final ready = _cart.panelsReady;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Solar Panel Cleaning',
                style: GoogleFonts.fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose your system size, then add the number of panels (₹${SolarCart.pricePerPanel} per panel, minimum ${SolarCart.minPanels} panels). You can also type the number.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 1.45,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Solar system size',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _cart.kw,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceWhite,
                    items: SolarCart.kwOptions
                        .map(
                          (k) => DropdownMenuItem(
                            value: k,
                            child: Text(
                              '$k kW',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) _cart.setKw(v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ready
                      ? AppTheme.tealAccent.withAlpha(20)
                      : AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: ready ? AppTheme.tealAccent : AppTheme.divider,
                    width: ready ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withAlpha(30),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text('☀️', style: TextStyle(fontSize: 26)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Number of panels',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '₹${SolarCart.pricePerPanel} / panel',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.tealAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _stepBtn(Icons.remove_rounded, false, () => _cart.changePanels(-1)),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 92,
                    height: 44,
                    child: TextField(
                      controller: _c,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.inputTextColor(context),
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '${SolarCart.minPanels}',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textMuted,
                        ),
                        filled: true,
                        fillColor: AppTheme.inputFillColor(context),
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.tealAccent,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (v) => _cart.setPanels(int.tryParse(v) ?? 0),
                      // Leaving the field with fewer than the minimum: raise it.
                      onEditingComplete: () {
                        if (_cart.panels > 0 && _cart.panels < SolarCart.minPanels) {
                          _cart.setPanels(SolarCart.minPanels);
                        }
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  _stepBtn(Icons.add_rounded, true, () => _cart.changePanels(1)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Minimum ${SolarCart.minPanels} panels per booking.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: ready ? AppTheme.textSecondary : AppTheme.error,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${_cart.kw}kW • ${_cart.panels} panel${_cart.panels == 1 ? '' : 's'} × ₹${SolarCart.pricePerPanel}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: Colors.white.withAlpha(190),
                            ),
                          ),
                        ),
                        Text(
                          _inr(_cart.panels * SolarCart.pricePerPanel),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Colors.white.withAlpha(190),
                          ),
                        ),
                      ],
                    ),
                    Divider(color: Colors.white.withAlpha(50), height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _inr(_cart.total),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.brandCyan,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: ready
                      ? () {
                          FocusScope.of(context).unfocus();
                          widget.onNext();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tealAccent,
                    disabledBackgroundColor: AppTheme.divider,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Next — Select Date & Time  →',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
