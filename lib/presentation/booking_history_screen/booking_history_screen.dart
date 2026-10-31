import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../../services/supabase_service.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/status_badge_widget.dart';
import '../../routes/app_routes.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadDbBookings();
    });
  }

  String _formatPrice(int price) {
    final str = price.toString();
    if (str.length > 3) {
      return '₹${str.substring(0, str.length - 3)},${str.substring(str.length - 3)}';
    }
    return '₹$str';
  }

  /// Format DateTime to 12-hour AM/PM time string
  String _formatTime12h(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }

  /// Format booking time slot string to 12-hour if it's in 24h format
  String _formatBookingTime(String timeSlot) {
    if (timeSlot.isEmpty) return '—';
    // If already contains AM/PM, return as-is
    if (timeSlot.toUpperCase().contains('AM') ||
        timeSlot.toUpperCase().contains('PM')) {
      return timeSlot;
    }
    // Try parsing HH:MM format
    final parts = timeSlot.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? -1;
      final minute = int.tryParse(parts[1].split(' ').first) ?? 0;
      if (hour >= 0 && hour <= 23) {
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        final minuteStr = minute.toString().padLeft(2, '0');
        return '$displayHour:$minuteStr $period';
      }
    }
    return timeSlot;
  }

  void _confirmDelete(BuildContext context, String bookingId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove Booking?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'This booking will be removed from your My Bookings list. Old bookings are also removed automatically after 7 days.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<AppState>().deleteDbBooking(
                bookingId,
              );
              if (mounted && !success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to delete booking. Try again.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: AppTheme.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final dbBookings = appState.dbBookings;
    final isLoading = appState.bookingsLoading;

    final activeBookings = dbBookings
        .where((b) => b.status != 'Completed' && b.status != 'Done')
        .toList();
    final completedBookings = dbBookings
        .where((b) => b.status == 'Completed' || b.status == 'Done')
        .toList();

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
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Bookings',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                '${dbBookings.length} booking${dbBookings.length != 1 ? 's' : ''}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: Colors.white.withAlpha(166),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => context.read<AppState>().loadDbBookings(),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'Refresh',
            ),
          ],
        ),
        floatingActionButton: dbBookings.isEmpty && !isLoading
            ? FloatingActionButton(
                onPressed: () {
                  context.go(AppRoutes.bookingScreen);
                },
                backgroundColor: AppTheme.tealAccent,
                child: const Icon(Icons.add_rounded, color: Colors.white),
              )
            : null,
        body: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : dbBookings.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.calendar_today_rounded,
                  title: 'No Bookings Yet',
                  subtitle:
                      'Your confirmed service bookings will appear here. Book your first water tank cleaning today!',
                  ctaLabel: 'Book a Service',
                  onCta: () {
                    context.go(AppRoutes.bookingScreen);
                  },
                )
              : RefreshIndicator(
                  onRefresh: () => context.read<AppState>().loadDbBookings(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      if (activeBookings.isNotEmpty) ...[
                        _sectionHeader(
                          'Active Bookings',
                          activeBookings.length,
                          AppTheme.tealAccent,
                        ),
                        const SizedBox(height: 10),
                        ...activeBookings.map(
                          (booking) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildDbBookingCard(
                              context,
                              booking: booking,
                              isCompleted: false,
                            ),
                          ),
                        ),
                      ],
                      if (completedBookings.isNotEmpty) ...[
                        if (activeBookings.isNotEmpty)
                          const SizedBox(height: 8),
                        _sectionHeader(
                          'Completed',
                          completedBookings.length,
                          AppTheme.success,
                        ),
                        const SizedBox(height: 10),
                        ...completedBookings.map(
                          (booking) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildDbBookingCard(
                              context,
                              booking: booking,
                              isCompleted: true,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDbBookingCard(
    BuildContext context, {
    required BookingRecord booking,
    required bool isCompleted,
  }) {
    BadgeStatus badgeStatus;
    switch (booking.status) {
      case 'Completed':
      case 'Done':
        badgeStatus = BadgeStatus.completed;
        break;
      case 'In Progress':
      case 'InProgress':
        badgeStatus = BadgeStatus.inProgress;
        break;
      default:
        badgeStatus = BadgeStatus.confirmed;
    }

    final borderColor = isCompleted ? AppTheme.success : AppTheme.tealAccent;

    // Parse service name to extract tank sizes and quantities for pricing breakdown
    final serviceNameLower = booking.serviceName.toLowerCase();
    final bool isRazorpayBooking = booking.status == 'CONFIRMED';

    // Format the booking time in 12-hour AM/PM
    final String formattedTime = _formatBookingTime(booking.bookingTime);

    // Format the exact booking creation date and time — convert UTC to IST (UTC+5:30)
    final DateTime createdAtUtc = booking.createdAt;
    final DateTime createdAtIst = createdAtUtc.add(
      const Duration(hours: 5, minutes: 30),
    );
    final String bookedOnDate = _formatDate(createdAtIst);
    final String bookedOnTime = _formatTime12h(createdAtIst);

    // Format the scheduled service date
    final String serviceDate =
        (booking.date.isNotEmpty && booking.date != 'null')
        ? booking.date
        : (booking.bookingDate.isNotEmpty && booking.bookingDate != 'null'
              ? booking.bookingDate
              : '—');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: borderColor, width: 3)),
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
          // Header: service name + status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  booking.serviceName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.tealAccent,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusBadgeWidget(status: badgeStatus),
            ],
          ),
          const SizedBox(height: 12),

          // Divider
          Divider(height: 1, color: AppTheme.divider),
          const SizedBox(height: 10),

          // Scheduled service date
          _infoRow(Icons.calendar_today_rounded, 'Service Date', serviceDate),
          const SizedBox(height: 6),

          // Scheduled time slot (12-hour AM/PM)
          if (formattedTime.isNotEmpty && formattedTime != '—') ...[
            _infoRow(Icons.access_time_rounded, 'Time Slot', formattedTime),
            const SizedBox(height: 6),
          ],

          // Booking created at (exact date + time)
          _infoRow(
            Icons.event_available_rounded,
            'Booked On',
            '$bookedOnDate at $bookedOnTime',
          ),
          const SizedBox(height: 6),

          // Address
          if (booking.address.isNotEmpty) ...[
            _infoRow(Icons.location_on_rounded, 'Address', booking.address),
            const SizedBox(height: 6),
          ],

          const SizedBox(height: 4),
          Divider(height: 1, color: AppTheme.divider),
          const SizedBox(height: 10),

          // Pricing section
          Text(
            'PRICING BREAKDOWN',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),

          // Total amount paid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Paid',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                _formatPrice(booking.price),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Payment method chip
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.tealLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isRazorpayBooking
                          ? Icons.credit_card_rounded
                          : Icons.payments_rounded,
                      size: 13,
                      color: AppTheme.tealAccent,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isRazorpayBooking
                          ? 'Paid via Razorpay'
                          : 'Cash on Service',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.tealAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Manual remove button (shown on every booking)
          ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: AppTheme.divider),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmDelete(context, booking.id),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: AppTheme.error,
                ),
                label: Text(
                  'Remove from History',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.error,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppTheme.error.withAlpha(102),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.tealAccent, size: 14),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
