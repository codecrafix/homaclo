import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';
import './widgets/reviews_card_widget.dart';
import './widgets/reviews_stats_widget.dart';
import '../../widgets/gps_enforcement_wrapper.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  int _selectedRating = 5;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _serviceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      appState.loadDbReviews();
      // Refresh DB-backed review eligibility on every screen load
      appState.checkReviewEligibility();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _serviceController.dispose();
    super.dispose();
  }

  void _onWriteReviewTapped(BuildContext context) {
    final appState = context.read<AppState>();

    if (!appState.canWriteReview) {
      // Determine the right message based on state
      final hasBooking = appState.hasCompletedBooking;
      final lockMessage = hasBooking
          ? 'You have already submitted a review for your last booking. Complete another booking to write a new review!'
          : 'Please complete a service booking first to unlock verified customer reviews!';

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔒', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                hasBooking ? 'Review Already Submitted' : 'Booking Required',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                lockMessage,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Got it',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    _selectedRating = 5;
    _commentController.clear();
    _serviceController.text = appState.dbBookings.isNotEmpty
        ? appState.dbBookings.first.serviceName
        : 'Water Tank Cleaning';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReviewSubmissionSheet(
        initialRating: _selectedRating,
        commentController: _commentController,
        serviceController: _serviceController,
        onSubmit: (rating, comment, serviceName) async {
          Navigator.of(ctx).pop();
          final state = context.read<AppState>();
          final success = await state.submitDbReview(
            serviceName: serviceName,
            rating: rating.toDouble(),
            reviewText: comment,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      success
                          ? 'Review submitted! +10 coins added.'
                          : 'Review submitted!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
              color: Colors.white,
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppTheme.primaryNavy,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _refreshReviews() async {
    final appState = context.read<AppState>();
    await Future.wait([
      appState.loadDbReviews(),
      appState.checkReviewEligibility(),
    ]);
  }

  void _confirmDeleteReview(BuildContext context, String reviewId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Review?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'This review will be permanently deleted.',
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
              await context.read<AppState>().deleteDbReview(reviewId);
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

  // Localized Satna mock reviews
  static const List<Map<String, dynamic>> _mockReviews = [
    {
      'name': 'Rajesh Sharma',
      'location': 'Civil Lines, Satna',
      'timeAgo': '2 weeks ago',
      'rating': 5,
      'review':
          'Excellent service! The team was professional and thorough. My 1000L tank was cleaned spotlessly. Water quality has improved significantly. Highly recommend to everyone in Satna!',
      'tag': '1000L Cleaned',
      'color': Color(0xFF3B82F6),
      'initials': 'RS',
    },
    {
      'name': 'Ramesh Tiwari',
      'location': 'Dawari, Satna',
      'timeAgo': '2 weeks ago',
      'rating': 5,
      'review':
          'Bahut achha service hai! Team time par aayi aur tank bilkul saaf kar diya. Paani ab zyada saaf aata hai. Homaclo ki team bahut professional hai. Definitely recommend karunga.',
      'tag': '1000L Tank Cleaned',
      'color': Color(0xFF10B981),
      'initials': 'RT',
    },
    {
      'name': 'Priya Sharma',
      'location': 'Pateri, Satna',
      'timeAgo': '3 weeks ago',
      'rating': 4,
      'review':
          'Good service, reasonable price. The technician was very professional and explained everything clearly. My family was worried about water quality but now we are fully satisfied.',
      'tag': '750L Cleaned',
      'color': Color(0xFFEC4899),
      'initials': 'PS',
    },
    {
      'name': 'Suresh Gupta',
      'location': 'Birla Road, Satna',
      'timeAgo': '1 month ago',
      'rating': 5,
      'review':
          'Superb experience! Booked online and the team arrived exactly on time. Tank cleaning was done in under 2 hours. Very affordable pricing. Will definitely book again.',
      'tag': '1500L Cleaned',
      'color': Color(0xFFF59E0B),
      'initials': 'SG',
    },
    {
      'name': 'Anita Verma',
      'location': 'Maihar Bypass, Satna',
      'timeAgo': '3 weeks ago',
      'rating': 5,
      'review':
          'Excellent work by the Homaclo team. They cleaned our 2000L overhead tank thoroughly. The water now tastes much better. Highly professional and courteous staff.',
      'tag': '2000L Cleaned',
      'color': Color(0xFF8B5CF6),
      'initials': 'AV',
    },
    {
      'name': 'Mohan Patel',
      'location': 'Jawahar Nagar, Satna',
      'timeAgo': '1 month ago',
      'rating': 4,
      'review':
          'Very good service at a fair price. The team was punctual and cleaned the tank properly. I noticed a clear improvement in water quality after the cleaning. Recommended!',
      'tag': '500L Cleaned',
      'color': Color(0xFF06B6D4),
      'initials': 'MP',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: GpsEnforcementWrapper(
        child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _refreshReviews,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
              SliverAppBar(
                backgroundColor: AppTheme.primaryNavy,
                pinned: true,
                expandedHeight: 120,
                elevation: 0,
                scrolledUnderElevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryNavy, Color(0xFF1A3F5C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: AppTheme.warning,
                              size: 22,
                            ),
                            const SizedBox(width: 6),
                            Text(
                             appState.publicAvgRating  > 0
                                  ? appState.publicAvgRating.toStringAsFixed(1)
                                  : '5.0',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withAlpha(51),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '✓ Verified',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'What our customers say',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Colors.white.withAlpha(179),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: ReviewsStatsWidget(),
                ),
              ),
              // Write a Review button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _onWriteReviewTapped(context),
                      icon: const Icon(Icons.rate_review_rounded, size: 18),
                      label: Text(
                        'Write a Review',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.tealAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(
                    'Customer Reviews',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (appState.reviewsLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      ...appState.userReviews.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Stack(
                            children: [
                              ReviewCardWidget(
                                name: r.name,
                                location: 'Satna, MP',
                                timeAgo: r.timeAgo,
                                rating: r.rating,
                                review: r.review,
                                tag: r.serviceName.isNotEmpty ? r.serviceName : 'Tank Cleaning',
                                avatarColor: Color(r.avatarColorValue),
                                initials: r.initials,
                                photoUrl: r.photoUrl,
                              ),
                               if (r.id != null &&
                                   r.userId == appState.currentUserId)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () =>
                                        _confirmDeleteReview(context, r.id!),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.error.withAlpha(20),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppTheme.error,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    // Localized Satna mock reviews
                    ..._mockReviews.map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ReviewCardWidget(
                          name: r['name'] as String,
                          location: r['location'] as String,
                          timeAgo: r['timeAgo'] as String,
                          rating: r['rating'] as int,
                          review: r['review'] as String,
                          tag: r['tag'] as String,
                          avatarColor: r['color'] as Color,
                          initials: r['initials'] as String,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _ReviewSubmissionSheet extends StatefulWidget {
  final int initialRating;
  final TextEditingController commentController;
  final TextEditingController serviceController;
  final void Function(int rating, String comment, String serviceName) onSubmit;

  const _ReviewSubmissionSheet({
    required this.initialRating,
    required this.commentController,
    required this.serviceController,
    required this.onSubmit,
  });

  @override
  State<_ReviewSubmissionSheet> createState() => _ReviewSubmissionSheetState();
}

class _ReviewSubmissionSheetState extends State<_ReviewSubmissionSheet> {
  late int _rating;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Write a Review',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.inputTextColor(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Share your experience to earn +10 coins',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Service',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.inputTextColor(context),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: widget.serviceController,
              readOnly: true,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.inputTextColor(context),
              ),
              decoration: InputDecoration(
                hintText: 'e.g. Water Tank Cleaning',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                ),
                filled: true,
                fillColor: AppTheme.inputFillColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.tealAccent,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your Rating',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = index + 1),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      index < _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: AppTheme.warning,
                      size: 36,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            Text(
              'Your Review',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.commentController,
              maxLines: 4,
              maxLength: 300,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.inputTextColor(context),
              ),
              decoration: InputDecoration(
                hintText: 'Tell others about your experience...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                ),
                filled: true,
                fillColor: AppTheme.inputFillColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.tealAccent,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),
            // ── SUBMIT BUTTON (always visible at bottom) ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        final comment = widget.commentController.text.trim();
                        if (comment.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please write your review before submitting.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                ),
                              ),
                              backgroundColor: Colors.red.shade400,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                          return;
                        }
                        setState(() => _isSubmitting = true);
                        final serviceName =
                            widget.serviceController.text.trim().isNotEmpty
                            ? widget.serviceController.text.trim()
                            : 'Water Tank Cleaning';
                        widget.onSubmit(_rating, comment, serviceName);
                      },
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _isSubmitting ? 'Submitting...' : 'Submit Review  (+10 🪙)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.tealAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            // Extra bottom padding so submit button clears the floating tab bar
            SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
          ],
       ),
     ),
    );
  }
}
