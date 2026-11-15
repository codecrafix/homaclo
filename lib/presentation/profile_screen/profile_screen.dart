import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tap_scale.dart';
import './widgets/profile_ad_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/profile_menu_widget.dart';
import './widgets/profile_referral_widget.dart';
import './widgets/profile_special_offer_widget.dart';
import './widgets/profile_stats_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load fresh data when profile screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      if (appState.isLoggedIn) {
        appState.loadDbBookings();
      }
    });
  }

  /// Staggered fade + slide-up entrance for each section.
  Widget _entry(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 450 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 24 * (1 - v)), child: c),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayFor(isDark),
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () => context.read<AppState>().refreshAllData(
              refreshLocation: false,
            ),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _entry(0, TapScale(scale: 0.985, child: ProfileHeaderWidget())),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _entry(1, TapScale(child: ProfileStatsWidget())),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _entry(2, TapScale(child: ProfileAdWidget())),
                  ),
                ),
                // Special Offer sits right below the Active Offer (₹100 OFF) card
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _entry(
                      3,
                      const TapScale(child: ProfileSpecialOfferWidget()),
                    ),
                  ),
                ),
                // Refer & Earn: same section as the website profile page.
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _entry(4, const ProfileReferralWidget()),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _entry(5, ProfileMenuWidget()),
                  ),
                ),
                // No footer here (footer is only on Home). Room for the floating bottom nav.
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
