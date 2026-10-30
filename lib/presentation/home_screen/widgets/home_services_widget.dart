import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../../../services/solar_cart.dart';

class HomeServicesWidget extends StatelessWidget {
  const HomeServicesWidget({super.key});

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse(
      'https://wa.me/916262262913?text=Hi%20Homaclo%2C%20I%20want%20to%20enquire%20about%20Solar%20Maintenance',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Our Services',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'Tap a service to get started',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Water Tank Cleaning
        _ServiceCard(
          icon: Icons.water_drop_rounded,
          iconColor: AppTheme.tealAccent,
          iconBg: AppTheme.tealLight,
          title: 'Water Tank Cleaning',
          subtitle: '500L — 2000L • Starting ₹1,000',
          features: const ['5-Stage Clean', 'TDS Tested', 'Certified'],
          buttonLabel: 'Book Now',
          buttonColor: AppTheme.tealAccent,
          onTap: () {
            SolarCart.instance.setSolar(false);
            context.go(AppRoutes.bookingScreen);
          },
        ),
        const SizedBox(height: 12),
        // Solar Maintenance
        _ServiceCard(
          icon: Icons.solar_power_rounded,
          iconColor: AppTheme.warning,
          iconBg: AppTheme.warning.withAlpha(26),
          title: 'Solar Maintenance & Repair',
          subtitle: 'Inverter check, wiring & panel repair',
          features: const [],
          buttonLabel: 'Enquire on WhatsApp',
          buttonColor: const Color(0xFF25D366),
          onTap: _openWhatsApp,
        ),
        const SizedBox(height: 12),
        // Solar Panel Cleaning — now ACTIVE
        _ServiceCard(
          icon: Icons.wb_sunny_rounded,
          iconColor: AppTheme.warning,
          iconBg: AppTheme.warning.withAlpha(26),
          title: 'Solar Panel Cleaning',
          subtitle: '3kW — 30kW • ₹100 per panel',
          features: const ['Dust & Grime Removal', 'Any System Size'],
          buttonLabel: 'Book Now',
          buttonColor: AppTheme.tealAccent,
          onTap: () {
            SolarCart.instance.setSolar(true);
            context.go(AppRoutes.bookingScreen);
          },
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final List<String> features;
  final String buttonLabel;
  final Color buttonColor;
  final VoidCallback? onTap;
  final String? badge;

  const _ServiceCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.features,
    required this.buttonLabel,
    required this.buttonColor,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border(
          left: BorderSide(color: iconColor.withAlpha(153), width: 3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.divider,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (features.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: features
                        .map(
                          (f) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.tealLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              f,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.tealAccent,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: onTap != null
                          ? buttonColor
                          : AppTheme.divider,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      buttonLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: onTap != null
                            ? Colors.white
                            : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
