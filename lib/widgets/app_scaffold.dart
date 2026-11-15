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
///
/// Back button: goes back through the tabs the user visited, one step at a
/// time (Profile -> Reviews -> Home ...). On Home with nothing left to go back
/// to, the first press shows "Press back again to exit" and a second press
/// within 2 seconds closes the app.
class AppScaffold extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppScaffold({required this.navigationShell, super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  /// Tabs visited before the current one (most recent last).
  final List<int> _history = [];
  late int _current = widget.navigationShell.currentIndex;
  DateTime? _lastBack;

  StatefulNavigationShell get navigationShell => widget.navigationShell;

  @override
  void didUpdateWidget(covariant AppScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    final now = widget.navigationShell.currentIndex;
    if (now != _current) {
      // Tab changed by a tap or by context.go(): remember where we came from.
      _history.remove(now);
      _history.add(_current);
      _current = now;
    }
  }

  void _onBack() {
    // 1) Go back to the previously opened tab.
    if (_history.isNotEmpty) {
      final prev = _history.removeLast();
      _current = prev;
      navigationShell.goBranch(prev);
      return;
    }
    // 2) Not on Home and no history: go Home first.
    if (_current != 0) {
      _current = 0;
      navigationShell.goBranch(0);
      return;
    }
    // 3) On Home: press back twice to exit.
    final now = DateTime.now();
    if (_lastBack != null &&
        now.difference(_lastBack!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }
    _lastBack = now;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Press back again to exit'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 100),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _onBack();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
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
      ),
    );
  }
}
