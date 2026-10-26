import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './providers/app_state.dart';
import './routes/app_routes.dart';
import './services/clerk/clerk_bridge.dart';
import './services/notification_service.dart';
import './services/supabase_service.dart';
import './widgets/custom_error_widget.dart';
import './widgets/global_tap_effect.dart';
import 'core/app_export.dart';

/// OneSignal App ID — from OneSignal dashboard (Settings > Keys & IDs) for
/// the "Homaclo App". Safe to keep in source; it is a public identifier,
/// not a secret (unlike the REST API key, which only ever lives server-side
/// in the Supabase Edge Function).
const String _oneSignalAppId = 'a791ea02-af27-4af4-9a9e-a8c062f960eb';

void main() {
  // CRITICAL: Must be the very first call before any async work or plugin use.
  WidgetsFlutterBinding.ensureInitialized();
  // Render a branded, animated boot surface immediately while services load.
  runApp(const _BootSplash());

  runZonedGuarded(
    () async {
      bool hasShownError = false;

      // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
      ErrorWidget.builder = (FlutterErrorDetails details) {
        if (!hasShownError) {
          hasShownError = true;
          Future.delayed(const Duration(seconds: 5), () {
            hasShownError = false;
          });
          return CustomErrorWidget(errorDetails: details);
        }
        return const SizedBox.shrink();
      };

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('Flutter error caught: ${details.exceptionAsString()}');
      };

      // Initialize Supabase before creating the authenticated app shell.
      String? startupError;
      try {
        await SupabaseService.initialize();
      } catch (e, stack) {
        startupError = 'Supabase init failed:\n$e\n\nStack:\n$stack';
        debugPrint('Supabase init error: $e\n$stack');
      }

      // Initialize OneSignal push notifications (real push — works even
      // when the app is closed or killed, unlike the old local-only setup).
      // OneSignal's Flutter plugin has no web implementation, so the web
      // build skips it (in-app notifications still arrive via Supabase
      // Realtime).
      if (!kIsWeb) {
        try {
          OneSignal.Debug.setLogLevel(OSLogLevel.error);
          OneSignal.initialize(_oneSignalAppId);
          await OneSignal.Notifications.requestPermission(true);
        } catch (e) {
          debugPrint('OneSignal init error (non-fatal): $e');
        }
      }

      // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

      GoRouter.optionURLReflectsImperativeAPIs = true;

      // If Supabase failed to initialize, show the actual error on screen
      if (startupError != null) {
        runApp(StartupErrorApp(errorMessage: startupError));
        return;
      }

      runApp(const MyApp());
    },
    (Object error, StackTrace stack) {
      debugPrint('Uncaught error: $error\n$stack');
      // Show the actual error on screen for uncaught zone errors
      runApp(
        StartupErrorApp(
          errorMessage: 'Uncaught startup error:\n$error\n\nStack:\n$stack',
        ),
      );
    },
  );
}

class _BootSplash extends StatelessWidget {
  const _BootSplash();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/maintix_m_logo.png',
                width: 132,
                height: 132,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 28),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF00A8CC),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Displayed when a fatal startup error occurs — shows the ACTUAL error
/// message so it can be diagnosed immediately without needing logcat.
class StartupErrorApp extends StatelessWidget {
  final String errorMessage;
  const StartupErrorApp({required this.errorMessage, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFFF6B6B),
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Startup Error',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'The app failed to start. Copy the error below and share it for debugging:',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFFAAAAAA),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0D1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF6B6B).withAlpha(102),
                    ),
                  ),
                  child: SelectableText(
                    errorMessage,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 11,
                      color: const Color(0xFFFF6B6B),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Common fixes:\n'
                  '• Verify the Supabase URL and anon key belong to the same project\n'
                  '• Optional: override them with --dart-define values\n'
                  '• Check GitHub Actions secrets are correctly mapped',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF888888),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// On wide desktop browser windows the phone-style UI would stretch across
/// the whole screen. This keeps the entire app (including dialogs and
/// bottom sheets) inside a centered, phone-width column with a branded
/// backdrop. On phones, narrow windows and native builds it does nothing.
class _WebFrame extends StatelessWidget {
  final Widget child;
  const _WebFrame({required this.child});

  static const double _maxWidth = 480;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= _maxWidth + 40) return child;
        final height = constraints.maxHeight;
        return ColoredBox(
          color: const Color(0xFF0B1B33),
          child: Center(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(color: Color(0x66000000), blurRadius: 40),
                ],
              ),
              child: ClipRect(
                child: SizedBox(
                  width: _maxWidth,
                  height: height,
                  child: MediaQuery.fromView(
                    view: View.of(context),
                    child: Builder(
                      builder: (context) {
                        final media = MediaQuery.of(context);
                        return MediaQuery(
                          data: media.copyWith(size: Size(_maxWidth, height)),
                          child: child,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppState _appState;
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<ClerkBridgeEvent>? _clerkSubscription;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
    _appState.loadThemePreference();
    _initAuthListener();
    _initClerkListener();
    // Apply initial system UI overlay for light mode
    AppTheme.applySystemUI(ThemeMode.light);
  }

  void _initAuthListener() {
    // Guard the listener so a transient plugin/auth initialization error does
    // not prevent the rest of the app shell from rendering.
    try {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen((data) async {
            final event = data.event;
            final session = data.session;

            debugPrint('Auth event: $event');

            if (event == AuthChangeEvent.signedIn && session != null) {
              // Email-OTP login wins: drop any leftover Google (Clerk) session
              // so its token is never attached to this user's requests.
              if (ClerkBridge.appUserId != null) {
                unawaited(ClerkBridge.signOut());
              }
              // Link this device to the user BEFORE login runs, so the welcome /
              // bonus pushes created during first-time setup can reach it.
              _linkOneSignalIdentity(session.user.id);
              if (!_appState.isLoggedIn) {
                await _appState.loginWithSupabase();
              }
              _subscribeToNotifications(session.user.id);
              if (_initialized &&
                  appRouter.routerDelegate.currentConfiguration.uri
                          .toString() !=
                      AppRoutes.homeScreen) {
                final currentPath = appRouter
                    .routerDelegate
                    .currentConfiguration
                    .uri
                    .toString();
                if (currentPath == AppRoutes.initial ||
                    currentPath == AppRoutes.signUpLoginScreen ||
                    currentPath == AppRoutes.otpVerifyScreen) {
                  appRouter.go(AppRoutes.homeScreen);
                }
              }
            } else if (event == AuthChangeEvent.signedOut) {
              // A Google (Clerk) user has no Supabase session; ignore this.
              if (ClerkBridge.appUserId != null) return;
              _handleSignedOut();
            } else if (event == AuthChangeEvent.initialSession) {
              if (session != null) {
                _linkOneSignalIdentity(session.user.id);
              }
              if (session != null && !_appState.isLoggedIn) {
                await _appState.loginWithSupabase();
              }
              if (session != null) {
                _subscribeToNotifications(session.user.id);
              }
              _initialized = true;
            } else if (event == AuthChangeEvent.tokenRefreshed &&
                session != null) {
              _linkOneSignalIdentity(session.user.id);
              if (!_appState.isLoggedIn) {
                await _appState.loginWithSupabase();
              }
              _subscribeToNotifications(session.user.id);
            }
          });
    } catch (e) {
      debugPrint('Auth listener init error (Supabase not ready): $e');
      _initialized = true;
    }
  }

  /// Google (Clerk) sign-in / restore / sign-out. Mirrors the email-OTP flow
  /// above so notifications, push and navigation behave the same way.
  void _initClerkListener() {
    _clerkSubscription = ClerkBridge.events.listen((event) async {
      switch (event.type) {
        case ClerkBridgeEventType.signedIn:
        case ClerkBridgeEventType.initialSession:
          final userId = event.userId;
          if (userId == null) return;
          _linkOneSignalIdentity(userId);
          if (!_appState.isLoggedIn) {
            await _appState.loginWithSupabase();
          }
          _subscribeToNotifications(userId);
          _initialized = true;
          final currentPath = appRouter
              .routerDelegate
              .currentConfiguration
              .uri
              .toString();
          if (currentPath == AppRoutes.initial ||
              currentPath == AppRoutes.signUpLoginScreen ||
              currentPath == AppRoutes.otpVerifyScreen) {
            appRouter.go(AppRoutes.homeScreen);
          }
          break;
        case ClerkBridgeEventType.signedOut:
          _handleSignedOut();
          break;
        case ClerkBridgeEventType.error:
          break;
      }
    });
  }

  void _handleSignedOut() {
    NotificationService.instance.unsubscribe();
    if (!kIsWeb) {
      OneSignal.logout();
    }
    _appState.logout();
    final currentPath = appRouter
        .routerDelegate
        .currentConfiguration
        .uri
        .toString();
    if (!currentPath.startsWith('/admin') && _initialized) {
      appRouter.go(AppRoutes.signUpLoginScreen);
    }
  }

  /// Associates this device's OneSignal subscription with the signed-in
  /// Supabase user (external_id). The Edge Function targets pushes using
  /// this same ID, so no player-id syncing table is needed.
  /// No-op on web, where OneSignal is not initialized.
  void _linkOneSignalIdentity(String userId) {
    if (kIsWeb) return;
    try {
      OneSignal.login(userId);
    } catch (e) {
      debugPrint('OneSignal login error (non-fatal): $e');
    }
  }

  void _subscribeToNotifications(String userId) {
    NotificationService.instance.subscribeToUserNotifications(
      userId,
      (_) => _appState.refreshUnreadNotificationCount(),
    );
    NotificationService.instance.subscribeToAdminBroadcasts(
      (_, __) => _appState.refreshUnreadNotificationCount(),
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _clerkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClerkBridge.wrap(
      ChangeNotifierProvider.value(
        value: _appState,
        child: _WebFrame(
          child: Sizer(
            builder: (context, orientation, screenType) {
              precacheImage(
                const AssetImage('assets/images/maintix_full_logo.png'),
                context,
              );
              return Consumer<AppState>(
                builder: (context, appState, _) {
                  AppTheme.applySystemUI(appState.themeMode);
                  return MaterialApp.router(
                    title: 'Homaclo',
                    theme: AppTheme.lightTheme,
                    darkTheme: AppTheme.darkTheme,
                    themeMode: appState.themeMode,
                    // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
                    builder: (context, child) {
                      return MediaQuery(
                        data: MediaQuery.of(
                          context,
                        ).copyWith(textScaler: TextScaler.linear(1.0)),
                        // App-wide tap animation (glow on every tappable widget)
                        child: GlobalTapEffect(child: child!),
                      );
                    },
                    // 🚨 END CRITICAL SECTION
                    debugShowCheckedModeBanner: false,
                    routerConfig: appRouter,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
