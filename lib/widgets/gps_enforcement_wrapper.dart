import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

/// Non-dismissible GPS enforcement overlay.
/// Wraps any child and shows a blocking overlay only when GPS is really off
/// or the location permission is really not granted.
class GpsEnforcementWrapper extends StatefulWidget {
  final Widget child;
  const GpsEnforcementWrapper({super.key, required this.child});

  @override
  State<GpsEnforcementWrapper> createState() => _GpsEnforcementWrapperState();
}

class _GpsEnforcementWrapperState extends State<GpsEnforcementWrapper>
    with WidgetsBindingObserver {
  Timer? _pollTimer;
  DateTime? _lastFetch;

  /// Real OS permission state. AppState also sets "permission denied" when a
  /// GPS fix merely failed / timed out, which used to lock the whole app
  /// behind the overlay even though permission was granted.
  bool _permissionGranted = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkGps());
    // Poll every 3 seconds while app is active
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkGps());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkGps();
    }
  }

  Future<bool> _readPermission() async {
    try {
      final p = await Geolocator.checkPermission();
      return p == LocationPermission.always || p == LocationPermission.whileInUse;
    } catch (_) {
      return true;
    }
  }

  void _fetch(AppState appState, String? userId) {
    _lastFetch = DateTime.now();
    LocationService.instance.lastAutoRefreshUserId = userId;
    appState.fetchAndSaveLocation();
  }

  Future<void> _checkGps() async {
    if (!mounted) return;
    final appState = context.read<AppState>();
    await appState.checkGpsServiceStatus();
    final granted = await _readPermission();
    if (!mounted) return;
    if (granted != _permissionGranted) {
      setState(() => _permissionGranted = granted);
    }

    if (appState.gpsServiceDisabled || appState.locationLoading) return;

    final userId = appState.currentUserId;
    final sinceLast = _lastFetch == null
        ? const Duration(days: 1)
        : DateTime.now().difference(_lastFetch!);

    // Fetch when GPS is on and either:
    //  - we have no location yet, or
    //  - first visit for this user in this session (the DB address can be
    //    old / coarse), or
    //  - a previous fix failed although permission is granted: retry, but at
    //    most every 20 seconds so GPS is not hammered.
    final needsFirstRefresh =
        appState.isLoggedIn &&
        userId != null &&
        LocationService.instance.lastAutoRefreshUserId != userId;
    final retryAfterFailure =
        granted && appState.locationPermissionDenied && sinceLast.inSeconds >= 20;
    final empty = appState.liveLocation.isEmpty && sinceLast.inSeconds >= 20;

    if (needsFirstRefresh || retryAfterFailure || empty) {
      _fetch(appState, userId);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final permissionBlocked =
            appState.locationPermissionDenied && !_permissionGranted;
        return Stack(
          children: [
            widget.child,
            if (appState.gpsServiceDisabled || permissionBlocked)
              _GpsDisabledOverlay(
                permissionDenied: permissionBlocked && !appState.gpsServiceDisabled,
              ),
          ],
        );
      },
    );
  }
}

class _GpsDisabledOverlay extends StatelessWidget {
  final bool permissionDenied;
  const _GpsDisabledOverlay({this.permissionDenied = false});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Container(
        color: Colors.black.withAlpha(230),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(51),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_off_rounded,
                    color: Colors.orange,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  permissionDenied
                      ? 'Location Permission Required'
                      : 'GPS Required',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  permissionDenied
                      ? 'Allow location access in Settings so Homaclo can provide accurate service location and booking.'
                      : 'Homaclo requires your device GPS to be turned on to provide accurate service location and booking.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (permissionDenied) {
                        await LocationService.instance.openAppSettings();
                      } else {
                        await LocationService.instance.openLocationSettings();
                      }
                    },
                    icon: const Icon(Icons.settings_rounded, size: 18),
                    label: Text(
                      permissionDenied ? 'Allow Location' : 'Enable GPS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.tealAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  permissionDenied
                      ? 'App will resume automatically once location access is allowed.'
                      : 'App will resume automatically once GPS is enabled.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
