import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import './app_navigation.dart';
import './site_header.dart';

/// Shell for the four main tabs. Every tab sits under the same website
/// header (logo, theme toggle, sign in / out) and above the website-style
/// bottom navigation.
class AppScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AppScaffold({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayFor(dark),
      child: Scaffold(
        backgroundColor: AppTheme.background,
        extendBody: true,
        body: Column(
          children: [
            const SiteHeader(),
            Expanded(
              // The header already covers the status bar, so tabs must not add
              // the top inset a second time.
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: navigationShell,
              ),
            ),
          ],
        ),
        bottomNavigationBar: AppNavigation(navigationShell: navigationShell),
      ),
    );
  }
}
