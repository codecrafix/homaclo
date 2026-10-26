import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
            'Terms & Conditions',
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
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryNavy, Color(0xFF1A3F5C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.article_rounded,
                        color: AppTheme.tealAccent,
                        size: 32,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Terms & Conditions',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Effective: January 1, 2026 · Homaclo Service Agreement',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white.withAlpha(153),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                _termsSection(
                  '1. Acceptance of Terms',
                  'By downloading, installing, or using the Homaclo mobile application ("App"), you agree to be bound by these Terms & Conditions ("Terms"). These Terms constitute a legally binding agreement between you ("User") and Homaclo ("Company"). If you do not agree to these Terms, do not use the App or our services.',
                ),

                _termsSection(
                  '2. Service Description',
                  'Homaclo provides professional water tank cleaning and maintenance services. Our services include:\n\n• Overhead water tank cleaning (500L – 2000L capacity)\n• Underground sump cleaning\n• Tank disinfection and sanitization\n• Post-cleaning water quality inspection\n\nAll services are performed by trained and verified Homaclo technicians.',
                ),

                _termsSection(
                  '3. Booking & Scheduling',
                  null,
                  children: [
                    _bulletList([
                      'Bookings must be made at least 24 hours in advance',
                      'Service slots are subject to availability in your area',
                      'You will receive a booking confirmation via the app',
                      'Our team will contact you 1–2 hours before the scheduled service',
                      'Please ensure water access and tank accessibility at the time of service',
                      'Bookings are confirmed only after successful submission in the app',
                    ]),
                  ],
                ),

                _termsSection(
                  '4. Cancellation Policy',
                  null,
                  children: [
                    _highlightBox('🚫 Bookings are non-cancellable', AppTheme.warning),
                    const SizedBox(height: 10),
                    _bulletList([
                      'All service requests (including Tank Cleaning, Solar Maintenance, and Home Services) submitted through the Homaclo app are final once confirmed',
                      'Once a booking is confirmed, you must allow the assigned technician to carry out the service',
                      'Cancellation or refund requests due to change of mind are not entertained',
                      'If Homaclo is unable to deliver the scheduled service, you are eligible for a refund — see the Refund Policy below and section 10 of our Privacy & Refund Policy',
                    ]),
                  ],
                ),

                _termsSection(
                  '5. Payment Policy',
                  null,
                  children: [
                    _subSection('Accepted Payment Methods', [
                      '• Online Payment — Pay securely via Razorpay using UPI, debit/credit card or netbanking',
                      '• Reward Coins — Earn 10 coins per review; redeem for discounts on future bookings',
                    ]),
                    _subSection('Pricing & Taxes', [
                      '• All prices listed in the app are inclusive of applicable GST',
                      '• Prices are fixed and transparent — no hidden charges',
                      '• Special discounts may apply during promotional periods',
                      '• Price revisions, if any, will be communicated 30 days in advance',
                    ]),
                    _subSection('Refund Policy', [
                      '• Refunds are issued only when Homaclo is unable to deliver the scheduled service (operational issues, technician unavailability, severe weather, or unforeseen technical failures)',
                      '• An accidental double payment, or money debited without a booking being created, is fully refundable',
                      '• Approved refunds are credited to the original payment source within 5–7 business days',
                      '• Full details: Privacy & Refund Policy, section 10',
                    ]),
                  ],
                ),

                _termsSection(
                  '6. User Responsibilities',
                  null,
                  children: [
                    _bulletList([
                      'Provide accurate address, contact details, and tank specifications',
                      'Ensure safe and unobstructed access to the water tank',
                      'Be present or designate a responsible adult during the service',
                      'Inform us of any special requirements or tank conditions in advance',
                      'Do not misuse the app or submit fraudulent bookings',
                      'Treat our service technicians with respect and professionalism',
                      'Report service issues within 24 hours of service completion',
                    ]),
                  ],
                ),

                _termsSection(
                  '7. Service Quality Guarantee',
                  'Homaclo guarantees professional-grade cleaning using food-safe, eco-friendly agents. If you are unsatisfied with the service quality:\n\n• Report within 24 hours via the app or email\n• We will re-inspect and re-service at no additional cost\n• If the issue persists, our support team will review it and resolve it with you\n\nThis guarantee does not cover pre-existing tank damage or structural issues.',
                ),

                _termsSection(
                  '8. Limitation of Liability',
                  'Homaclo shall not be liable for:\n\n• Indirect, incidental, or consequential damages arising from service use\n• Pre-existing damage to tanks, pipes, or water systems\n• Delays caused by factors beyond our control (weather, emergencies)\n• Data loss due to device failure or third-party service outages\n\nOur maximum liability is limited to the amount paid for the specific service in question.',
                ),

                _termsSection(
                  '9. Intellectual Property',
                  'All content within the Homaclo app — including logos, text, graphics, and software — is the exclusive property of Homaclo and protected under Indian copyright law. Unauthorized reproduction, distribution, or modification is strictly prohibited.',
                ),

                _termsSection(
                  '10. Governing Law & Disputes',
                  'These Terms are governed by the laws of India. Any disputes arising from these Terms or our services shall be subject to the exclusive jurisdiction of courts in Satna, Madhya Pradesh, India. We encourage resolution through direct communication before pursuing legal action.',
                ),

                _termsSection(
                  '11. Amendments',
                  'Homaclo reserves the right to modify these Terms at any time. Updated Terms will be posted in the app with a revised effective date. Continued use of the app after changes constitutes acceptance of the new Terms.',
                ),

                _termsSection(
                  '12. Contact',
                  'For questions about these Terms:\n\n📧 maintix.help@gmail.com\n📞 +91 62622 62913\n📍 Satna, Madhya Pradesh, India',
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _termsSection(
    String title,
    String? content, {
    List<Widget>? children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryNavy,
            ),
          ),
          const SizedBox(height: 10),
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

  Widget _subSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              item,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _bulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                item,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _highlightBox(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
