import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../presentation/home_screen/widgets/web_header.dart'
    show showReferSheet;
import '../presentation/home_screen/widgets/web_tokens.dart';
import '../providers/app_state.dart';
import '../services/supabase_service.dart';
import 'location_sheet.dart';
import 'maintix_logo.dart' show HomacloDrop;
import 'tap_scale.dart';

/// The Homaclo app header: logo on the left; location, Refer & Earn and
/// Sign in / Sign out on the right. Light / dark mode is switched from Profile.
///
/// It paints its own background behind the status bar, so screens placed
/// under it must not add the top safe-area inset again.
class SiteHeader extends StatelessWidget {
  /// Hide the location button.
  final bool showLocation;

  /// Hide the Refer & Earn button.
  final bool showRefer;

  /// Hide the Sign in / Sign out button.
  final bool showAuthButton;

  const SiteHeader({
    super.key,
    this.showLocation = true,
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
    final loading = app.locationLoading;
    final denied = app.locationPermissionDenied;
    const amber = Color(0xFFF59E0B);

    final actions = <Widget>[
      if (showLocation)
        _IconBtn(
          label: 'Location',
          onTap: () {
            if (denied) {
              app.fetchAndSaveLocation();
            } else {
              showLocationSheet(context);
            }
          },
          child: loading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: WT.teal,
                  ),
                )
              : Icon(
                  denied
                      ? Icons.location_off_rounded
                      : Icons.location_on_rounded,
                  size: 20,
                  color: denied ? amber : WT.teal,
                ),
        ),
      if (showRefer)
        _IconBtn(
          label: 'Refer and Earn',
          onTap: () => showReferSheet(context),
          child: const Text('🎁', style: TextStyle(fontSize: 17)),
        ),
      if (showAuthButton)
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
    ];

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
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                actions[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Website logo: Homaclo mark + "Homaclo" in Fraunces Bold.
/// The mark is sized from the wordmark (30 vs 19 at scale 1) so it is clearly
/// visible and in proportion with the text. [light] forces the white wordmark
/// (used on the dark footer).
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
        HomacloDrop(height: 30 * scale),
        SizedBox(width: 9 * scale),
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
  final String label;
  const _IconBtn({
    required this.child,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: TapScale(
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
      ),
    );
  }
}
