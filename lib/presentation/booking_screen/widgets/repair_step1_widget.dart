import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/solar_cart.dart';
import '../../../theme/app_theme.dart';

/// Step 1 (Solar Maintenance & Repair): problem type + description, flat
/// ₹1,000 service charge — same as the website.
class RepairStep1Widget extends StatefulWidget {
  final VoidCallback onNext;
  const RepairStep1Widget({required this.onNext, super.key});

  @override
  State<RepairStep1Widget> createState() => _RepairStep1WidgetState();
}

class _RepairStep1WidgetState extends State<RepairStep1Widget> {
  final SolarCart _cart = SolarCart.instance;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _note = TextEditingController(text: _cart.repairNote);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _cart,
      builder: (context, _) {
        final ready = _cart.repairReady;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Solar maintenance & repair',
                style: GoogleFonts.fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tell us what is wrong with your solar system. Service charge: ₹${SolarCart.repairPrice}.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 1.45,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'What is the problem related to?',
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
                  child: DropdownButton<String>(
                    value: _cart.repairCategory.isEmpty ? null : _cart.repairCategory,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceWhite,
                    hint: Text(
                      'Select problem type…',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    items: SolarCart.repairCategories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              c,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) _cart.setRepairCategory(v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Describe the problem',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _note,
                maxLines: 5,
                maxLength: 300,
                onChanged: _cart.setRepairNote,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppTheme.inputTextColor(context),
                ),
                decoration: InputDecoration(
                  hintText:
                      'Explain in detail: since when it is happening, what you see (error / light on inverter, voltage or output reading), etc.',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                  ),
                  filled: true,
                  fillColor: AppTheme.inputFillColor(context),
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
              ),
              Text(
                'First select the problem type, then describe it in your own words. Our technician will check everything on the visit.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  height: 1.5,
                  color: AppTheme.textSecondary,
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
                        Text(
                          'Solar maintenance & repair',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Colors.white.withAlpha(190),
                          ),
                        ),
                        Text(
                          '₹${SolarCart.repairPrice}',
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
                          '₹${SolarCart.repairPrice}',
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
