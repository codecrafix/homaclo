import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../presentation/home_screen/widgets/web_header.dart'
    show showReferSheet;
import '../presentation/home_screen/widgets/web_tokens.dart';
import '../providers/app_state.dart';
import '../services/supabase_service.dart';
import 'maintix_logo.dart' show HomacloDrop;
import 'tap_scale.dart';

/// The Homaclo app header: logo on the left, Refer & Earn and Sign in / Sign
/// out on the right. (Dark-mode toggle and notification bell were removed.)
///
/// It paints its own background behind the status bar, so screens placed
/// under it must not add the top safe-area inset again.
class SiteHeader extends StatelessWidget {
  /// Hide the Refer & Earn button.
  final bool showRefer;

  /// Hide the Sign in / Sign out button.
  final bool showAuthButton;

  const SiteHeader({
    super.key,
    this.showRefer = true,
    this.showAuthButton = true,
  });

  Future<void> _signOut(BuildContext context) async {
    final app = context.read<AppState>();
    final router = GoRouter.of(context);
    try {
      await SupabaseService.instance.signOut();
    } catch (e) {
      debugPrint('signOut error (non-critical): $e');
    }
    app.logout();
    router.go(WT.routeLogin);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    // Dark mode was removed from the app: reset anyone who had it saved.
    if (app.themeMode == ThemeMode.dark) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted &&
            context.read<AppState>().themeMode == ThemeMode.dark) {
          context.read<AppState>().toggleTheme();
        }
      });
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: WT.bg,
        border: Border(bottom: BorderSide(color: WT.line)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Row(
            children: [
              const Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(fit: BoxFit.scaleDown, child: SiteLogo()),
                ),
              ),
              if (showRefer)
                _IconBtn(
                  onTap: () => showReferSheet(context),
                  child: const Text('🎁', style: TextStyle(fontSize: 17)),
                ),
              if (showAuthButton) ...[
                const SizedBox(width: 6),
                WBtn(
                  app.isLoggedIn ? 'Sign out' : 'Sign in',
                  small: true,
                  full: false,
                  onTap: () {
                    if (app.isLoggedIn) {
                      _signOut(context);
                    } else {
                      context.go(WT.routeLogin);
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Website logo: gradient water drop + "Homaclo" in Fraunces Bold.
/// [light] forces the white wordmark (used on the dark footer).
class SiteLogo extends StatelessWidget {
  final bool light;
  final double scale;
  const SiteLogo({super.key, this.light = false, this.scale = 1});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        HomacloDrop(height: 21 * scale),
        SizedBox(width: 8 * scale),
        Text(
          'Homaclo',
          maxLines: 1,
          softWrap: false,
          style: GoogleFonts.fraunces(
            fontSize: 19 * scale,
            fontWeight: FontWeight.w700,
            color: light ? Colors.white : WT.ink,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _IconBtn({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      scale: 0.92,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: WT.sf,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: WT.line),
        ),
        child: child,
      ),
    );
  }
}
