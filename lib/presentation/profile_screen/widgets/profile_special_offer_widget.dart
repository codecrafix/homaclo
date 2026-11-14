import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../routes/app_routes.dart';
import '../../../widgets/premium_ui.dart';

/// Special Offer promo card shown right below the Active Offer card.
/// Tapping it takes the user to the Booking tab. Flat (no light sheen / glow).
class ProfileSpecialOfferWidget extends StatelessWidget {
  const ProfileSpecialOfferWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const radius = 22.0;

    return TapScale(
      onTap: () {
        HapticFeedback.selectionClick();
        // Booking is a bottom-nav tab, so go() switches to that tab.
        context.go(AppRoutes.bookingScreen);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D9488), Color(0xFF0A2540)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(38),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.local_offer_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Special Offer 🎉',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '₹500 Flat Discount on 3 Tank Cleaning Bookings!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white.withAlpha(230),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF0D9488),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
