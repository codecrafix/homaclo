import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import './app_navigation.dart';
import './site_header.dart';

/// Shell for the four main tabs. Every tab sits under the same website
/// header (logo, theme toggle, sign in / out) and above the website-style
/// bottom navigation.
///
/// Keyboard handling: this Scaffold already shrinks its body above the
/// keyboard. The tabs have their own Scaffolds, and each of them used to shrink
/// *again* by the keyboard height, which left the Booking form completely
/// blank as soon as a field (phone number) was focused. The keyboard inset is
/// therefore removed for everything inside the body, and the big header is
/// hidden while typing so the form gets the room.
class AppScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AppScaffold({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final keyboardOpen = media.viewInsets.bottom > 0;

    // The header covers the status bar, so tabs must not add the top inset a
    // second time. While the header is hidden (keyboard open) they must.
    final bodyMedia = media.copyWith(
      padding: keyboardOpen ? media.padding : media.padding.copyWith(top: 0),
      viewPadding: keyboardOpen
          ? media.viewPadding
          : media.viewPadding.copyWith(top: 0),
      viewInsets: media.viewInsets.copyWith(bottom: 0),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayFor(dark),
      child: Scaffold(
        backgroundColor: AppTheme.background,
        extendBody: true,
        body: Column(
          children: [
            if (!keyboardOpen) const SiteHeader(),
            Expanded(
              child: MediaQuery(data: bodyMedia, child: navigationShell),
            ),
          ],
        ),
        bottomNavigationBar: AppNavigation(navigationShell: navigationShell),
      ),
    );
  }
}
