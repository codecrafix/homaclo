import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingModel {
  final String bookingId;
  final List<Map<String, dynamic>> tanks;
  final String date;
  final String timeSlot;
  final String address;
  final String landmark;
  final String phone;
  final int totalAmount;
  final DateTime createdAt;
  String status;

  BookingModel({
    required this.bookingId,
    required this.tanks,
    required this.date,
    required this.timeSlot,
    required this.address,
    required this.landmark,
    required this.phone,
    required this.totalAmount,
    required this.createdAt,
    this.status = 'Confirmed',
  });
}

class ReviewModel {
  final String? id;
  final String? userId;
  final String name;
  final String initials;
  final int avatarColorValue;
  final int rating;
  final String review;
  final String timeAgo;
  final String? photoUrl;
  final String serviceName;
  final bool isApproved;

  ReviewModel({
    this.id,
    this.userId,
    required this.name,
    required this.initials,
    required this.avatarColorValue,
    required this.rating,
    required this.review,
    this.timeAgo = 'Just now',
    this.photoUrl,
    this.serviceName = 'Water Tank Cleaning',
    this.isApproved = true,
  });
}

class CartState {
  Map<String, int> tankQuantities;
  String? selectedDate;
  String? selectedTimeSlot;
  String address;
  String landmark;
  String phone;
  bool useCoins;
  String couponCode;
  int couponDiscount;

  CartState({
    Map<String, int>? tankQuantities,
    this.selectedDate,
    this.selectedTimeSlot,
    this.address = '',
    this.landmark = '',
    this.phone = '',
    this.useCoins = false,
    this.couponCode = '',
    this.couponDiscount = 0,
  }) : tankQuantities =
           tankQuantities ??
           {'500L': 0, '750L': 0, '1000L': 0, '1500L': 0, '2000L': 0};

  void reset() {
    tankQuantities = {'500L': 0, '750L': 0, '1000L': 0, '1500L': 0, '2000L': 0};
    selectedDate = null;
    selectedTimeSlot = null;
    address = '';
    landmark = '';
    phone = '';
    useCoins = false;
    couponCode = '';
    couponDiscount = 0;
  }
}

class AppState extends ChangeNotifier {
  // ─── Theme ─────────────────────────────────────────────────────────────────────
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(
        'theme_mode',
        _themeMode == ThemeMode.dark ? 'dark' : 'light',
      );
    });
  }

  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode');
    if (saved == 'dark') {
      _themeMode = ThemeMode.dark;
      notifyListeners();
    }
  }

  // ─── Coin balance (Supabase-backed) ──────────────────────────────────────
  int _coinBalance = 0;
  int get coinBalance => _coinBalance;

  // ─── Live location ────────────────────────────────────────────────────────────
  String _liveLocation = '';
  String get liveLocation => _liveLocation;
  bool _locationLoading = false;
  bool get locationLoading => _locationLoading;
  bool _locationPermissionDenied = false;
  bool get locationPermissionDenied => _locationPermissionDenied;
  double? _locationLatitude;
  double? get locationLatitude => _locationLatitude;
  double? _locationLongitude;
  double? get locationLongitude => _locationLongitude;

  // ─── Supabase-backed bookings ─────────────────────────────────────────────────
  final List<BookingModel> _bookingHistory = [];
  List<BookingModel> get bookingHistory => List.unmodifiable(_bookingHistory);

  List<BookingRecord> _dbBookings = [];
  List<BookingRecord> get dbBookings => List.unmodifiable(_dbBookings);
  bool _bookingsLoading = false;
  bool get bookingsLoading => _bookingsLoading;

  // ─── Reviews (Supabase-backed) ────────────────────────────────────────────────
  List<ReviewModel> _userReviews = [];
  List<ReviewModel> get userReviews => List.unmodifiable(_userReviews);
  List<ReviewModel> _myReviews = [];
  List<ReviewModel> get myReviews => List.unmodifiable(_myReviews);
  double _publicAvgRating = 0.0;
  double get publicAvgRating => _publicAvgRating;
  bool _reviewsLoading = false;
  bool get reviewsLoading => _reviewsLoading;

  int _reviewCredits = 0;
  int get reviewCredits => _reviewCredits;

  /// True if user has at least one booking AND hasn't submitted a review
  /// since their most recent booking (review gate logic).
  bool get hasCompletedBooking {
    final allBookings = [..._dbBookings, ..._bookingHistory];
    if (allBookings.isEmpty) return false;
    // User has bookings — check if they already reviewed after the latest booking
    return true;
  }

  /// Returns true only when the user can write a new review:
  /// - Must have at least one completed booking
  /// - Must NOT have already submitted a review after their most recent booking
  bool get canWriteReview {
    // Use DB-backed flag (set by checkReviewEligibility)
    if (_dbBookings.isEmpty && _bookingHistory.isEmpty) return false;
    return !_reviewSubmittedAfterLastBooking;
  }

  // ─── Profile stats ────────────────────────────────────────────────────────────
  int _totalBookingsCount = 0;
  int get totalBookingsCount => _totalBookingsCount;

  double _avgRating = 0.0;
  double get avgRating => _avgRating;

  bool _statsLoading = false;
  bool get statsLoading => _statsLoading;

  bool _reviewSubmittedAfterLastBooking = false;

  // ─── Login mutex — prevents concurrent loginWithSupabase() calls ──────────
  bool _loginInProgress = false;

  // ─── Unread notification count ──────────────────────────────────────────
  int _unreadNotificationCount = 0;
  int get unreadNotificationCount => _unreadNotificationCount;

  Future<void> refreshUnreadNotificationCount() async {
    final userId = currentUserId;
    if (userId == null) {
      _unreadNotificationCount = 0;
      notifyListeners();
      return;
    }
    try {
      final client = SupabaseService.instance.client;
      final rows = await client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);
      // Account may have changed while the request was in flight — ignore
      // the result so one account's count never lands on another account.
      if (currentUserId != userId) return;
      _unreadNotificationCount = (rows as List).length;
      notifyListeners();
    } catch (e) {
      debugPrint('refreshUnreadNotificationCount error: $e');
    }
  }

  void clearUnreadNotificationCount() {
    _unreadNotificationCount = 0;
    notifyListeners();
  }

  final CartState _cartState = CartState();
  CartState get cartState => _cartState;

  // ─── Auth & Profile ──────────────────────────────────────────────────────────
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  bool _profileLoading = false;
  bool get profileLoading => _profileLoading;

  String _userName = '';
  String get userName => _userName;

  String _userEmail = '';
  String get userEmail => _userEmail;

  String _userPhone = '';
  String get userPhone => _userPhone;

  String _userCity = '';
  String get userCity => _userCity;
  String get suggestedCity => _userCity.isNotEmpty ? _userCity : _liveLocation;

  String? _avatarUrl;
  String? get avatarUrl => _avatarUrl;

  String? _profileImagePath;
  String? get profileImagePath => _profileImagePath;

  String? _googlePhotoUrl;
  String? get googlePhotoUrl => _googlePhotoUrl;

  /// Current user ID from Supabase
  String? get currentUserId => SupabaseService.instance.currentUser?.id;

  /// Best available avatar
  String? get effectiveProfileImageUrl =>
      _avatarUrl ?? _profileImagePath ?? _googlePhotoUrl;

  // ─── Completed tank cleaning bookings count ───────────────────────────────
  int get completedTankCleaningCount => _dbBookings
      .where(
        (b) =>
            b.serviceName.toLowerCase().contains('tank') &&
            (b.status.toLowerCase() == 'completed' ||
                b.status.toLowerCase() == 'confirmed'),
      )
      .length;

  // ─── Auth methods ───────────────────────────────────────────────────────────────

  Future<void> loginWithSupabase() async {
    // ── Mutex guard: prevent concurrent calls (race between OTP screen & auth listener) ──
    if (_loginInProgress) return;
    _loginInProgress = true;

    try {
      final user = SupabaseService.instance.currentUser;
      if (user == null) return;

      _isLoggedIn = true;
      _userEmail = user.email ?? '';
      notifyListeners();

      await loadThemePreference();

      final isNewUser = await SupabaseService.instance.ensureFirstTimeSetup();

      await _loadProfile();
      await loadDbBookings();
      await loadDbReviews();
      await _loadProfileStats();
      await loadSavedLocation();

      // Check DB-backed review eligibility after loading bookings & reviews
      await checkReviewEligibility();

      // Load unread notification count for badge
      await refreshUnreadNotificationCount();

      if (isNewUser && user.id.isNotEmpty) {
        await _handleSignupBonus(user.id);
        // Do NOT call _checkMonthlyBonus for new users — signup bonus covers first month
      } else {
        // Existing user login — send welcome notification if not already sent
        await _handleLoginNotification(user.id);
        // Check monthly bonus only for existing users
        await _checkMonthlyBonus(user.id);
      }
    } finally {
      _loginInProgress = false;
    }
  }

  Future<void> _handleLoginNotification(String userId) async {
    try {
      // Only send welcome notification if none exists yet for this user
      final alreadySent = await SupabaseService.instance.hasWelcomeNotification(
        userId,
      );
      if (alreadySent) return;

      await NotificationService.instance.triggerNotification(
        userId: userId,
        title: 'Welcome to Homaclo! 🚰',
        body: 'Book your professional water tank cleaning slot today.',
        type: 'welcome',
        localId: 10,
      );
    } catch (e) {
      debugPrint('_handleLoginNotification error: $e');
    }
  }

  Future<void> _handleSignupBonus(String userId) async {
    try {
      // PRIMARY GUARD: Check coin_transactions DB for any 'welcome' entry
      // This is the single authoritative source — prevents all race conditions
      final client = SupabaseService.instance.client;
      final existingBonus = await client
          .from('coin_transactions')
          .select('id')
          .eq('user_id', userId)
          .eq('type', 'welcome')
          .limit(1);

      if ((existingBonus as List).isNotEmpty) {
        debugPrint(
          '_handleSignupBonus: skipped — welcome bonus already exists in DB',
        );
        // Still mark profile flag if somehow not set
        await SupabaseService.instance.markSignupBonusAwarded();
        return;
      }

      // SECONDARY GUARD: Check profile flag
      final profile = await SupabaseService.instance.fetchProfile();
      final bonusAwarded = profile?.signupBonusAwarded ?? false;
      if (bonusAwarded) {
        debugPrint(
          '_handleSignupBonus: skipped — signupBonusAwarded flag is true',
        );
        return;
      }

      // Mark bonus as awarded FIRST (before adding coins) to prevent race condition
      await SupabaseService.instance.markSignupBonusAwarded();

      // Award +50 coins exactly once
      await addCoinsToSupabase(
        amount: 50,
        type: 'welcome',
        description: 'Welcome signup bonus',
      );

      // Welcome notification (only once — new user)
      await NotificationService.instance.triggerNotification(
        userId: userId,
        title: 'Welcome to Homaclo! 🚰',
        body: 'Book your professional water tank cleaning slot today.',
        type: 'welcome',
        localId: 10,
      );

      // Signup bonus notification
      await NotificationService.instance.triggerNotification(
        userId: userId,
        title: 'Welcome Bonus! 🪙',
        body: 'You received 50 Coins on signup! (Value ₹50)',
        type: 'welcome',
        localId: 11,
      );

      // WEL100 coupon notification
      await NotificationService.instance.triggerNotification(
        userId: userId,
        title: 'Welcome Offer! 🎁',
        body: 'Get ₹100 Flat Discount on your first booking using code WEL100!',
        type: 'coupon',
        localId: 12,
      );
    } catch (e) {
      debugPrint('_handleSignupBonus error: $e');
    }
  }

  Future<void> _checkMonthlyBonus(String userId) async {
    try {
      final now = DateTime.now();
      final client = SupabaseService.instance.client;

      // PRIMARY GUARD: Check Supabase coin_transactions for any monthly_bonus in last 30 days
      // This is the single authoritative source — prevents all cross-device duplication
      final rows = await client
          .from('coin_transactions')
          .select('created_at')
          .eq('user_id', userId)
          .eq('type', 'monthly_bonus')
          .order('created_at', ascending: false)
          .limit(1);

      if ((rows as List).isNotEmpty) {
        final lastDbBonusStr = rows[0]['created_at'] as String?;
        if (lastDbBonusStr != null) {
          final lastDbBonus = DateTime.tryParse(lastDbBonusStr);
          if (lastDbBonus != null) {
            final diff = now.difference(lastDbBonus).inDays;
            if (diff < 30) {
              debugPrint(
                '_checkMonthlyBonus: skipped — last bonus was $diff days ago',
              );
              return; // Not yet 30 days — skip
            }
          }
        }
      } else {
        // No monthly_bonus ever — check if signup bonus was awarded within last 30 days
        // to avoid double-granting on first login month
        final signupRows = await client
            .from('coin_transactions')
            .select('created_at')
            .eq('user_id', userId)
            .eq('type', 'welcome')
            .order('created_at', ascending: false)
            .limit(1);

        if ((signupRows as List).isNotEmpty) {
          final signupBonusStr = signupRows[0]['created_at'] as String?;
          if (signupBonusStr != null) {
            final signupDate = DateTime.tryParse(signupBonusStr);
            if (signupDate != null) {
              final diff = now.difference(signupDate).inDays;
              if (diff < 30) {
                debugPrint(
                  '_checkMonthlyBonus: skipped — signup bonus was $diff days ago',
                );
                return; // Signup was recent — skip monthly
              }
            }
          }
        }
      }

      // Award monthly +50 coins — only reaches here if 30+ days since last bonus
      final success = await addCoinsToSupabase(
        amount: 50,
        type: 'monthly_bonus',
        description: 'Monthly recurring bonus',
      );

      if (success) {
        // Update SharedPreferences as secondary cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('monthly_bonus_$userId', now.toIso8601String());

        await NotificationService.instance.triggerNotification(
          userId: userId,
          title: 'Monthly Bonus! 🪙',
          body: '+50 Coins credited to your wallet this month!',
          type: 'bonus',
          localId: 13,
        );
        debugPrint('_checkMonthlyBonus: awarded 50 coins');
      }
    } catch (e) {
      debugPrint('_checkMonthlyBonus error: $e');
    }
  }

  /// Schedule recurring 3-tank offer notifications (every 4 hours, up to 3x/day)
  Future<void> scheduleThreeTankOfferIfNeeded(String userId) async {
    try {
      if (completedTankCleaningCount >= 3) return;

      final prefs = await SharedPreferences.getInstance();
      final key = 'three_tank_offer_count_${userId}_${DateTime.now().day}';
      final sentToday = prefs.getInt(key) ?? 0;
      if (sentToday >= 3) return;

      final lastSentKey = 'three_tank_offer_last_$userId';
      final lastSentStr = prefs.getString(lastSentKey);
      if (lastSentStr != null) {
        final lastSent = DateTime.tryParse(lastSentStr);
        if (lastSent != null) {
          final hoursSince = DateTime.now().difference(lastSent).inHours;
          if (hoursSince < 4) return;
        }
      }

      await NotificationService.instance.triggerNotification(
        userId: userId,
        title: 'Special Offer! 🎉',
        body: 'Get ₹500 Flat Discount on 3 Tank Cleaning Bookings! Book now.',
        type: 'offer',
        localId: 20,
      );

      await prefs.setInt(key, sentToday + 1);
      await prefs.setString(lastSentKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('scheduleThreeTankOfferIfNeeded error: $e');
    }
  }

  Future<void> _loadProfile() async {
    _profileLoading = true;
    notifyListeners();

    final profile = await SupabaseService.instance.fetchProfile();
    if (profile != null) {
      _userName = profile.fullName.isNotEmpty
          ? profile.fullName
          : (_userEmail.split('@').first);
      _userPhone = profile.phoneNumber;
      _userCity = profile.location;
      _avatarUrl = profile.avatarUrl;
    } else {
      _userName = _userEmail.split('@').first;
    }

    _profileLoading = false;
    notifyListeners();
  }

  Future<void> _loadProfileStats() async {
    _statsLoading = true;
    notifyListeners();

    final stats = await SupabaseService.instance.fetchProfileStats();
    _totalBookingsCount = stats['bookings'] as int? ?? 0;
    _coinBalance = stats['coins'] as int? ?? 0;
    _avgRating = stats['avgRating'] as double? ?? 0.0;

    _statsLoading = false;
    notifyListeners();
  }

  Future<void> refreshProfileStats() async {
    await _loadProfileStats();
  }

  void logout() {
    _isLoggedIn = false;
    _userName = '';
    _userEmail = '';
    _userPhone = '';
    _userCity = '';
    _avatarUrl = null;
    _profileImagePath = null;
    _googlePhotoUrl = null;
    _dbBookings = [];
    _bookingHistory.clear();
    _userReviews = [];
    _myReviews = [];
    _publicAvgRating = 0.0;
    _reviewCredits = 0;
    _reviewSubmittedAfterLastBooking = false;
    _coinBalance = 0;
    _totalBookingsCount = 0;
    _avgRating = 0.0;
    // Per-account notification state: old account's badge must not carry over
    _unreadNotificationCount = 0;
    // Old account's cart / address / phone must not carry over either
    _cartState.reset();
    _liveLocation = '';
    _locationPermissionDenied = false;
    _locationLatitude = null;
    _locationLongitude = null;
    _gpsServiceDisabled = false;
    notifyListeners();
    // theme_mode is intentionally NOT cleared here — dark/light preference
    // must survive logout (was previously removed by mistake, which caused
    // the app to forget dark mode after logging out).
  }

  void login({
    String? name,
    String? email,
    String? phone,
    String? googlePhotoUrl,
  }) {
    _isLoggedIn = true;
    if (name != null) _userName = name;
    if (email != null) _userEmail = email;
    if (phone != null) _userPhone = phone;
    if (googlePhotoUrl != null) _googlePhotoUrl = googlePhotoUrl;
    notifyListeners();
  }

  // ─── Profile update (Supabase-backed) ─────────────────────────────────────────────

  Future<bool> saveProfileToSupabase({
    required String name,
    required String phone,
    required String city,
    String? avatarUrl,
  }) async {
    final updated = await SupabaseService.instance.updateProfile(
      fullName: name,
      phoneNumber: phone,
      location: city,
      avatarUrl: avatarUrl ?? _avatarUrl,
    );

    if (updated != null) {
      _userName = updated.fullName;
      _userPhone = updated.phoneNumber;
      _userCity = updated.location;
      if (updated.avatarUrl != null) _avatarUrl = updated.avatarUrl;

      // User ne city khud badli ho to GPS use overwrite na kare
      try {
        final prefs = await SharedPreferences.getInstance();
        final isManual =
            city.trim().isNotEmpty && city.trim() != _liveLocation.trim();
        await prefs.setBool('city_manual_${currentUserId ?? ''}', isManual);
      } catch (_) {}

      notifyListeners();
      return true;
    }
    return false;
  }

  void updateProfile({
    String? name,
    String? phone,
    String? city,
    String? imagePath,
  }) {
    if (name != null && name.isNotEmpty) _userName = name;
    if (phone != null && phone.isNotEmpty) _userPhone = phone;
    if (city != null && city.isNotEmpty) _userCity = city;
    if (imagePath != null) _profileImagePath = imagePath;
    notifyListeners();
  }

  void setAvatarUrl(String url) {
    _avatarUrl = url;
    _profileImagePath = null;
    notifyListeners();
  }

  // ─── Bookings (Supabase DB) ────────────────────────────────────────────────────

  Future<void> loadDbBookings() async {
    _bookingsLoading = true;
    notifyListeners();

    _dbBookings = await SupabaseService.instance.fetchBookings();
    _totalBookingsCount = _dbBookings.length + _bookingHistory.length;

    _bookingsLoading = false;
    notifyListeners();
  }

  Future<bool> deleteDbBooking(String bookingId) async {
    final success = await SupabaseService.instance.deleteBooking(bookingId);
    if (success) {
      _dbBookings.removeWhere((b) => b.id == bookingId);
      _totalBookingsCount = _dbBookings.length + _bookingHistory.length;
      notifyListeners();
    }
    return success;
  }

  // ─── Reviews (Supabase DB) ────────────────────────────────────────────────────

  Future<void> loadDbReviews() async {
    _reviewsLoading = true;
    notifyListeners();

    final publicRecords = await SupabaseService.instance.fetchReviews();
    final myRecords = await SupabaseService.instance.fetchMyReviews();

    _userReviews = publicRecords.map(_toReviewModel).toList();
    _myReviews = myRecords.map(_toReviewModel).toList();

    if (_userReviews.isNotEmpty) {
      final total = _userReviews.fold<double>(0, (sum, r) => sum + r.rating);
      _publicAvgRating = total / _userReviews.length;
    } else {
      _publicAvgRating = 0.0;
    }

    _reviewsLoading = false;
    notifyListeners();
  }

  ReviewModel _toReviewModel(ReviewRecord r) {
    final isMine = r.userId == currentUserId;
    String displayName = r.userName.trim();
    if (displayName.isEmpty) {
      displayName = (isMine && _userName.isNotEmpty) ? _userName : 'Customer';
    }
    final initials = displayName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();
    const colors = <int>[
      0xFF3B82F6,
      0xFF10B981,
      0xFFEC4899,
      0xFFF59E0B,
      0xFF8B5CF6,
      0xFF06B6D4,
      0xFF0D9488,
    ];
    return ReviewModel(
      id: r.id,
      userId: r.userId,
      name: displayName,
      initials: initials.isEmpty ? 'C' : initials,
      avatarColorValue: colors[displayName.codeUnitAt(0) % colors.length],
      rating: r.rating.round(),
      review: r.reviewText,
      serviceName: r.serviceName,
      timeAgo: _timeAgo(r.createdAt),
      photoUrl: isMine ? effectiveProfileImageUrl : null,
      isApproved: r.isApproved,
    );
  }

  Future<bool> submitDbReview({
    required String serviceName,
    required double rating,
    required String reviewText,
  }) async {
    final record = await SupabaseService.instance.createReview(
      serviceName: serviceName,
      rating: rating,
      reviewText: reviewText,
      userName: _userName,
    );

    if (record != null) {
      // Award +10 coins for review
      await addCoinsToSupabase(
        amount: 10,
        type: 'reward',
        description: 'Review submitted for $serviceName',
      );

      // Lock review form immediately after submission
      _reviewSubmittedAfterLastBooking = true;

      // Trigger review reward notification
      final userId = currentUserId;
      if (userId != null) {
        await NotificationService.instance.triggerNotification(
          userId: userId,
          title: 'Review Reward! 🪙',
          body: '+10 Coins added for submitting your review!',
          type: 'reward',
          localId: 30,
        );
      }

      await loadDbReviews();
      await _loadProfileStats();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deleteDbReview(String reviewId) async {
    final success = await SupabaseService.instance.deleteReview(reviewId);
    if (success) {
      _userReviews.removeWhere((r) => r.id == reviewId);
      _myReviews.removeWhere((r) => r.id == reviewId);
      if (_myReviews.isNotEmpty) {
        final total = _myReviews.fold<double>(0, (sum, r) => sum + r.rating);
        _avgRating = total / _myReviews.length;
      } else {
        _avgRating = 0.0;
      }
      notifyListeners();
    }
    return success;
  }

  // ─── Coins (Supabase-backed) ──────────────────────────────────────────────────────

  Future<bool> addCoinsToSupabase({
    required int amount,
    required String type,
    required String description,
  }) async {
    final success = await SupabaseService.instance.addCoins(
      amount: amount,
      type: type,
      description: description,
    );
    if (success) {
      _coinBalance += amount;
      notifyListeners();
    }
    return success;
  }

  void addCoins(int amount) {
    _coinBalance += amount;
    notifyListeners();
  }

  void deductCoins(int amount) {
    if (_coinBalance >= amount) {
      _coinBalance -= amount;
      notifyListeners();
    }
  }

  // ─── Coupon validation ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> validateCoupon(String code) async {
    final cart = _cartState;
    final totalTanks = cart.tankQuantities.values.fold(0, (sum, v) => sum + v);
    return await SupabaseService.instance.validateCoupon(
      code: code,
      userId: currentUserId ?? '',
      tankCount: totalTanks,
    );
  }

  void updateCartCoupon(String code, int discount) {
    _cartState.couponCode = code;
    _cartState.couponDiscount = discount;
    notifyListeners();
  }

  // ─── Local bookings (cart flow) ───────────────────────────────────────────────

  void addBooking(BookingModel booking) {
    _bookingHistory.insert(0, booking);
    _reviewCredits += 1;
    _totalBookingsCount = _dbBookings.length + _bookingHistory.length;
    // New booking unlocks review form
    _reviewSubmittedAfterLastBooking = false;
    notifyListeners();

    final serviceLabel = booking.tanks
        .map((t) => '${t['size']} × ${t['qty']}')
        .join(', ');
    SupabaseService.instance
        .createBooking(
          serviceName: '$serviceLabel Tank Cleaning',
          date: booking.date,
          bookingDate: booking.date,
          bookingTime: booking.timeSlot,
          address: booking.address,
          status: booking.status,
          price: booking.totalAmount,
        )
        .then((record) {
          if (record != null) {
            _dbBookings.insert(0, record);
            _totalBookingsCount = _dbBookings.length + _bookingHistory.length;
            notifyListeners();
          }
        });
  }

  void deleteBooking(String bookingId) {
    _bookingHistory.removeWhere((b) => b.bookingId == bookingId);
    _totalBookingsCount = _dbBookings.length + _bookingHistory.length;
    notifyListeners();
  }

  void submitReview(ReviewModel review) {
    _userReviews.insert(0, review);
    _coinBalance += 10;
    notifyListeners();
  }

  void resetCart() {
    _cartState.reset();
    notifyListeners();
  }

  void updateCartTank(String size, int qty) {
    _cartState.tankQuantities[size] = qty;
    notifyListeners();
  }

  void updateCartDate(String date) {
    _cartState.selectedDate = date;
    notifyListeners();
  }

  void updateCartTime(String time) {
    _cartState.selectedTimeSlot = time;
    notifyListeners();
  }

  void updateCartAddress({String? address, String? landmark, String? phone}) {
    if (address != null) _cartState.address = address;
    if (landmark != null) _cartState.landmark = landmark;
    if (phone != null) _cartState.phone = phone;
    notifyListeners();
  }

  void updateCartCoins(bool useCoins) {
    _cartState.useCoins = useCoins;
    notifyListeners();
  }

  // ─── Razorpay-confirmed booking ──────────────────────────────────────────────────────

  /// Creates a booking in Supabase with CONFIRMED status after successful payment.
  /// Returns the booking ID string or null.
  Future<String?> createConfirmedBooking({
    required String serviceName,
    required CartState cart,
    required int totalAmount,
  }) async {
    try {
      final record = await SupabaseService.instance.createBooking(
        serviceName: serviceName,
        date: cart.selectedDate ?? '',
        bookingDate: cart.selectedDate ?? '',
        bookingTime: cart.selectedTimeSlot ?? '',
        address: cart.address,
        status: 'CONFIRMED',
        price: totalAmount,
      );

      if (record != null) {
        _dbBookings.insert(0, record);
        _totalBookingsCount = _dbBookings.length + _bookingHistory.length;
        // New booking unlocks review form
        _reviewSubmittedAfterLastBooking = false;
        notifyListeners();
        return record.id;
      }
    } catch (e) {
      debugPrint('createConfirmedBooking error: $e');
    }
    return null;
  }

  // ─── Location methods ───────────────────────────────────────────────────────────

  // ─── GPS enforcement state ──────────────────────────────────────────────────
  bool _gpsServiceDisabled = false;
  bool get gpsServiceDisabled => _gpsServiceDisabled;

  /// Check GPS hardware service status and update state.
  Future<void> checkGpsServiceStatus() async {
    if (kIsWeb) return;
    final enabled = await LocationService.instance.isLocationServiceEnabled();
    if (_gpsServiceDisabled != !enabled) {
      _gpsServiceDisabled = !enabled;
      notifyListeners();
    }
  }

  /// Fetch GPS location, reverse geocode via LocationIQ, save to DB, and update state.
  Future<void> fetchAndSaveLocation() async {
    if (_locationLoading) return;
    _locationLoading = true;
    _locationPermissionDenied = false;
    notifyListeners();

    try {
      // Check if hardware GPS service is enabled
      final serviceEnabled = await LocationService.instance
          .isLocationServiceEnabled();
      if (!serviceEnabled) {
        _gpsServiceDisabled = true;
        _locationPermissionDenied = true;
        _locationLoading = false;
        notifyListeners();
        return;
      }
      _gpsServiceDisabled = false;

      final result = await LocationService.instance.fetchCurrentLocation();
      if (result == null) {
        _locationPermissionDenied = true;
        _locationLoading = false;
        notifyListeners();
        return;
      }

      _liveLocation = result.address;
      _locationLatitude = result.latitude;
      _locationLongitude = result.longitude;
      _locationPermissionDenied = false;

      // Save to Supabase
      // Agar user ne city khud edit ki hai to GPS use overwrite na kare
      final prefs = await SharedPreferences.getInstance();
      final isManual =
          prefs.getBool('city_manual_${currentUserId ?? ''}') ?? false;
      final autoFill = !isManual || _userCity.trim().isEmpty;

      await SupabaseService.instance.logUserLocation(
        latitude: result.latitude,
        longitude: result.longitude,
        address: result.address,
        updateProfileLocation: autoFill,
      );
      if (autoFill) {
        _userCity = result.address;
      }
    } catch (e) {
      debugPrint('fetchAndSaveLocation error: $e');
      _locationPermissionDenied = true;
    } finally {
      _locationLoading = false;
      notifyListeners();
    }
  }

  /// Load last known location from Supabase (used on app reopen).
  Future<void> loadSavedLocation() async {
    try {
      final saved = await SupabaseService.instance.fetchLatestLocation();
      if (saved != null && saved.isNotEmpty) {
        _liveLocation = saved;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('loadSavedLocation error: $e');
    }
  }

  /// Refresh the data shown by the main app surfaces without resetting cart
  /// state. Location is opt-in so a normal list refresh never surprises users
  /// with a second permission prompt.
  Future<void> refreshAllData({bool refreshLocation = false}) async {
    final jobs = <Future<void>>[
      loadDbBookings(),
      loadDbReviews(),
      refreshUnreadNotificationCount(),
      _loadProfileStats(),
    ];
    if (refreshLocation) jobs.add(fetchAndSaveLocation());
    await Future.wait(jobs);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────────

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} month(s) ago';
    if (diff.inDays > 0) return '${diff.inDays} day(s) ago';
    if (diff.inHours > 0) return '${diff.inHours} hour(s) ago';
    return 'Just now';
  }

  /// Deduct coins from Supabase and update local balance
  Future<bool> deductCoinsFromSupabase({
    required int amount,
    required String description,
  }) async {
    final success = await SupabaseService.instance.deductCoins(
      amount: amount,
      description: description,
    );
    if (success) {
      _coinBalance = (_coinBalance - amount).clamp(0, 999999);
      notifyListeners();
    }
    return success;
  }

  /// DB-backed review eligibility check.
  /// Compares the latest booking date vs the latest review date for this user.
  /// Sets _reviewSubmittedAfterLastBooking = true if a review exists after the latest booking.
  Future<void> checkReviewEligibility() async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      final client = SupabaseService.instance.client;

      // Get latest booking date
      final bookingRows = await client
          .from('bookings')
          .select('created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);

      if ((bookingRows as List).isEmpty) {
        // No bookings — lock review
        _reviewSubmittedAfterLastBooking = true;
        notifyListeners();
        return;
      }

      final latestBookingStr = bookingRows[0]['created_at'] as String?;
      if (latestBookingStr == null) {
        _reviewSubmittedAfterLastBooking = true;
        notifyListeners();
        return;
      }
      final latestBookingDate = DateTime.tryParse(latestBookingStr);
      if (latestBookingDate == null) {
        _reviewSubmittedAfterLastBooking = true;
        notifyListeners();
        return;
      }

      // Get latest review date for this user
      final reviewRows = await client
          .from('reviews')
          .select('created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);

      if ((reviewRows as List).isEmpty) {
        // No reviews yet — user can write one (has bookings)
        _reviewSubmittedAfterLastBooking = false;
        notifyListeners();
        return;
      }

      final latestReviewStr = reviewRows[0]['created_at'] as String?;
      if (latestReviewStr == null) {
        _reviewSubmittedAfterLastBooking = false;
        notifyListeners();
        return;
      }
      final latestReviewDate = DateTime.tryParse(latestReviewStr);
      if (latestReviewDate == null) {
        _reviewSubmittedAfterLastBooking = false;
        notifyListeners();
        return;
      }

      // If latest review is AFTER latest booking → locked
      // If latest booking is AFTER latest review → unlocked
      _reviewSubmittedAfterLastBooking = latestReviewDate.isAfter(
        latestBookingDate,
      );
      notifyListeners();
      debugPrint(
        'checkReviewEligibility: locked=$_reviewSubmittedAfterLastBooking '
        '(lastBooking=$latestBookingDate, lastReview=$latestReviewDate)',
      );
    } catch (e) {
      debugPrint('checkReviewEligibility error: $e');
    }
  }
}
