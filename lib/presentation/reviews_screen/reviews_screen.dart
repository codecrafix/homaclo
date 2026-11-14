import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../../routes/app_routes.dart';
import '../../services/supabase_service.dart';
import './widgets/reviews_card_widget.dart';
import './widgets/reviews_stats_widget.dart';
import '../../widgets/gps_enforcement_wrapper.dart';
import '../../widgets/site_footer.dart';

/// Reviews screen — same rules as the website (web/site/reviews.js):
///  * public feed = approved reviews only (newest first) + Satna sample reviews
///  * one review and one +10 coin reward per booking, enforced by the database
///    (review_locks + triggers); the server credits the coins, not the app
///  * review is saved for the service of the user's latest booking, with its
///    service_category; card icon follows the service (💧 ☀️ 🔧)
///  * deleting a review never frees the booking again
class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _Elig {
  final String state; // anon | nobooking | done | ok | err
  final String service;
  final String category;
  const _Elig(this.state, [this.service = '', this.category = 'water_tank']);
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  static const _colors = <int>[
    0xFF3B82F6,
    0xFF10B981,
    0xFFEC4899,
    0xFFF59E0B,
    0xFF8B5CF6,
    0xFF06B6D4,
    0xFF0D9488,
  ];

  List<Map<String, dynamic>> _db = [];
  bool _loading = true;
  bool _busy = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _loadFeed();
    // Keep the public feed live, like the website (every 30 s).
    _poll = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadFeed();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  String? get _uid => SupabaseService.instance.currentUser?.id;

  Future<void> _loadFeed() async {
    try {
      final data = await SupabaseService.instance.client
          .from('reviews')
          .select()
          .eq('is_approved', true)
          .order('created_at', ascending: false);
      _db = List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      debugPrint('loadFeed error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  // ── helpers (same as website) ──
  static String _cleanSvc(dynamic s) => (s ?? '').toString().split(' — ').first.trim();

  static String _iconFor(String tag, dynamic cat) {
    if (RegExp(r'repair|maintenance', caseSensitive: false).hasMatch(tag)) {
      return '🔧';
    }
    if (cat == 'solar' || RegExp('solar', caseSensitive: false).hasMatch(tag)) {
      return '☀️';
    }
    return '💧';
  }

  static String _ago(String? iso) {
    final t = DateTime.tryParse(iso ?? '');
    if (t == null) return 'Just now';
    final d = DateTime.now().difference(t).inMinutes / 1440.0;
    if (d > 30) return '${(d / 30).floor()} month(s) ago';
    if (d >= 1) return '${d.floor()} day(s) ago';
    final hr = (d * 24).floor();
    return hr > 0 ? '$hr hour(s) ago' : 'Just now';
  }

  static String _initials(String n) {
    final s = n
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();
    return s.isEmpty ? 'C' : s;
  }

  double get _avg => _db.isEmpty
      ? 5.0
      : _db.fold<double>(0, (s, r) => s + ((r['rating'] as num?)?.toDouble() ?? 0)) /
            _db.length;

  // ── eligibility: one review per booking (review_locks) ──
  Future<_Elig> _eligibility() async {
    final uid = _uid;
    if (uid == null) return const _Elig('anon');
    final client = SupabaseService.instance.client;
    final b = await client
        .from('bookings')
        .select('id,created_at,service_name,service_category')
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(1);
    if ((b as List).isEmpty) return const _Elig('nobooking');
    final bk = b.first as Map<String, dynamic>;
    final svc = _cleanSvc(bk['service_name']);
    final service = svc.isEmpty ? 'Water Tank Cleaning' : svc;
    final cat = bk['service_category'] == 'solar' ? 'solar' : 'water_tank';
    // Locked for good once this booking was reviewed (even if deleted later).
    try {
      final lk = await client
          .from('review_locks')
          .select('booking_id')
          .eq('booking_id', bk['id'])
          .limit(1);
      if ((lk as List).isNotEmpty) return const _Elig('done');
    } catch (_) {}
    final r = await client
        .from('reviews')
        .select('created_at')
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(1);
    if ((r as List).isEmpty) return _Elig('ok', service, cat);
    final rt = DateTime.tryParse(r.first['created_at'] as String? ?? '');
    final bt = DateTime.tryParse(bk['created_at'] as String? ?? '');
    if (rt != null && bt != null && rt.isAfter(bt)) return const _Elig('done');
    return _Elig('ok', service, cat);
  }

  void _toast(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          m,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: error ? Colors.red.shade400 : AppTheme.primaryNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _info(String icon, String title, String msg, {String? primary, VoidCallback? onPrimary}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                onPrimary?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary != null ? AppTheme.tealAccent : AppTheme.primaryNavy,
                foregroundColor: primary != null ? const Color(0xFF04202A) : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                primary ?? 'Got it',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
          if (primary != null)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _doneInfo() => _info(
    '🔒',
    'Review Already Submitted',
    'You have already reviewed your last booking (one review and one reward per booking). Complete another booking to write a new review!',
  );

  Future<void> _onWriteReviewTapped() async {
    if (_uid == null) {
      _info(
        '🔐',
        'Sign in required',
        'Please login or signup first to write a review.',
        primary: 'Sign in / Sign up',
        onPrimary: () => context.go(AppRoutes.signUpLoginScreen),
      );
      return;
    }
    _Elig e;
    try {
      e = await _eligibility();
    } catch (_) {
      e = const _Elig('err');
    }
    if (!mounted) return;
    if (e.state == 'nobooking') {
      return _info(
        '🔒',
        'Booking Required',
        'Please complete a service booking first to unlock verified customer reviews!',
      );
    }
    if (e.state == 'done') return _doneInfo();
    if (e.state != 'ok') {
      return _toast('Could not check review eligibility. Try again.', error: true);
    }
    final comment = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ReviewSubmissionSheet(
        service: e.service,
        commentController: comment,
        onSubmit: (rating, text) => _submit(rating, text),
      ),
    ).whenComplete(comment.dispose);
  }

  Future<void> _submit(int rating, String text) async {
    if (_busy) return;
    _busy = true;
    try {
      final e = await _eligibility();
      if (e.state != 'ok') {
        _doneInfo();
        return;
      }
      final app = context.read<AppState>();
      await SupabaseService.instance.client.from('reviews').insert({
        'user_id': _uid,
        'user_name': app.userName,
        'service_name': e.service,
        'service_category': e.category,
        'rating': rating,
        'review_text': text,
        'is_approved': false,
      });
      // The +10 coins are credited by the server, exactly once per booking.
      await app.refreshProfileStats();
      _toast('🪙 Review submitted! +10 coins added.');
      await _loadFeed();
    } catch (x) {
      final m = x.toString();
      if (RegExp('review_already_submitted|review_requires_booking').hasMatch(m)) {
        _doneInfo();
      } else {
        debugPrint('submit review error: $x');
        _toast('Could not submit review. Please try again.', error: true);
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _refreshReviews() async {
    await _loadFeed();
    if (mounted) {
      // keep Profile > My Reviews in sync
      await context.read<AppState>().loadDbReviews();
    }
  }

  void _confirmDeleteReview(String reviewId) {
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
          'This review will be permanently deleted. You will not be able to write another review for the same booking.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.textSecondary),
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
              await _loadFeed();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  // name, location, time, rating, review, tag, colour, initials, icon
  static const List<List<Object>> _mock = [
    ['Rajesh Sharma', 'Civil Lines, Satna', '2 weeks ago', 5, 'Excellent service! The team was professional and thorough. My 1000L tank was cleaned spotlessly. Water quality has improved significantly. Highly recommend to everyone in Satna!', '1000L Cleaned', 0xFF3B82F6, 'RS', '💧'],
    ['Amit Mishra', 'Kothi Road, Satna', '1 week ago', 5, 'Our solar panels were covered in dust and bird droppings. The team washed all 8 panels carefully with soft brushes and the generation went up noticeably the very next day. Neat work and a fair price.', 'Solar Panel Cleaning · 4kW', 0xFFF59E0B, 'AM', '☀️'],
    ['Manish Agrawal', 'Sindhi Camp, Satna', '1 week ago', 5, 'The inverter kept showing a fault and the output was very low. The technician found a loose DC connection, fixed it on the spot and explained everything clearly. Output is back to normal now.', 'Solar Maintenance & Repair', 0xFF0D9488, 'MA', '🔧'],
    ['Ramesh Tiwari', 'Dawari, Satna', '2 weeks ago', 5, 'Bahut achha service hai! Team time par aayi aur tank bilkul saaf kar diya. Paani ab zyada saaf aata hai. Homaclo ki team bahut professional hai. Definitely recommend karunga.', '1000L Tank Cleaned', 0xFF10B981, 'RT', '💧'],
    ['Sunita Pandey', 'Panna Road, Satna', '2 weeks ago', 5, 'Panel cleaning ke baad inverter ki reading me clear farak dikha. Team time par aayi aur paani ki vyavastha bhi khud ki. ₹100 per panel ka rate bilkul theek laga.', 'Solar Panel Cleaning · 3kW', 0xFFEC4899, 'SP', '☀️'],
    ['Kavita Soni', 'Dawari, Satna', '2 weeks ago', 5, 'ACDB me problem aa rahi thi, bijli ban rahi thi par grid me nahi ja rahi thi. Technician ne check karke ek hi visit me theek kar diya. Bahut professional aur samajhdaar.', 'Solar Maintenance & Repair', 0xFF8B5CF6, 'KS', '🔧'],
    ['Priya Sharma', 'Pateri, Satna', '3 weeks ago', 4, 'Good service, reasonable price. The technician was very professional and explained everything clearly. My family was worried about water quality but now we are fully satisfied.', '750L Cleaned', 0xFFEC4899, 'PS', '💧'],
    ['Deepak Singh', 'Rewa Road, Satna', '3 weeks ago', 4, 'Good job on our 10kW rooftop system. They used soft brushes and no harsh chemicals, and finished in about two hours. Will book again after the dusty season.', 'Solar Panel Cleaning · 10kW', 0xFF06B6D4, 'DS', '☀️'],
    ['Suresh Gupta', 'Birla Road, Satna', '1 month ago', 5, 'Superb experience! Booked online and the team arrived exactly on time. Tank cleaning was done in under 2 hours. Very affordable pricing. Will definitely book again.', '1500L Cleaned', 0xFFF59E0B, 'SG', '💧'],
    ['Rakesh Kushwaha', 'Maihar Bypass, Satna', '1 month ago', 4, 'Voltage was dropping every afternoon. They checked the DCDB, wiring and earthing and fixed the issue. The ₹1,000 service charge was reasonable. Good service overall.', 'Solar Maintenance & Repair', 0xFF3B82F6, 'RK', '🔧'],
    ['Anita Verma', 'Maihar Bypass, Satna', '3 weeks ago', 5, 'Excellent work by the Homaclo team. They cleaned our 2000L overhead tank thoroughly. The water now tastes much better. Highly professional and courteous staff.', '2000L Cleaned', 0xFF8B5CF6, 'AV', '💧'],
    ['Mohan Patel', 'Jawahar Nagar, Satna', '1 month ago', 4, 'Very good service at a fair price. The team was punctual and cleaned the tank properly. I noticed a clear improvement in water quality after the cleaning. Recommended!', '500L Cleaned', 0xFF06B6D4, 'MP', '💧'],
  ];

  /// Website-style navy band with the average rating (like the site's .band).
  Widget _heroBand() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF072654), Color(0xFF0A3B66)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, color: AppTheme.warning, size: 24),
              const SizedBox(width: 6),
              Text(
                _avg.toStringAsFixed(1),
                style: GoogleFonts.fraunces(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.success.withAlpha(51),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '✓ Verified',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF34D399),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'What our customers say',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFFC5D6EE),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dbCard(Map<String, dynamic> r, AppState app) {
    final own = _uid != null && r['user_id'] == _uid;
    var name = (r['user_name'] ?? '').toString().trim();
    if (name.isEmpty) name = own && app.userName.isNotEmpty ? app.userName : 'Customer';
    final tagRaw = _cleanSvc(r['service_name']);
    final tag = tagRaw.isEmpty ? 'Tank Cleaning' : tagRaw;
    final id = r['id']?.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          ReviewCardWidget(
            name: name,
            location: 'Satna, MP',
            timeAgo: _ago(r['created_at'] as String?),
            rating: ((r['rating'] as num?)?.round() ?? 5),
            review: (r['review_text'] ?? '').toString(),
            tag: tag,
            icon: _iconFor(tag, r['service_category']),
            avatarColor: Color(_colors[name.codeUnitAt(0) % _colors.length]),
            initials: _initials(name),
            photoUrl: own ? app.effectiveProfileImageUrl : null,
          ),
          if (own && id != null)
            Positioned(
              bottom: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => _confirmDeleteReview(id),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayFor(Theme.of(context).brightness == Brightness.dark),
      child: GpsEnforcementWrapper(
        child: Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _refreshReviews,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(child: _heroBand()),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: ReviewsStatsWidget(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _onWriteReviewTapped,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.tealAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            '✍️ Write a Review',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
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
                        style: GoogleFonts.fraunces(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (_loading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else ...[
                          ..._db.map((r) => _dbCard(r, app)),
                          ..._mock.map(
                            (m) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ReviewCardWidget(
                                name: m[0] as String,
                                location: m[1] as String,
                                timeAgo: m[2] as String,
                                rating: m[3] as int,
                                review: m[4] as String,
                                tag: m[5] as String,
                                avatarColor: Color(m[6] as int),
                                initials: m[7] as String,
                                icon: m[8] as String,
                              ),
                            ),
                          ),
                        ],
                      ]),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SiteFooter()),
                  // Room for the floating bottom nav, same colour as the footer end.
                  const SliverToBoxAdapter(
                    child: ColoredBox(
                      color: Color(0xFF0F172A),
                      child: SizedBox(height: 90, width: double.infinity),
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
  final String service;
  final TextEditingController commentController;
  final void Function(int rating, String comment) onSubmit;

  const _ReviewSubmissionSheet({
    required this.service,
    required this.commentController,
    required this.onSubmit,
  });

  @override
  State<_ReviewSubmissionSheet> createState() => _ReviewSubmissionSheetState();
}

class _ReviewSubmissionSheetState extends State<_ReviewSubmissionSheet> {
  int _rating = 5;
  bool _submitting = false;

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted),
    filled: true,
    fillColor: AppTheme.inputFillColor(context),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppTheme.divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppTheme.divider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppTheme.tealAccent, width: 1.5),
    ),
    contentPadding: const EdgeInsets.all(12),
  );

  Widget _label(String t) => Text(
    t,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppTheme.inputTextColor(context),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Write a Review',
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.inputTextColor(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Share your experience to earn +10 coins',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              _label('Service'),
              const SizedBox(height: 6),
              TextField(
                controller: TextEditingController(text: widget.service),
                readOnly: true,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.inputTextColor(context),
                ),
                decoration: _dec(''),
              ),
              const SizedBox(height: 12),
              _label('Your Rating'),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setState(() => _rating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: AppTheme.warning,
                        size: 36,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              _label('Your Review'),
              const SizedBox(height: 8),
              TextField(
                controller: widget.commentController,
                maxLines: 4,
                maxLength: 300,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppTheme.inputTextColor(context),
                ),
                decoration: _dec('Tell others about your experience...'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting
                      ? null
                      : () {
                          final comment = widget.commentController.text.trim();
                          if (comment.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please write your review before submitting.',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                                ),
                                backgroundColor: Colors.red.shade400,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          setState(() => _submitting = true);
                          Navigator.of(context).pop();
                          widget.onSubmit(_rating, comment);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tealAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _submitting ? 'Submitting...' : 'Submit Review (+10 🪙)',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
            ],
          ),
        ),
      ),
    );
  }
}
