import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/supabase_service.dart';
import '../../../theme/app_theme.dart';

class ProfileAdWidget extends StatefulWidget {
  const ProfileAdWidget({super.key});

  @override
  State<ProfileAdWidget> createState() => _ProfileAdWidgetState();
}

class _ProfileAdWidgetState extends State<ProfileAdWidget> {
  Map<String, dynamic>? _coupon;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCoupon();
  }

  Future<void> _loadCoupon() async {
    try {
      final coupon = await SupabaseService.instance.fetchActiveFeaturedCoupon();
      if (mounted) {
        setState(() {
          _coupon = coupon;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _copyCoupon(String code) {
    Clipboard.setData(ClipboardData(text: code));
    Fluttertoast.showToast(
      msg: 'Coupon "$code" copied!',
      backgroundColor: AppTheme.tealAccent,
      textColor: Colors.white,
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 90,
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_coupon == null) return const SizedBox.shrink();

    final code = _coupon!['code'] as String? ?? '';
    final discountAmount = _coupon!['discount_amount'] as int? ?? 0;
    final description = _coupon!['description'] as String?;
    final expiresAt = _coupon!['expires_at'] as String?;

    String expiryText = '';
    if (expiresAt != null) {
      final expiry = DateTime.tryParse(expiresAt);
      if (expiry != null) {
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        expiryText =
            'Valid till ${expiry.day} ${months[expiry.month - 1]} ${expiry.year}';
      }
    }

    // Flat card: no decorative light circles / glow.
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(38),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🎁', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Offer',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withAlpha(179),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    discountAmount > 0
                        ? '₹$discountAmount OFF'
                        : description ?? 'Special Discount',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  if (description != null && discountAmount > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.white.withAlpha(179),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (expiryText.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      expiryText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: Colors.white.withAlpha(153),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _copyCoupon(code),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      code,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0D9488),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.copy_rounded,
                          size: 10,
                          color: const Color(0xFF0D9488).withAlpha(179),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'COPY',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0D9488).withAlpha(179),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
