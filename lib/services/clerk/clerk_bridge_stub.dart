import 'dart:async';

import 'package:flutter/widgets.dart';

import 'clerk_types.dart';

/// Web stub: Clerk is not used inside the Flutter web build.
class ClerkBridge {
  ClerkBridge._();

  static const bool isSupported = false;

  static Stream<ClerkBridgeEvent> get events =>
      const Stream<ClerkBridgeEvent>.empty();

  static String? get appUserId => null;
  static String? get appUserEmail => null;
  static Map<String, dynamic> get appUserMetadata => const <String, dynamic>{};
  static bool get hasSession => false;

  static Widget wrap(Widget child) => child;

  static Future<String?> accessToken() async => null;

  static Future<void> signInWithGoogle(BuildContext context) async {}

  static Future<void> signOut() async {}
}
