import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/maintix_logo.dart';

class HomeContactFooterWidget extends StatelessWidget {
  const HomeContactFooterWidget({super.key});

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse(
      'https://wa.me/916262262913?text=Hi%20Homaclo%2C%20I%20need%20help',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openInstagram() async {
    final uri = Uri.parse('https://instagram.com/maintix.in');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryNavy, AppTheme.headerAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // New Homaclo logo — vector, rounded square (sharp at any size).
              const MaintixLogo(
                width: 64,
                height: 64,
                borderRadius: 14,
                fit: BoxFit.cover,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Us',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '🛡️ 100% Secure & Verified Service',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.white.withAlpha(179),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow(Icons.location_on_rounded, 'Satna, Madhya Pradesh — 485001'),
          const SizedBox(height: 8),
          _infoRow(Icons.email_rounded, 'maintix.help@gmail.com'),
          const SizedBox(height: 8),
          _infoRow(Icons.access_time_rounded, 'Mon–Sat: 8:00 AM – 6:00 PM'),
          const SizedBox(height: 12),
          // Instagram follow button
          GestureDetector(
            onTap: _openInstagram,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFE1306C),
                    Color(0xFFF77737),
                    Color(0xFF833AB4),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Follow us on Instagram',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '@maintix.in',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.white.withAlpha(204),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // WhatsApp button (full width now)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openWhatsApp,
              icon: const Icon(
                Icons.chat_rounded,
                size: 16,
                color: Colors.white,
              ),
              label: Text(
                'WhatsApp',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '© 2026 Homaclo. All Rights Reserved.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.white.withAlpha(115),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.tealAccent, size: 14),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: Colors.white.withAlpha(191),
          ),
        ),
      ],
    );
  }
}
