// Mobile implementation using razorpay_flutter SDK
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

Future<void> launchRazorpayCheckout({
  required BuildContext context,
  required String keyId,
  required String orderId,
  required int amountInPaise,
  required String email,
  required String contact,
  required Function(String paymentId, String orderId, String signature)
  onSuccess,
  required Function(String errorMsg) onFailure,
}) async {
  final razorpay = Razorpay();

  razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (
    PaymentSuccessResponse response,
  ) {
    razorpay.clear();
    onSuccess(
      response.paymentId ?? '',
      response.orderId ?? orderId,
      response.signature ?? '',
    );
  });

  razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
    razorpay.clear();
    onFailure(response.message ?? 'Payment failed');
  });

  razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (
    ExternalWalletResponse response,
  ) {
    razorpay.clear();
    onFailure('External wallet selected: ${response.walletName}');
  });

  final options = {
    'key': keyId,
    'amount': amountInPaise,
    'currency': 'INR',
    'order_id': orderId,
    'name': 'Homaclo',
    'description': 'Water Tank Cleaning Service',
    'prefill': {'email': email, 'contact': contact},
    'theme': {'color': '#072654'},
    // With retry fully disabled, Razorpay's native checkout activity
    // declares any transient hiccup (slow UPI confirmation, momentary
    // gateway blip) an immediate "Payment Failed" and closes straight
    // away — before our own EVENT_PAYMENT_ERROR handler, and often before
    // the bank/UPI app has actually finished confirming. Allowing exactly
    // one automatic retry gives Razorpay's own SDK a moment to re-check
    // before it gives up and shows that screen, which is what we want for
    // the common "payment actually went through, first check was just
    // slow" case this app already backs up with webhook-status polling
    // (see _handlePaymentFailure) either way.
    'retry': {'enabled': true, 'max_count': 1},
    // Give slow UPI confirmations more time before being treated as a
    // failure at all.
    'timeout': 300,
  };

  try {
    razorpay.open(options);
  } catch (e) {
    razorpay.clear();
    onFailure('Failed to open Razorpay: $e');
  }
}
