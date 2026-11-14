import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state.dart';
import 'package:provider/provider.dart';
import 'tap_scale.dart';

// Floating bottom nav, same look as the website's mobile `.bnav`:
// dark translucent pill, active tab in a blue -> cyan gradient.
class AppNavigation extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppNavigation({required this.navigationShell, super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  static const Color _inactive = Color(0xFF94A3B8);

  final List<_TabSpec> _tabs = const [
    _TabSpec(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      branchIndex: 0,
    ),
    _TabSpec(
      label: 'Book',
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today_rounded,
      branchIndex: 1,
    ),
    _TabSpec(
      label: 'Reviews',
      icon: Icons.star_outline_rounded,
      selectedIcon: Icons.star_rounded,
      branchIndex: 2,
    ),
    _TabSpec(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      branchIndex: 3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xEB050C1A),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x1FFFFFFF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 30,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final tab = _tabs[index];
            final isActive = tab.branchIndex == currentIndex;

            return Expanded(
              child: TapScale(
                scale: 0.94,
                onTap: () {
                  // When tapping the Booking tab, reset cart so it always shows fresh flow
                  if (tab.branchIndex == 1) {
                    context.read<AppState>().resetCart();
                  }
                  widget.navigationShell.goBranch(
                    tab.branchIndex,
                    initialLocation: tab.branchIndex == currentIndex,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(
                            colors: [Color(0xFF0284C7), Color(0xFF06B6D4)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? tab.selectedIcon : tab.icon,
                        color: isActive ? Colors.white : _inactive,
                        size: 21,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tab.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isActive ? Colors.white : _inactive,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _TabSpec {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int branchIndex;

  const _TabSpec({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.branchIndex,
  });
}
