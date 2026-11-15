import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/sign_up_login_screen/sign_up_login_screen.dart';
import '../presentation/otp_verify_screen/otp_verify_screen.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/booking_screen/booking_screen.dart';
import '../presentation/reviews_screen/reviews_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/booking_history_screen/booking_history_screen.dart';
import '../presentation/edit_profile_screen/edit_profile_screen.dart';
import '../presentation/about_us_screen/about_us_screen.dart';
import '../presentation/privacy_policy_screen/privacy_policy_screen.dart';
import '../presentation/terms_screen/terms_screen.dart';
import '../presentation/notifications_screen/notifications_screen.dart';
import '../presentation/refer_earn_screen/refer_earn_screen.dart';
import '../presentation/admin_panel_screen/admin_panel_screen.dart';
import '../widgets/app_scaffold.dart';
import '../services/auth_hint.dart';
import '../services/supabase_service.dart';

class AppRoutes {
  static const String initial = '/';
  static const String signUpLoginScreen = '/sign-up-login-screen';
  static const String otpVerifyScreen = '/otp-verify-screen';
  static const String homeScreen = '/home-screen';
  static const String bookingScreen = '/booking-screen';
  static const String reviewsScreen = '/reviews-screen';
  static const String profileScreen = '/profile-screen';
  static const String bookingHistoryScreen = '/booking-history-screen';
  static const String editProfileScreen = '/edit-profile-screen';
  static const String aboutUsScreen = '/about-us-screen';
  static const String privacyPolicyScreen = '/privacy-policy-screen';
  static const String termsScreen = '/terms-screen';
  static const String notificationsScreen = '/notifications-screen';
  static const String referEarnScreen = '/refer-earn-screen';
  static const String adminPanelScreen = '/admin';
}

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: child,
      );
    },
  );
}

CustomTransitionPage<void> _slidePage(
  GoRouterState state,
  Widget child, {
  Offset begin = const Offset(1, 0),
  int milliseconds = 280,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: Duration(milliseconds: milliseconds),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: begin, end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.initial,
  redirect: (context, state) {
    // A user who was signed in last time counts as signed in while the session
    // (especially a Google/Clerk one) is still being restored in the
    // background. This is what removes the login-page flash on app start.
    final isLoggedIn =
        SupabaseService.instance.isLoggedIn || AuthHint.wasLoggedIn;
    final path = state.uri.toString();

    // Always allow /admin route through — it handles its own auth check internally
    if (path == AppRoutes.adminPanelScreen || path.startsWith('/admin')) {
      return null;
    }

    // If logged in and on auth screens, redirect to home
    if (isLoggedIn &&
        (path == AppRoutes.initial ||
            path == AppRoutes.signUpLoginScreen ||
            path == AppRoutes.otpVerifyScreen)) {
      return AppRoutes.homeScreen;
    }

    // If not logged in and on protected screens, redirect to login
    if (!isLoggedIn &&
        (path == AppRoutes.homeScreen ||
            path == AppRoutes.bookingScreen ||
            path == AppRoutes.reviewsScreen ||
            path == AppRoutes.profileScreen ||
            path == AppRoutes.bookingHistoryScreen ||
            path == AppRoutes.editProfileScreen)) {
      return AppRoutes.signUpLoginScreen;
    }

    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.initial,
      pageBuilder: (context, state) =>
          _fadePage(state, const SignUpLoginScreen()),
    ),
    GoRoute(
      path: AppRoutes.signUpLoginScreen,
      pageBuilder: (context, state) =>
          _fadePage(state, const SignUpLoginScreen()),
    ),
    GoRoute(
      path: AppRoutes.otpVerifyScreen,
      pageBuilder: (context, state) {
        final email = state.extra as String? ?? '';
        return _slidePage(state, OtpVerifyScreen(email: email));
      },
    ),
    GoRoute(
      path: AppRoutes.bookingHistoryScreen,
      pageBuilder: (context, state) =>
          _slidePage(state, const BookingHistoryScreen()),
    ),
    GoRoute(
      path: AppRoutes.editProfileScreen,
      pageBuilder: (context, state) => _slidePage(
        state,
        const EditProfileScreen(),
        begin: const Offset(0, 1),
        milliseconds: 300,
      ),
    ),
    GoRoute(
      path: AppRoutes.aboutUsScreen,
      pageBuilder: (context, state) => _slidePage(state, const AboutUsScreen()),
    ),
    GoRoute(
      path: AppRoutes.privacyPolicyScreen,
      pageBuilder: (context, state) =>
          _slidePage(state, const PrivacyPolicyScreen()),
    ),
    GoRoute(
      path: AppRoutes.termsScreen,
      pageBuilder: (context, state) => _slidePage(state, const TermsScreen()),
    ),
    GoRoute(
      path: AppRoutes.notificationsScreen,
      pageBuilder: (context, state) =>
          _slidePage(state, const NotificationsScreen()),
    ),
    GoRoute(
      path: AppRoutes.referEarnScreen,
      pageBuilder: (context, state) =>
          _slidePage(state, const ReferEarnScreen()),
    ),
    GoRoute(
      path: AppRoutes.adminPanelScreen,
      pageBuilder: (context, state) =>
          _slidePage(state, const AdminPanelScreen()),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppScaffold(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.homeScreen,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: HomeScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.bookingScreen,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: BookingScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.reviewsScreen,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ReviewsScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profileScreen,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ProfileScreen()),
            ),
          ],
        ),
      ],
    ),
  ],
);
