import 'dart:async';

import 'package:flutter/foundation.dart';

import './supabase_service.dart';

/// Wakes up the payment Edge Functions while the user is still reviewing the
/// bill, so the first tap on "Pay" (order creation) and the confirmation right
/// after paying (signature verification) do not pay the cold-start cost.
///
/// The calls carry no body, so the functions reject them immediately with a
/// 400 (no Razorpay order is created, nothing is written). Errors are ignored.
class EdgeWarmup {
  EdgeWarmup._();

  static DateTime? _last;

  static void payments() {
    final now = DateTime.now();
    final last = _last;
    if (last != null && now.difference(last) < const Duration(minutes: 4)) {
      return;
    }
    _last = now;
    try {
      final functions = SupabaseService.instance.client.functions;
      for (final name in const [
        'create-razorpay-order',
        'verify-razorpay-payment',
      ]) {
        unawaited(
          functions.invoke(name).then<void>((_) {}).catchError((Object e) {
            debugPrint('[warmup] $name: $e');
          }),
        );
      }
    } catch (e) {
      debugPrint('[warmup] failed: $e');
    }
  }
}
