import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'clerk/clerk_bridge.dart';
import 'clerk/clerk_http_client.dart';

class ProfileModel {
  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String location;
  final String? avatarUrl;
  final DateTime? updatedAt;
  final bool signupBonusAwarded;

  ProfileModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.location,
    this.avatarUrl,
    this.updatedAt,
    this.signupBonusAwarded = false,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      location: json['location'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      signupBonusAwarded: json['signup_bonus_awarded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'email': email,
    'full_name': fullName,
    'phone_number': phoneNumber,
    'location': location,
    'avatar_url': avatarUrl,
    'updated_at': DateTime.now().toIso8601String(),
  };
}

class BookingRecord {
  final String id;
  final String userId;
  final String serviceName;
  final String date;
  final String bookingDate;
  final String bookingTime;
  final String address;
  final String status;
  final int price;
  final DateTime createdAt;

  BookingRecord({
    required this.id,
    required this.userId,
    required this.serviceName,
    required this.date,
    required this.bookingDate,
    required this.bookingTime,
    required this.address,
    required this.status,
    required this.price,
    required this.createdAt,
  });

  factory BookingRecord.fromJson(Map<String, dynamic> json) {
    return BookingRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      serviceName: json['service_name'] as String? ?? '',
      date: json['date'] as String? ?? '',
      bookingDate:
          json['booking_date'] as String? ?? json['date'] as String? ?? '',
      bookingTime: json['booking_time'] as String? ?? '',
      address: json['address'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      price: json['price'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'service_name': serviceName,
    'date': date,
    'booking_date': bookingDate,
    'booking_time': bookingTime,
    'address': address,
    'status': status,
    'price': price,
  };
}

class ReviewRecord {
  final String id;
  final String userId;
  final String userName;
  final String serviceName;
  final double rating;
  final String reviewText;
  final bool isApproved;
  final DateTime createdAt;

  ReviewRecord({
    required this.id,
    required this.userId,
    this.userName = '',
    required this.serviceName,
    required this.rating,
    required this.reviewText,
    this.isApproved = false,
    required this.createdAt,
  });

  factory ReviewRecord.fromJson(Map<String, dynamic> json) {
    return ReviewRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String? ?? '',
      serviceName: json['service_name'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      reviewText: json['review_text'] as String? ?? '',
      isApproved: json['is_approved'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class CoinTransactionRecord {
  final String id;
  final String userId;
  final int amount;
  final String type;
  final String description;
  final DateTime createdAt;

  CoinTransactionRecord({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  factory CoinTransactionRecord.fromJson(Map<String, dynamic> json) {
    return CoinTransactionRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: json['amount'] as int? ?? 0,
      type: json['type'] as String? ?? 'reward',
      description: json['description'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ServiceRecord {
  final String id;
  final String title;
  final String description;
  final double price;
  final String iconUrl;
  final String category;

  ServiceRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.iconUrl,
    required this.category,
  });

  factory ServiceRecord.fromJson(Map<String, dynamic> json) {
    return ServiceRecord(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      iconUrl: json['icon_url'] as String? ?? '',
      category: json['category'] as String? ?? '',
    );
  }
}
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  // The URL is public configuration. The anon key is injected at Flutter
  // compile time so it can come from Replit Secrets/CI without being kept in
  // source control. Supabase anon keys are client credentials, not service
  // role keys, and are safe to ship in the compiled app.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hudlucmsjyjilkjpviva.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    // Supabase anon keys are public client credentials. Keep this verified
    // project key as a safe first-run fallback; CI/local builds can override
    // it with the workspace secret through tool/flutter_with_env.sh.
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh1ZGx1Y21zanlqaWxranB2aXZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgwMDQwMzksImV4cCI6MjEwMzU4MDAzOX0.nEoVQzbJYD8EF5fQ168KPheIeJRpZMRm02D2zynn86M',
  );

  static Future<void> initialize() async {
    final url = supabaseUrl.trim();
    final anonKey = supabaseAnonKey.trim();
    final parsedUrl = Uri.tryParse(url);

    if (anonKey.isEmpty) {
      throw Exception(
        'SUPABASE_ANON_KEY is missing. Run through '
        'tool/flutter_with_env.sh or pass --dart-define=SUPABASE_ANON_KEY=... .',
      );
    }

    if (parsedUrl == null ||
        parsedUrl.scheme != 'https' ||
        parsedUrl.host.isEmpty ||
        !parsedUrl.host.endsWith('.supabase.co')) {
      throw Exception(
        'SUPABASE_URL must be an HTTPS Supabase project URL.',
      );
    }

    _validateKeyProject(anonKey, parsedUrl.host);
    // On Android/iOS the Clerk session token is attached to data requests when
    // a Google (Clerk) session is active. On web this is null (no change).
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      httpClient: ClerkBridge.isSupported
          ? ClerkTokenHttpClient(ClerkBridge.accessToken)
          : null,
    );
  }

  /// Reject a common configuration error where a key from another project is
  /// paired with this project's URL. Publishable keys are not JWTs and are
  /// intentionally accepted without decoding.
  static void _validateKeyProject(String key, String urlHost) {
    if (key.startsWith('sb_publishable_')) return;

    final parts = key.split('.');
    if (parts.length != 3) {
      throw Exception(
        'SUPABASE_ANON_KEY is not a valid Supabase publishable or JWT key.',
      );
    }

    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final keyProjectRef = payload is Map ? payload['ref'] as String? : null;
      final urlProjectRef = urlHost.split('.').first;

      if (keyProjectRef != null &&
          keyProjectRef.isNotEmpty &&
          keyProjectRef != urlProjectRef) {
        throw Exception(
          'SUPABASE_ANON_KEY belongs to a different Supabase project.',
        );
      }
    } on FormatException {
      throw Exception('SUPABASE_ANON_KEY is not a valid JWT.');
    }
  }

  SupabaseClient get client => Supabase.instance.client;

  /// The signed-in user. For a Google (Clerk) login this is a lightweight
  /// user carrying the shared app user id (same id the website uses).
  User? get currentUser {
    final clerkUserId = ClerkBridge.appUserId;
    if (clerkUserId != null) {
      return User(
        id: clerkUserId,
        appMetadata: const <String, dynamic>{'provider': 'clerk'},
        userMetadata: ClerkBridge.appUserMetadata,
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: ClerkBridge.appUserEmail,
      );
    }
    return client.auth.currentUser;
  }

  bool get isLoggedIn => currentUser != null;

  // ─── AUTH ────────────────────────────────────────────────────────────────
Future<void> sendOtp(String email) async {
  try {
    await client.auth.signInWithOtp(
      email: email.trim().toLowerCase(),
      shouldCreateUser: true,
    );
  } catch (e) {
    // Ye real error print karega aur screen par bhejaega
    throw Exception(e.toString());
  }
}
  Future<AuthResponse> verifyOtp(String email, String token) async {
    return await client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  Future<void> signOut() async {
    if (ClerkBridge.appUserId != null) {
      await ClerkBridge.signOut();
      return;
    }
    await client.auth.signOut();
  }

  // ─── PROFILES ────────────────────────────────────────────────────────────

  Future<ProfileModel?> fetchProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final data = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        await client.from('profiles').insert({
          'id': user.id,
          'email': user.email ?? '',
          'full_name': user.email?.split('@').first ?? '',
          'phone_number': '',
          'location': '',
        });
        // Also initialize user_coins
        await _ensureUserCoins(user.id);
        final created = await client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        return created != null ? ProfileModel.fromJson(created) : null;
      }
      return ProfileModel.fromJson(data);
    } catch (e) {
      debugPrint('fetchProfile error: $e');
      return null;
    }
  }

  Future<void> _ensureUserCoins(String userId) async {
    try {
      final existing = await client
          .from('user_coins')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (existing == null) {
        await client.from('user_coins').insert({
          'user_id': userId,
          'balance': 0,
        });
      }
    } catch (e) {
      debugPrint('_ensureUserCoins error: $e');
    }
  }

  Future<ProfileModel?> updateProfile({
    required String fullName,
    required String phoneNumber,
    required String location,
    String? avatarUrl,
  }) async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final updateData = <String, dynamic>{
        'full_name': fullName,
        'phone_number': phoneNumber,
        'location': location,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

      final data = await client
          .from('profiles')
          .update(updateData)
          .eq('id', user.id)
          .select()
          .maybeSingle();

      return data != null ? ProfileModel.fromJson(data) : null;
    } catch (e) {
      debugPrint('updateProfile error: $e');
      return null;
    }
  }

  // ─── AVATAR UPLOAD ───────────────────────────────────────────────────────

  Future<String?> uploadAvatar(XFile imageFile) async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final ext = imageFile.name.split('.').last.toLowerCase();
      final filePath =
          '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        await client.storage
            .from('avatars')
            .uploadBinary(
              filePath,
              bytes,
              fileOptions: const FileOptions(
                upsert: true,
                contentType: 'image/jpeg',
              ),
            );
      } else {
        await client.storage
            .from('avatars')
            .upload(
              filePath,
              File(imageFile.path),
              fileOptions: const FileOptions(upsert: true),
            );
      }

      final publicUrl = client.storage.from('avatars').getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      debugPrint('uploadAvatar error: $e');
      return null;
    }
  }

  // ─── BOOKINGS ────────────────────────────────────────────────────────────

  Future<List<BookingRecord>> fetchBookings() async {
    final user = currentUser;
    if (user == null) return [];

    try {
      final data = await client
          .from('bookings')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (data as List)
          .map((item) => BookingRecord.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('fetchBookings error: $e');
      return [];
    }
  }

  Future<BookingRecord?> createBooking({
    required String serviceName,
    required String date,
    required String bookingDate,
    required String bookingTime,
    required String address,
    required String status,
    required int price,
  }) async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final data = await client
          .from('bookings')
          .insert({
            'user_id': user.id,
            'service_name': serviceName,
            'date': date,
            'booking_date': bookingDate,
            'booking_time': bookingTime,
            'address': address,
            'status': status,
            'price': price,
          })
          .select()
          .maybeSingle();

      return data != null ? BookingRecord.fromJson(data) : null;
    } catch (e) {
      debugPrint('createBooking error: $e');
      return null;
    }
  }

  Future<bool> deleteBooking(String bookingId) async {
    try {
      await client.from('bookings').delete().eq('id', bookingId);
      return true;
    } catch (e) {
      debugPrint('deleteBooking error: $e');
      return false;
    }
  }

  // ─── REVIEWS ─────────────────────────────────────────────────────────────

  Future<List<ReviewRecord>> fetchReviews() async {
    try {
      // Sirf approved reviews public hain
      final data = await client
          .from('reviews')
          .select()
          .eq('is_approved', true)
          .order('created_at', ascending: false);

      return (data as List)
          .map((item) => ReviewRecord.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('fetchReviews error: $e');
      return [];
    }
  }
  Future<List<ReviewRecord>> fetchMyReviews() async {
    final user = currentUser;
    if (user == null) return [];
    try {
      final data = await client
          .from('reviews')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      return (data as List)
          .map((item) => ReviewRecord.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('fetchMyReviews error: $e');
      return [];
    }
  }
  Future<ReviewRecord?> createReview({
    required String serviceName,
    required double rating,
    required String reviewText,
    String userName = '',
  }) async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final data = await client
          .from('reviews')
          .insert({
            'user_id': user.id,
            'user_name': userName,
            'service_name': serviceName,
            'rating': rating,
            'review_text': reviewText,
            'is_approved': false,
          })
          .select()
          .maybeSingle();

      return data != null ? ReviewRecord.fromJson(data) : null;
    } catch (e) {
      debugPrint('createReview error: $e');
      return null;
    }
  }

  Future<bool> deleteReview(String reviewId) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      await client
          .from('reviews')
          .delete()
          .eq('id', reviewId)
          .eq('user_id', user.id);
      return true;
    } catch (e) {
      debugPrint('deleteReview error: $e');
      return false;
    }
  }

  // ─── USER COINS ──────────────────────────────────────────────────────────

  Future<int> fetchCoinBalance() async {
    final user = currentUser;
    if (user == null) return 0;

    try {
      final data = await client
          .from('user_coins')
          .select('balance')
          .eq('user_id', user.id)
          .maybeSingle();

      if (data == null) {
        await _ensureUserCoins(user.id);
        return 0;
      }
      return data['balance'] as int? ?? 0;
    } catch (e) {
      debugPrint('fetchCoinBalance error: $e');
      return 0;
    }
  }

  Future<bool> addCoins({
    required int amount,
    required String type,
    required String description,
  }) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      // Ensure user_coins row exists
      await _ensureUserCoins(user.id);

      // Get current balance
      final coinData = await client
          .from('user_coins')
          .select('balance')
          .eq('user_id', user.id)
          .maybeSingle();

      final currentBalance = coinData?['balance'] as int? ?? 0;
      final newBalance = currentBalance + amount;

      // Update balance
      await client
          .from('user_coins')
          .update({
            'balance': newBalance,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', user.id);

      // Record transaction
      await client.from('coin_transactions').insert({
        'user_id': user.id,
        'amount': amount,
        'type': type,
        'description': description,
      });

      return true;
    } catch (e) {
      debugPrint('addCoins error: $e');
      return false;
    }
  }

  Future<List<CoinTransactionRecord>> fetchCoinTransactions() async {
    final user = currentUser;
    if (user == null) return [];

    try {
      final data = await client
          .from('coin_transactions')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(50);

      return (data as List)
          .map(
            (item) =>
                CoinTransactionRecord.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('fetchCoinTransactions error: $e');
      return [];
    }
  }

  // ─── SUPPORT TICKETS ─────────────────────────────────────────────────────

  Future<bool> createSupportTicket({
    required String subject,
    required String message,
  }) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      await client.from('support_tickets').insert({
        'user_id': user.id,
        'subject': subject,
        'message': message,
        'status': 'open',
      });
      return true;
    } catch (e) {
      debugPrint('createSupportTicket error: $e');
      return false;
    }
  }

  // ─── SERVICES ────────────────────────────────────────────────────────────

  Future<List<ServiceRecord>> fetchServices() async {
    try {
      final data = await client
          .from('services')
          .select()
          .order('price', ascending: true);

      return (data as List)
          .map((item) => ServiceRecord.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('fetchServices error: $e');
      return [];
    }
  }

  // ─── PROFILE STATS ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchProfileStats() async {
    final user = currentUser;
    if (user == null) return {'bookings': 0, 'coins': 0, 'avgRating': 0.0};

    try {
      // Fetch bookings count
      final bookingsResp = await client
          .from('bookings')
          .select('id')
          .eq('user_id', user.id);
      final bookingsCount = (bookingsResp as List).length;

      // Fetch coin balance
      final coinBalance = await fetchCoinBalance();

      // Fetch average rating
      final reviewsData = await client
          .from('reviews')
          .select('rating')
          .eq('user_id', user.id);

      double avgRating = 0.0;
      if ((reviewsData as List).isNotEmpty) {
        final total = reviewsData.fold<double>(
          0,
          (sum, r) => sum + ((r['rating'] as num?)?.toDouble() ?? 0),
        );
        avgRating = total / reviewsData.length;
      }

      return {
        'bookings': bookingsCount,
        'coins': coinBalance,
        'avgRating': avgRating,
      };
    } catch (e) {
      debugPrint('fetchProfileStats error: $e');
      return {'bookings': 0, 'coins': 0, 'avgRating': 0.0};
    }
  }

  // ─── USER LOCATIONS ──────────────────────────────────────────────────────

  Future<void> logUserLocation({
    required double latitude,
    required double longitude,
    required String address,
    bool updateProfileLocation = true,
  }) async {
    final user = currentUser;
    if (user == null) return;

    try {
      await client.from('user_locations').insert({
        'user_id': user.id,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      });

      if (updateProfileLocation) {
        await client
            .from('profiles')
            .update({
              'location': address,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', user.id);
      }
    } catch (e) {
      debugPrint('logUserLocation error: $e');
    }
  }

  Future<String?> fetchLatestLocation() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final data = await client
          .from('user_locations')
          .select('address')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return data?['address'] as String?;
    } catch (e) {
      debugPrint('fetchLatestLocation error: $e');
      return null;
    }
  }

  // ─── FIRST-TIME SETUP ────────────────────────────────────────────────────

  /// Called after first OTP verification to ensure profile + coins are initialized.
  /// Returns true if this is a brand-new user (first time setup).
  Future<bool> ensureFirstTimeSetup() async {
    final user = currentUser;
    if (user == null) return false;

    bool isNewUser = false;

    try {
      // Ensure profile exists
      final profileData = await client
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (profileData == null) {
        await client.from('profiles').insert({
          'id': user.id,
          'email': user.email ?? '',
          'full_name': user.email?.split('@').first ?? '',
          'phone_number': '',
          'location': '',
          'signup_bonus_awarded': false,
        });
        isNewUser = true;
      } else {
        // Update email if missing
        await client
            .from('profiles')
            .update({'email': user.email ?? ''})
            .eq('id', user.id)
            .eq('email', '');
      }

      // Ensure user_coins row exists
      await _ensureUserCoins(user.id);
    } catch (e) {
      debugPrint('ensureFirstTimeSetup error: $e');
    }

    return isNewUser;
  }

  Future<void> markSignupBonusAwarded() async {
    final user = currentUser;
    if (user == null) return;
    try {
      await client
          .from('profiles')
          .update({'signup_bonus_awarded': true})
          .eq('id', user.id);
    } catch (e) {
      debugPrint('markSignupBonusAwarded error: $e');
    }
  }

  Future<void> saveNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
  }) async {
    try {
      await client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
      });
    } catch (e) {
      debugPrint('saveNotification error: $e');
    }
  }

  // ─── COUPONS ─────────────────────────────────────────────────────────────

  /// Validate a coupon code for a given user.
  /// Returns: { 'valid': bool, 'discount': int, 'message': String, 'couponId': String? }
  Future<Map<String, dynamic>> validateCoupon({
    required String code,
    required String userId,
    int tankCount = 0,
  }) async {
    if (code.trim().isEmpty) {
      return {'valid': false, 'discount': 0, 'message': 'Enter a coupon code'};
    }

    try {
      final upperCode = code.trim().toUpperCase();

      // TANK500 is strictly restricted to 3+ tanks
      if (upperCode == 'TANK500' && tankCount < 3) {
        return {
          'valid': false,
          'discount': 0,
          'message': 'TANK500 requires 3 or more tanks to be selected',
        };
      }

      // Check coupons table
      final data = await client
          .from('coupons')
          .select()
          .eq('code', upperCode)
          .eq('is_active', true)
          .maybeSingle();

      if (data == null) {
        return {
          'valid': false,
          'discount': 0,
          'message': 'Invalid or expired coupon code',
        };
      }

      // Check expiry
      final expiresAt = data['expires_at'] as String?;
      if (expiresAt != null) {
        final expiry = DateTime.tryParse(expiresAt);
        if (expiry != null && expiry.isBefore(DateTime.now())) {
          return {
            'valid': false,
            'discount': 0,
            'message': 'This coupon has expired',
          };
        }
      }

      // Check usage limit
      final maxUses = data['max_uses'] as int?;
      final usedCount = data['used_count'] as int? ?? 0;
      if (maxUses != null && usedCount >= maxUses) {
        return {
          'valid': false,
          'discount': 0,
          'message': 'Coupon usage limit reached',
        };
      }

      // For WEL100 — only valid on first booking.
      // Uses a server-side check that also counts bookings the user has
      // removed from "My Bookings" (hidden bookings still count).
      if (upperCode == 'WEL100') {
        bool hasBooking;
        try {
          final res = await client.rpc('current_user_has_booking');
          hasBooking = res == true;
        } catch (_) {
          final bookingCount = await client
              .from('bookings')
              .select('id')
              .eq('user_id', userId);
          hasBooking = (bookingCount as List).isNotEmpty;
        }
        if (hasBooking) {
          return {
            'valid': false,
            'discount': 0,
            'message': 'WEL100 is only valid on your first booking',
          };
        }
      }

      final discount = data['discount_amount'] as int? ?? 0;
      return {
        'valid': true,
        'discount': discount,
        'message': '🎉 Coupon applied! ₹$discount off',
        'couponId': data['id'] as String?,
      };
    } catch (e) {
      debugPrint('validateCoupon error: $e');
      return {
        'valid': false,
        'discount': 0,
        'message': 'Could not validate coupon. Try again.',
      };
    }
  }

  /// Deduct coins from user_coins balance in Supabase
  Future<bool> deductCoins({
    required int amount,
    required String description,
  }) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      await _ensureUserCoins(user.id);

      final coinData = await client
          .from('user_coins')
          .select('balance')
          .eq('user_id', user.id)
          .maybeSingle();

      final currentBalance = coinData?['balance'] as int? ?? 0;
      final newBalance = (currentBalance - amount).clamp(0, 999999);

      await client
          .from('user_coins')
          .update({
            'balance': newBalance,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', user.id);

      // Record deduction transaction
      await client.from('coin_transactions').insert({
        'user_id': user.id,
        'amount': -amount,
        'type': 'deduction',
        'description': description,
      });

      return true;
    } catch (e) {
      debugPrint('deductCoins error: $e');
      return false;
    }
  }

  /// Check if welcome notification was already sent to this user
  Future<bool> hasWelcomeNotification(String userId) async {
    try {
      final data = await client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('type', 'welcome')
          .limit(1);
      return (data as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Mark coupon as used (increment used_count)
  Future<void> markCouponUsed(String couponId) async {
    try {
      await client.rpc(
        'increment_coupon_usage',
        params: {'coupon_id': couponId},
      );
    } catch (e) {
      // Fallback: manual increment
      try {
        final data = await client
            .from('coupons')
            .select('used_count')
            .eq('id', couponId)
            .maybeSingle();
        final current = data?['used_count'] as int? ?? 0;
        await client
            .from('coupons')
            .update({'used_count': current + 1})
            .eq('id', couponId);
      } catch (e2) {
        debugPrint('markCouponUsed fallback error: $e2');
      }
    }
  }

  /// Fetch the latest active featured coupon for display in profile
  Future<Map<String, dynamic>?> fetchActiveFeaturedCoupon() async {
    try {
      final data = await client
          .from('coupons')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('fetchActiveFeaturedCoupon error: $e');
      return null;
    }
  }
}
