import 'supabase_service.dart';

/// Extra home-screen data (same tables the website reads).
class HomeDataService {
  HomeDataService._();

  /// Active, not expired, not used-up coupons (same filter as the website).
  static Future<List<Map<String, dynamic>>> fetchActiveCoupons() async {
    try {
      final data = await SupabaseService.instance.client
          .from('coupons')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);
      final now = DateTime.now();
      final list = (data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((c) {
            final ex = c['expires_at'] as String?;
            if (ex != null) {
              final d = DateTime.tryParse(ex);
              if (d != null && d.isBefore(now)) return false;
            }
            final max = c['max_uses'];
            final used = (c['used_count'] as num?)?.toInt() ?? 0;
            if (max is num && used >= max) return false;
            return true;
          })
          .toList();
      return list;
    } catch (_) {
      return [];
    }
  }

  /// Personal referral code (same RPC the website uses).
  static Future<String?> myReferralCode() async {
    try {
      final r = await SupabaseService.instance.client.rpc(
        'get_my_referral_code',
      );
      if (r == null) return null;
      final s = r.toString();
      return s.isEmpty ? null : s;
    } catch (_) {
      return null;
    }
  }

  /// Referral summary for the Profile page (same RPC the website uses):
  /// code, invited, rewarded, pending, coins_earned, referred_by, items.
  static Future<Map<String, dynamic>?> myReferralSummary() async {
    try {
      final r = await SupabaseService.instance.client.rpc(
        'my_referral_summary',
      );
      if (r is Map) return Map<String, dynamic>.from(r);
      return null;
    } catch (_) {
      return null;
    }
  }
}
