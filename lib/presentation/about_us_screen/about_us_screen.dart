import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart'; 
import '../../theme/app_theme.dart';
import '../../widgets/maintix_logo.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryNavy,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          title: Text(
            'About Us',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryNavy, Color(0xFF1A3F5C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const MaintixLogo(
                        // Square (equal width/height), medium size.
                        width: 110,
                        height: 110,
                        borderRadius: 18,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Trusted Water Tank Cleaning Services',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.white.withAlpha(178),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Mission
                _sectionCard(
                  icon: Icons.flag_rounded,
                  iconColor: AppTheme.tealAccent,
                  title: 'Our Mission',
                  content:
                      'At Homaclo, our mission is to deliver safe, hygienic, and affordable water tank cleaning services to every household and business. We believe clean water storage is a fundamental right, not a luxury — and we\'re here to make it accessible to all.',
                ),
                const SizedBox(height: 16),

                // Vision
                _sectionCard(
                  icon: Icons.visibility_rounded,
                  iconColor: const Color(0xFF6C63FF),
                  title: 'Our Vision',
                  content:
                      'We envision a future where every family in India has access to professionally maintained water storage systems. By 2030, Homaclo aims to serve 1 million households across Madhya Pradesh and beyond, setting the gold standard for home maintenance services.',
                ),
                const SizedBox(height: 16),

                // Why Homaclo
                _sectionCard(
                  icon: Icons.star_rounded,
                  iconColor: AppTheme.warning,
                  title: 'Why Choose Homaclo?',
                  content: null,
                  children: [
                    _bulletPoint(
                      '✅ Certified & trained cleaning professionals',
                    ),
                    _bulletPoint('✅ Eco-friendly, food-grade cleaning agents'),
                    _bulletPoint('✅ Transparent pricing — no hidden charges'),
                    _bulletPoint('✅ Same-day & scheduled booking options'),
                    _bulletPoint(
                      '✅ 100% satisfaction guarantee on every service',
                    ),
                    _bulletPoint('✅ Real-time booking tracking & updates'),
                  ],
                ),
                const SizedBox(height: 16),

                // Services
                _sectionCard(
                  icon: Icons.cleaning_services_rounded,
                  iconColor: AppTheme.success,
                  title: 'Our Services',
                  content: null,
                  children: [
                    _serviceChip('500L Tank Cleaning', '₹1,000'),
                    _serviceChip('750L Tank Cleaning', '₹1,500'),
                    _serviceChip('1000L Tank Cleaning', '₹1,800'),
                    _serviceChip('1500L Tank Cleaning', '₹2,000'),
                    _serviceChip('2000L Tank Cleaning', '₹2,500'),
                  ],
                ),
                const SizedBox(height: 16),

                // Company Info
                Container(
                  padding: const EdgeInsets.all(20),
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
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryNavy.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.business_rounded,
                              color: AppTheme.primaryNavy,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Company Details',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _infoRow(
                        Icons.location_on_rounded,
                        'Headquarters',
                        'Satna, Madhya Pradesh, India',
                      ),
                      const SizedBox(height: 10),
                      _infoRow(
                        Icons.email_rounded,
                        'Email',
                        'maintix.help@gmail.com',
                      ),
                      const SizedBox(height: 10),
                      _infoRow(Icons.phone_rounded, 'Phone', '+91 62622 62913'),
                      const SizedBox(height: 10),
                      _infoRow(Icons.calendar_today_rounded, 'Founded', '2024'),
                      const SizedBox(height: 10),
                      _infoRow(
                        Icons.verified_rounded,
                        'Version',
                        'Homaclo App v1.0.0 (2026)',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? content,
    List<Widget>? children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (content != null)
            Text(
              content,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
            ),
          if (children != null) ...children,
        ],
      ),
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: AppTheme.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _serviceChip(String name, String price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.water_drop_rounded,
                color: AppTheme.tealAccent,
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          Text(
            price,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryNavy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.tealAccent, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
