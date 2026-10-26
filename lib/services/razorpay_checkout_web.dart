// Web implementation using the Razorpay JS SDK via dart:js_interop.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';

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
  try {
    // Check if Razorpay JS SDK is loaded (script tag in web/index.html)
    if (!globalContext.has('Razorpay')) {
      onFailure('Razorpay SDK not loaded. Please refresh and try again.');
      return;
    }

    // Register global callbacks that JS can call back into Dart
    globalContext['_rzpOnSuccess'] =
        ((JSString paymentId, JSString rzpOrderId, JSString signature) {
          onSuccess(paymentId.toDart, rzpOrderId.toDart, signature.toDart);
        }).toJS;

    globalContext['_rzpOnFailure'] = ((JSString errorMsg) {
      onFailure(errorMsg.toDart);
    }).toJS;

    // Build and open Razorpay checkout via JS eval
    final script =
        '''
      (function() {
        try {
          var options = {
            key: "$keyId",
            amount: $amountInPaise,
            currency: "INR",
            order_id: "$orderId",
            name: "Homaclo",
            description: "Water Tank Cleaning Service",
            prefill: {
              email: "$email",
              contact: "$contact"
            },
            theme: { color: "#072654" },
            // With retry fully disabled, Razorpay's checkout declares any
            // transient hiccup (slow UPI confirmation, momentary gateway
            // blip) an immediate "Payment Failed" and closes straight away
            // — before our own payment.failed handler below, and often
            // before the bank/UPI app has actually finished confirming.
            // Allowing exactly one automatic retry gives Razorpay's own
            // checkout a moment to re-check before it gives up and shows
            // that screen, which is what we want for the common "payment
            // actually went through, first check was just slow" case this
            // app already backs up with webhook-status polling
            // (_handlePaymentFailure) either way.
            retry: { enabled: true, max_count: 1 },
            // Give slow UPI confirmations more time before being treated as
            // a failure at all.
            timeout: 300,
            handler: function(response) {
              if (window._rzpOnSuccess) {
                window._rzpOnSuccess(
                  response.razorpay_payment_id || "",
                  response.razorpay_order_id || "$orderId",
                  response.razorpay_signature || ""
                );
              }
            },
            modal: {
              ondismiss: function() {
                if (window._rzpOnFailure) {
                  window._rzpOnFailure("Payment cancelled by user");
                }
              }
            }
          };
          var rzp = new Razorpay(options);
          rzp.on("payment.failed", function(response) {
            if (window._rzpOnFailure) {
              window._rzpOnFailure(response.error.description || "Payment failed");
            }
          });
          rzp.open();
        } catch(e) {
          if (window._rzpOnFailure) {
            window._rzpOnFailure("Razorpay error: " + e.message);
          }
        }
      })();
    ''';

    globalContext.callMethod<JSAny?>('eval'.toJS, script.toJS);
  } catch (e) {
    onFailure('Failed to launch Razorpay: $e');
  }
}
