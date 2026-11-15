import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Remembers (on the device) that the user was signed in last time.
///
/// Why: Google (Clerk) sessions are restored asynchronously a moment after the
/// app opens. Until that finishes the router cannot know the user is logged in,
/// so it used to show the login page for a second and only then jump to the
/// account. With this hint the router goes straight to the signed-in screens on
/// launch and the real session check happens quietly in the background.
class AuthHint {
  AuthHint._();

  static const String _key = 'auth_hint_logged_in';

  /// True when the user was signed in when the app was last used.
  static bool wasLoggedIn = false;

  /// Call once at startup (before the router is first used).
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      wasLoggedIn = prefs.getBool(_key) ?? false;
    } catch (_) {
      wasLoggedIn = false;
    }
  }

  /// Update the hint. Safe to call without awaiting.
  static Future<void> set(bool value) async {
    if (wasLoggedIn == value) {
      // Still persist on the first call after install/update (key missing).
    }
    wasLoggedIn = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (_) {}
  }
}
