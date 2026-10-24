import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'clerk_types.dart';

/// Public identifier (same key the website uses). Can be overridden with
/// --dart-define=CLERK_PUBLISHABLE_KEY=... for the live instance.
const String _publishableKey = String.fromEnvironment(
  'CLERK_PUBLISHABLE_KEY',
  defaultValue:
      'pk_test_Z2xhZC1nYW5uZXQtODI3OC5jbGVyay5hY2NvdW50cy5kZXYk',
);

/// Connects Clerk (Google sign-in) to the app's Supabase user model.
/// A Clerk user is mapped to the same app user id as on the website via the
/// `ensure_clerk_profile` Supabase function.
class ClerkBridge {
  ClerkBridge._();

  static const bool isSupported = true;

  static const String _redirectScheme = 'maintix';
  static const String _redirectHost = 'auth';
  static const String _oauthPath = '/oauth';

  static final StreamController<ClerkBridgeEvent> _events =
      StreamController<ClerkBridgeEvent>.broadcast();
  static Stream<ClerkBridgeEvent> get events => _events.stream;

  static ClerkAuthState? _auth;
  static String? _appUserId;
  static String? _appUserEmail;
  static Map<String, dynamic> _appUserMetadata = <String, dynamic>{};
  static String? _linkedClerkId;
  static bool _syncing = false;
  static bool _syncAgain = false;
  static DateTime? _freshSince;
  static Timer? _realtimeTimer;

  static String? get appUserId => _appUserId;
  static String? get appUserEmail => _appUserEmail;
  static Map<String, dynamic> get appUserMetadata => _appUserMetadata;
  static bool get hasSession => _auth?.session != null;

  static final ClerkAuthConfig _config = ClerkAuthConfig(
    publishableKey: _publishableKey,
    redirectionGenerator: _redirectFor,
    // uriLinkStream exists in every app_links 6.x/7.x release. The OAuth
    // redirect arrives while the app is already running, so this is enough.
    deepLinkStream: AppLinks().uriLinkStream.asyncMap(_filterDeepLink),
  );

  static Uri? _redirectFor(BuildContext context, clerk.Strategy strategy) {
    if (strategy.isOauth) {
      return Uri(
        scheme: _redirectScheme,
        host: _redirectHost,
        path: _oauthPath,
      );
    }
    return null;
  }

  static Future<Uri?> _filterDeepLink(Uri uri) async {
    if (uri.scheme == _redirectScheme &&
        uri.host == _redirectHost &&
        uri.path == _oauthPath) {
      return uri;
    }
    return null;
  }

  /// Wrap the whole app so Clerk is initialised once.
  static Widget wrap(Widget child) =>
      ClerkAuth(config: _config, child: _ClerkCapture(child: child));

  static void _attach(ClerkAuthState state) {
    if (identical(_auth, state)) return;
    _auth?.removeListener(_onClerkChanged);
    _auth = state;
    state.addListener(_onClerkChanged);
    _onClerkChanged();
  }

  static void _onClerkChanged() {
    unawaited(_sync());
  }

  static Future<void> _sync() async {
    final auth = _auth;
    if (auth == null) return;
    if (_syncing) {
      _syncAgain = true;
      return;
    }
    _syncing = true;
    try {
      do {
        _syncAgain = false;
        final user = auth.user;
        if (user != null && auth.session != null) {
          if (_appUserId == null || _linkedClerkId != user.id) {
            await _link(auth, user.id);
          }
        } else if (_appUserId != null) {
          _signedOut();
        }
      } while (_syncAgain);
    } catch (e) {
      debugPrint('Clerk sync error: $e');
    } finally {
      _syncing = false;
    }
  }

  static Future<void> _link(ClerkAuthState auth, String? clerkId) async {
    try {
      final tokenObj = await auth.sessionToken();
      final jwt = tokenObj.jwt;
      final claims = _claims(jwt);
      final email = (claims['email'] as String? ?? '').toLowerCase();
      if (email.isEmpty) {
        throw StateError('email claim missing in Clerk session token');
      }

      final res = await Supabase.instance.client.rpc('ensure_clerk_profile');
      final uid = res is String ? res : null;
      if (uid == null || uid.isEmpty) {
        throw StateError('ensure_clerk_profile returned no user id');
      }

      _appUserId = uid;
      _appUserEmail = email;
      _appUserMetadata = <String, dynamic>{
        'full_name': claims['full_name'] ?? '',
        'avatar_url': claims['avatar'] ?? '',
      };
      _linkedClerkId = clerkId;

      _setRealtimeAuth(jwt);
      _realtimeTimer?.cancel();
      _realtimeTimer = Timer.periodic(const Duration(seconds: 45), (_) async {
        final t = await accessToken();
        if (t != null) _setRealtimeAuth(t);
      });

      _events.add(
        ClerkBridgeEvent(
          _takeFresh()
              ? ClerkBridgeEventType.signedIn
              : ClerkBridgeEventType.initialSession,
          userId: uid,
        ),
      );
    } catch (e) {
      debugPrint('Clerk link failed: $e');
      final message = '$e'.contains('email claim')
          ? 'Sign-in setup incomplete: Clerk session token needs the email claim.'
          : 'Google sign-in could not be completed. Please try again.';
      _events.add(ClerkBridgeEvent(ClerkBridgeEventType.error, message: message));
      try {
        await auth.signOut();
      } catch (_) {}
    }
  }

  static void _setRealtimeAuth(String jwt) {
    try {
      unawaited(
        Future<void>.sync(() => Supabase.instance.client.realtime.setAuth(jwt)),
      );
    } catch (e) {
      debugPrint('Realtime setAuth error: $e');
    }
  }

  static bool _takeFresh() {
    final t = _freshSince;
    _freshSince = null;
    return t != null &&
        DateTime.now().difference(t) < const Duration(minutes: 10);
  }

  static Map<String, dynamic> _claims(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return <String, dynamic>{};
      final decoded = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      return decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static void _signedOut() {
    _realtimeTimer?.cancel();
    _realtimeTimer = null;
    _appUserId = null;
    _appUserEmail = null;
    _appUserMetadata = <String, dynamic>{};
    _linkedClerkId = null;
    _events.add(const ClerkBridgeEvent(ClerkBridgeEventType.signedOut));
  }

  /// Current Clerk session token, or null when no Clerk session is active.
  static Future<String?> accessToken() async {
    final auth = _auth;
    if (auth == null || auth.session == null) return null;
    try {
      final tokenObj = await auth.sessionToken();
      return tokenObj.jwt;
    } catch (_) {
      return null;
    }
  }

  static Future<void> signInWithGoogle(BuildContext context) async {
    final auth = _auth ?? ClerkAuth.of(context);
    _freshSince = DateTime.now();
    await auth.ssoSignIn(context, clerk.Strategy.oauthGoogle);
  }

  static Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (e) {
      debugPrint('Clerk signOut error: $e');
    }
    if (_appUserId != null) _signedOut();
  }
}

class _ClerkCapture extends StatefulWidget {
  const _ClerkCapture({required this.child});

  final Widget child;

  @override
  State<_ClerkCapture> createState() => _ClerkCaptureState();
}

class _ClerkCaptureState extends State<_ClerkCapture> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ClerkBridge._attach(ClerkAuth.of(context));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
