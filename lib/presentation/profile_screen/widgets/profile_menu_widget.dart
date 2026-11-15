import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/app_state.dart';
import '../../../routes/app_routes.dart';
import './help_support_dialog.dart';
import 'package:go_router/go_router.dart';

class ProfileMenuWidget extends StatelessWidget {
  const ProfileMenuWidget({super.key});

  void _showMyReviewsDialog(BuildContext context) {
    final reviews = context.read<AppState>().myReviews;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'My Reviews',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.tealLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${reviews.length} review${reviews.length != 1 ? 's' : ''}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.tealAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: reviews.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_border_rounded,
                            size: 48,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No reviews yet',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Complete a booking to write your first review',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: reviews.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final r = reviews[i];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ...List.generate(
                                    5,
                                    (si) => Icon(
                                      si < r.rating
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      color: AppTheme.warning,
                                      size: 16,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (r.id != null)
                                    GestureDetector(
                                      onTap: () async {
                                        Navigator.pop(ctx);
                                        await context
                                            .read<AppState>()
                                            .deleteDbReview(r.id!);
                                      },
                                      child: Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppTheme.error,
                                        size: 18,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                r.review,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${r.timeAgo}  •  ${r.isApproved ? "✅ Live" : "⏳ Approval pending"}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.themeMode == ThemeMode.dark;

    final menuItems = [
      _MenuItem(
        icon: Icons.notifications_rounded,
        iconColor: const Color(0xFF6366F1),
        title: 'Notifications',
        subtitle: 'View your alerts and updates',
        onTap: () => context.push(AppRoutes.notificationsScreen),
      ),
      _MenuItem(
        icon: Icons.card_giftcard_rounded,
        iconColor: const Color(0xFFEC4899),
        title: 'Refer & Earn',
        subtitle: 'Invite friends, earn 50 coins each',
        onTap: () => context.push(AppRoutes.referEarnScreen),
      ),
      _MenuItem(
        icon: Icons.history_rounded,
        iconColor: AppTheme.tealAccent,
        title: 'My Bookings',
        subtitle: 'View all your service bookings',
        onTap: () => context.push(AppRoutes.bookingHistoryScreen),
      ),
      _MenuItem(
        icon: Icons.star_rounded,
        iconColor: AppTheme.warning,
        title: 'My Reviews',
        subtitle: 'Reviews you have submitted',
        onTap: () => _showMyReviewsDialog(context),
      ),
      _MenuItem(
        icon: Icons.info_outline_rounded,
        iconColor: AppTheme.tealAccent,
        title: 'About Us',
        subtitle: 'Our mission and company highlights',
        onTap: () => context.push(AppRoutes.aboutUsScreen),
      ),
      _MenuItem(
        icon: Icons.privacy_tip_rounded,
        iconColor: AppTheme.onSurfaceStrong,
        title: 'Privacy & Refund Policy',
        subtitle: 'Data privacy, cancellation & refund terms',
        onTap: () => context.push(AppRoutes.privacyPolicyScreen),
      ),
      _MenuItem(
        icon: Icons.article_rounded,
        iconColor: AppTheme.onSurfaceStrong,
        title: 'Terms & Conditions',
        subtitle: 'Service terms for 2026',
        onTap: () => context.push(AppRoutes.termsScreen),
      ),
      _MenuItem(
        icon: Icons.help_outline_rounded,
        iconColor: AppTheme.success,
        title: 'Help & Support',
        subtitle: 'Submit a ticket or contact us',
        onTap: () => showHelpSupportDialog(context),
      ),
    ];

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.cardShadow,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: List.generate(menuItems.length, (index) {
              final item = menuItems[index];
              return Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: item.onTap,
                      borderRadius: BorderRadius.only(
                        topLeft: index == 0
                            ? const Radius.circular(16)
                            : Radius.zero,
                        topRight: index == 0
                            ? const Radius.circular(16)
                            : Radius.zero,
                        bottomLeft: index == menuItems.length - 1
                            ? const Radius.circular(16)
                            : Radius.zero,
                        bottomRight: index == menuItems.length - 1
                            ? const Radius.circular(16)
                            : Radius.zero,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            // Show red badge on notification icon when unread count > 0
                            index == 0
                                ? Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: item.iconColor.withAlpha(26),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          item.icon,
                                          color: item.iconColor,
                                          size: 20,
                                        ),
                                      ),
                                      if (appState.unreadNotificationCount > 0)
                                        Positioned(
                                          top: -4,
                                          right: -4,
                                          child: Container(
                                            width: 16,
                                            height: 16,
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                appState.unreadNotificationCount >
                                                        9
                                                    ? '9+'
                                                    : '${appState.unreadNotificationCount}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  )
                                : Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: item.iconColor.withAlpha(26),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      item.icon,
                                      color: item.iconColor,
                                      size: 20,
                                    ),
                                  ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    item.subtitle,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: AppTheme.textMuted,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (index < menuItems.length - 1)
                    Divider(
                      height: 1,
                      color: AppTheme.divider,
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 16),

        // ── Theme Toggle ────────────────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.cardShadow,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: const Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDark ? 'Dark Mode' : 'Light Mode',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Tap to switch theme',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isDark,
                onChanged: (_) {
                  appState.toggleTheme();
                  // Apply correct system UI after toggle (isDark is the OLD value before toggle)
                  AppTheme.applySystemUI(
                    isDark ? ThemeMode.light : ThemeMode.dark,
                  );
                },
                activeThumbColor: const Color(0xFF6366F1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // NOTE: Special Offer card moved to ProfileSpecialOfferWidget
        // (shown right below the Active Offer card on the profile screen).

        // Logout button removed from Profile (Sign out lives in the top header).
        Text(
          'Homaclo © 2026 · @maintix.in · v1.0.0',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppTheme.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
