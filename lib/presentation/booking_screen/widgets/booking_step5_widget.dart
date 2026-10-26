import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/app_state.dart';
import '../../../routes/app_routes.dart';

class BookingStep5Widget extends StatefulWidget {
  final VoidCallback? onBookAnother;
  const BookingStep5Widget({super.key, this.onBookAnother});

  @override
  State<BookingStep5Widget> createState() => _BookingStep5WidgetState();
}

class _BookingStep5WidgetState extends State<BookingStep5Widget>
    with SingleTickerProviderStateMixin {
  // TODO: Replace with Riverpod/Bloc for production
  late AnimationController _checkController;
  late Animation<double> _checkScale;
  late Animation<double> _checkOpacity;
  late String _bookingId;
  bool _coinsAwarded = false;

  static const Map<String, int> _prices = {
    '500L': 1000,
    '750L': 1500,
    '1000L': 1800,
    '1500L': 2000,
    '2000L': 2500,
  };

  String _formatPrice(int price) {
    final str = price.toString();
    if (str.length > 3) {
      return '₹${str.substring(0, str.length - 3)},${str.substring(str.length - 3)}';
    }
    return '₹$str';
  }

  @override
  void initState() {
    super.initState();
    final rand = Random();
    _bookingId = '#TK-2026-${(10000 + rand.nextInt(89999)).toString()}';

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );
    _checkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _checkController.forward();

    // Award coins after animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_coinsAwarded && mounted) {
        _coinsAwarded = true;
        final appState = context.read<AppState>();
        final cart = appState.cartState;

        final orderItems = cart.tankQuantities.entries
            .where((e) => e.value > 0)
            .toList();
        int subtotal = 0;
        for (final item in orderItems) {
          subtotal += (_prices[item.key] ?? 0) * item.value;
        }
        final int totalTanks = orderItems.fold(0, (sum, e) => sum + e.value);
        final bool hasBulkDiscount = totalTanks >= 3;
        final int bulkDiscount = hasBulkDiscount ? 500 : 0;
        const int welcomeOffer = 100;
        final int coinsDiscount = cart.useCoins
            ? appState.coinBalance.clamp(0, 50)
            : 0;
        final int total =
            (subtotal - bulkDiscount - welcomeOffer - coinsDiscount).clamp(
              0,
              99999,
            );

        if (cart.useCoins && coinsDiscount > 0) {
          appState.deductCoins(coinsDiscount);
        }

        appState.addBooking(
          BookingModel(
            bookingId: _bookingId,
            tanks: orderItems
                .map((e) => {'size': e.key, 'qty': e.value})
                .toList(),
            date: cart.selectedDate ?? '',
            timeSlot: cart.selectedTimeSlot ?? '',
            address: cart.address,
            landmark: cart.landmark,
            phone: cart.phone,
            totalAmount: total,
            createdAt: DateTime.now(),
          ),
        );

        appState.addCoins(50);
        appState.resetCart();
      }
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final booking = appState.bookingHistory.isNotEmpty
        ? appState.bookingHistory.first
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 40),
      child: Column(
        children: [
          // Animated checkmark
          ScaleTransition(
            scale: _checkScale,
            child: FadeTransition(
              opacity: _checkOpacity,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.success.withAlpha(26),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.success.withAlpha(77),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.check_rounded,
                    color: AppTheme.success,
                    size: 56,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('🎉', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            'Booking Confirmed!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Our team will call you before arrival to confirm the appointment.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Booking ID
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryNavy,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.confirmation_number_rounded,
                  color: AppTheme.tealAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Booking ID: ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.white.withAlpha(179),
                  ),
                ),
                Text(
                  _bookingId,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.tealAccent,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Appointment details
          if (booking != null)
            Container(
              width: double.infinity,
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'APPOINTMENT DETAILS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _detailRow(
                    Icons.cleaning_services_rounded,
                    'Service',
                    booking.tanks
                        .map((t) => '${t['size']} × ${t['qty']} Tank Cleaning')
                        .join(', '),
                  ),
                  const SizedBox(height: 8),
                  _detailRow(
                    Icons.calendar_today_rounded,
                    'Date & Time',
                    '${booking.date}, ${booking.timeSlot}',
                  ),
                  const SizedBox(height: 8),
                  _detailRow(
                    Icons.location_on_rounded,
                    'Address',
                    booking.address,
                  ),
                  const SizedBox(height: 8),
                  _detailRow(
                    Icons.payment_rounded,
                    'Amount',
                    '${_formatPrice(booking.totalAmount)} — Cash on Service / Pay Later',
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Rewards notice
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.warning.withAlpha(26),
                  AppTheme.tealAccent.withAlpha(26),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.warning.withAlpha(77)),
            ),
            child: Row(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '+50 Coins Added to Wallet!',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.warning,
                        ),
                      ),
                      Text(
                        'Leave a review after service to earn even more coins!',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Back to Home — resets wizard to Step 1 and switches to Home tab (index 0)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                context.go(AppRoutes.homeScreen);
              },
              icon: const Icon(Icons.home_rounded, size: 20),
              label: Text(
                'Back to Home',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Book Another Service — resets all form fields and goes back to Step 1
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                // Reset cart state (form fields)
                context.read<AppState>().resetCart();
                // Reset wizard to Step 1 via callback, then navigate to booking tab
                if (widget.onBookAnother != null) {
                  widget.onBookAnother!();
                } else {
                  context.go(AppRoutes.bookingScreen);
                }
              },
              icon: Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: AppTheme.tealAccent,
              ),
              label: Text(
                'Book Another Service',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.tealAccent,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.tealAccent, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
          Text(
            'Need help? Contact us at maintix.help@gmail.com or WhatsApp',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '© 2026 Homaclo. All Rights Reserved.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppTheme.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
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
