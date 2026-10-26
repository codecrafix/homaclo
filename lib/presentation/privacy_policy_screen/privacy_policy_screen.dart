import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
           'Privacy & Refund Policy',
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
                        Icons.privacy_tip_rounded,
                        color: AppTheme.tealAccent,
                        size: 32,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Privacy & Refund Policy',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last updated: January 1, 2026 · Homaclo v1.0.0',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white.withAlpha(153),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                _policySection(
                  '1. Introduction',
                  'Homaclo ("we", "our", or "us") is committed to protecting your personal information and your right to privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and services. Please read this policy carefully. If you disagree with its terms, please discontinue use of our app.',
                ),

                _policySection(
                  '2. Information We Collect',
                  null,
                  children: [
                    _subSection('Personal Identification Data', [
                      '• Full Name — used to personalize your account and service bookings',
                      '• Phone Number — used for booking confirmations and service updates',
                      '• Email Address — used for account authentication and notifications',
                    ]),
                    _subSection('Location & Service Data', [
                      '• City / Area — used to match you with available service slots',
                      '• Service Address — collected only at booking time for technician dispatch',
                      '• Landmark Details — optional, used to assist our service team',
                    ]),
                    _subSection('Usage & Behavioral Data', [
                      '• App interaction logs (screens visited, features used)',
                      '• Booking history and service preferences',
                      '• Review and rating submissions',
                    ]),
                  ],
                ),

                _policySection(
                  '3. Data Security Standards',
                  null,
                  children: [
                    _subSection('Encryption Practices', [
                      '• All data transmitted between the app and our servers is encrypted using TLS 1.3 (Transport Layer Security)',
                      '• Stored personal data is encrypted at rest using AES-256 encryption',
                      '• Passwords and sensitive credentials are hashed using bcrypt with salt rounds',
                      '• API communications use HTTPS exclusively — no plain HTTP connections',
                    ]),
                    _subSection('Access Controls', [
                      '• Only authorized Homaclo personnel can access user data',
                      '• Role-based access control (RBAC) limits data visibility by job function',
                      '• All data access is logged and audited regularly',
                    ]),
                    _subSection('Infrastructure Security', [
                      '• Data hosted on ISO 27001-certified cloud infrastructure',
                      '• Regular security audits and penetration testing conducted',
                      '• Automated threat detection and intrusion prevention systems active',
                    ]),
                  ],
                ),

                _policySection(
                  '4. How We Use Your Data',
                  null,
                  children: [
                    _bulletList([
                      'To process and confirm your service bookings',
                      'To dispatch and coordinate our cleaning technicians',
                      'To send booking confirmations and service reminders',
                      'To improve app features and user experience',
                      'To calculate and credit loyalty reward coins',
                      'To respond to customer support inquiries',
                      'To comply with applicable legal obligations',
                    ]),
                  ],
                ),

                _policySection(
                  '5. Data Sharing & Third Parties',
                  'We do NOT sell, trade, or rent your personal information to third parties. We may share limited data with:\n\n• Service technicians (name, address, phone) — only for active bookings\n• Payment processors — only transaction amounts, no card data stored by us\n• Legal authorities — only when required by law or court order\n\nAll third-party partners are contractually bound to maintain data confidentiality.',
                ),

                _policySection(
                  '6. Your Privacy Rights',
                  null,
                  children: [
                    _bulletList([
                      '🔍 Right to Access — Request a copy of all data we hold about you',
                      '✏️ Right to Rectification — Correct inaccurate or incomplete data',
                      '🗑️ Right to Erasure — Request deletion of your account and data',
                      '🚫 Right to Object — Opt out of non-essential data processing',
                      '📦 Right to Portability — Receive your data in a portable format',
                      '🔒 Right to Restriction — Limit how we process your data',
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      'To exercise any of these rights, contact us at maintix.help@gmail.com',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppTheme.tealAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                _policySection(
                  '7. Data Retention',
                  'We retain your personal data for as long as your account is active or as needed to provide services. Booking records are retained for 3 years for legal and tax compliance. You may request deletion of your account at any time, after which personal data is purged within 30 days.',
                ),

                _policySection(
                  '8. Children\'s Privacy',
                  'Homaclo services are not directed to individuals under the age of 18. We do not knowingly collect personal information from minors. If we become aware that a child under 18 has provided us with personal data, we will delete it immediately.',
                ),

                _policySection(
                  '9. Changes to This Policy',
                  'We may update this Privacy Policy periodically. We will notify you of significant changes via in-app notification or email. Continued use of the app after changes constitutes acceptance of the updated policy.',
                ),
                _policySection(
                    '10. Cancellation & Refund Policy',
                      '🚫 CANCELLATION POLICY BY CUSTOMER:\n'
                        '• Non-Cancellable Bookings: All service requests (including Tank Cleaning, Solar Maintenance, and Home Services) submitted through the Homaclo application are final.\n'
                          '• Customer Obligations: Once a service booking is confirmed, customers are required to allow the assigned technician to execute the service. Requests for cash refunds or booking cancellations upon customer change of mind will not be entertained.\n\n'
                            '💰 REFUND ELIGIBILITY & CONDITIONS:\n'
                              '• Service Non-Fulfillment: Refunds are strictly issued only under extraordinary circumstances where Homaclo is unable to execute or deliver the scheduled service due to operational issues, technician unavailability, severe weather, or unforeseen technical failures.\n'
                                '• Partial / Failed Transactions: In the event of an accidental double payment or money debited without booking generation, the excess amount is fully eligible for a refund.\n\n'
                                  '⏳ REFUND TIMELINE & PAYMENT MODE:\n'
                                    '• Processing Window: Upon verification of service non-fulfillment by our operations team, the refund process will be initiated immediately.\n'
                                      '• Credit Duration: All approved refunds will be credited back to the customer’s original payment source (Bank Account, Credit/Debit Card, or UPI ID) within 5 to 7 business days (approx. 1 week).\n\n'
                                        '📞 DISPUTES & SUPPORT RESOLUTION:\n'
                                          '• For any refund status tracking, billing discrepancies, or failed transaction queries, please contact our support desk directly with your Booking ID and payment reference number.\n'
                                            '• Official Email: maintix.help@gmail.com\n'
                                              '• Escalation Contact: +91 62622 62913',
                                              ),
                
                _policySection(
                  '11. Contact Us',
                  'For privacy-related questions, data requests, or concerns:\n\n📧 Email: maintix.help@gmail.com\n📞 Phone: +91 62622 62913\n📍 Address: Satna, Madhya Pradesh, India',
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _policySection(
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
                '• $item',
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
}
