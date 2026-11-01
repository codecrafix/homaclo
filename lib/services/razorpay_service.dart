import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

class RazorpayService {
  static RazorpayService? _instance;
  static RazorpayService get instance => _instance ??= RazorpayService._();
  RazorpayService._();

  /// Optional fallback public Razorpay key (build-time `RAZORPAY_KEY_ID`),
  /// used only if the server does not return one. Prefer the `key` returned
  /// by [createOrder] — it is guaranteed to match the account/mode that
  /// actually created the order, which avoids "Payment could not be
  /// completed" errors caused by a key mismatch between order creation
  /// (server) and checkout (client).
  ///
  /// There is intentionally no hardcoded default: a live build must never
  /// silently fall back to a test key.
  static const String keyId = String.fromEnvironment('RAZORPAY_KEY_ID');

  /// Step 1: Create a Razorpay order through the Supabase Edge Function.
  ///
  /// [amountRupees] — amount in rupees (e.g. 499). Converted strictly to paise internally.
  /// [cartSnapshot] — a snapshot of what's being booked (tanks, date, time
  /// slot, address, service name). The server stores this alongside the
  /// order so that if the app never receives a payment success/failure
  /// callback (killed mid-UPI-flow, dropped network, etc.), the Razorpay
  /// webhook can still create the correct booking once the payment is
  /// confirmed as captured — instead of the booking silently being lost and
  /// the user hitting Razorpay's "order already paid" error on retry.
  /// Returns a map with 'id' (order id) and 'key' (the exact public key that
  /// created the order) on success, null on failure.
  Future<Map<String, String>?> createOrder({
    required int amountRupees,
    String currency = 'INR',
    String? receipt,
    Map<String, dynamic>? cartSnapshot,
  }) async {
    // Strict paise conversion: multiply rupees by 100
    final int amountInPaise = amountRupees * 100;

    debugPrint(
      '[Razorpay] Creating order: ₹$amountRupees = $amountInPaise paise',
    );

    try {
      final response = await SupabaseService.instance.client.functions.invoke(
        'create-razorpay-order',
        body: {
          'amount': amountInPaise,
          'currency': currency,
          'receipt': receipt ?? 'rcpt_${DateTime.now().millisecondsSinceEpoch}',
          if (cartSnapshot != null) 'cartSnapshot': cartSnapshot,
        },
      );

      final data = response.data;
      final body = data is Map
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{};
      final orderId = body['id'] as String?;
      final serverKey = body['key'] as String?;
      final checkoutKey = (serverKey != null && serverKey.isNotEmpty)
          ? serverKey
          : keyId;
      if (orderId != null && orderId.isNotEmpty) {
        if (checkoutKey.isEmpty) {
          debugPrint(
            '[Razorpay] Order $orderId created but no Razorpay key is available for checkout',
          );
          return null;
        }
        debugPrint('[Razorpay] Order created: $orderId');
        return {'id': orderId, 'key': checkoutKey};
      }
      debugPrint('[Razorpay] Edge Function returned no order id: $data');
    } catch (e) {
      debugPrint('[Razorpay] createOrder error: $e');
    }
    return null;
  }

  /// Verify the checkout signature on the server before confirming a booking.
  Future<bool> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    if (orderId.isEmpty || paymentId.isEmpty || signature.isEmpty) return false;
    try {
      final response = await SupabaseService.instance.client.functions.invoke(
        'verify-razorpay-payment',
        body: {
          'orderId': orderId,
          'paymentId': paymentId,
          'signature': signature,
        },
      );
      final data = response.data;
      return data is Map && data['verified'] == true;
    } catch (e) {
      debugPrint('[Razorpay] verifyPayment error: $e');
      return false;
    }
  }

  /// Look up the current status of an order's payment row directly (RLS
  /// scoped to the signed-in user, so this is safe to call from the app).
  ///
  /// Used after Razorpay's checkout reports a failure/cancellation — before
  /// showing the user a scary "payment failed, try again" message, we check
  /// whether the Razorpay webhook has *already* reconciled this exact order
  /// as SUCCESS in the background (which happens when the money was in fact
  /// captured but the client-side callback never arrived). If so, the
  /// booking already exists and the user should see success, not failure.
  ///
  /// Returns a map with 'status' ('PENDING' | 'SUCCESS' | 'FAILED') and
  /// optional 'bookingId', or null if the row can't be found/read.
  Future<Map<String, dynamic>?> checkOrderStatus(String orderId) async {
    if (orderId.isEmpty) return null;
    try {
      final data = await SupabaseService.instance.client
          .from('payments')
          .select('status, booking_id, razorpay_payment_id')
          .eq('razorpay_order_id', orderId)
          .maybeSingle();
      if (data == null) return null;
      return {
        'status': data['status'] as String? ?? 'PENDING',
        'bookingId': data['booking_id'] as String?,
        'paymentId': data['razorpay_payment_id'] as String?,
      };
    } catch (e) {
      debugPrint('[Razorpay] checkOrderStatus error: $e');
      return null;
    }
  }

  /// Step 2: Record successful payment in Supabase.
  /// Updates the PENDING row created by create-razorpay-order to SUCCESS
  /// and updates booking status to CONFIRMED.
  ///
  /// [amountInPaise] — amount already in paise as stored/returned from createOrder flow.
  Future<bool> recordPaymentSuccess({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required int amountInPaise,
    String? bookingId,
  }) async {
    try {
      final user = SupabaseService.instance.currentUser;
      if (user == null) return false;

      final client = SupabaseService.instance.client;

      // UPDATE the PENDING row from order creation rather than inserting a
      // new one — `payments.razorpay_order_id` is now unique, and this is
      // also what keeps this row and the webhook's reconciliation from ever
      // racing into two rows for the same order.
      await client
          .from('payments')
          .update({
            'razorpay_payment_id': razorpayPaymentId,
            'booking_id': bookingId,
            'status': 'SUCCESS',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('razorpay_order_id', razorpayOrderId);

      if (bookingId != null && bookingId.isNotEmpty) {
        await client
            .from('bookings')
            .update({'status': 'CONFIRMED'})
            .eq('id', bookingId);
      }

      return true;
    } catch (e) {
      debugPrint('[Razorpay] recordPaymentSuccess error: $e');
      return false;
    }
  }

  /// Record a failed/pending payment attempt.
  Future<void> recordPaymentFailure({
    required String razorpayOrderId,
    int amountInPaise = 0,
    String? bookingId,
  }) async {
    try {
      final user = SupabaseService.instance.currentUser;
      if (user == null) return;

      // UPDATE the PENDING row rather than inserting a new one (see note in
      // recordPaymentSuccess). If the webhook already reconciled this order
      // as SUCCESS in the background, this deliberately does NOT overwrite
      // that — only PENDING rows are moved to FAILED.
      await SupabaseService.instance.client
          .from('payments')
          .update({
            'status': 'FAILED',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('razorpay_order_id', razorpayOrderId)
          .eq('status', 'PENDING');
    } catch (e) {
      debugPrint('[Razorpay] recordPaymentFailure error: $e');
    }
  }
}
