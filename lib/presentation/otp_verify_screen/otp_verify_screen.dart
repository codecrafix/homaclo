import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../../routes/app_routes.dart';
import '../../services/supabase_service.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String email;
  const OtpVerifyScreen({super.key, required this.email});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;
  int _resendSeconds = 60;
  Timer? _resendTimer;

  // Location flow state
  bool _showLocationPrompt = false;
  bool _locationFetching = false;

  static const String _prefKeyOtpSent = 'otp_sent';
  static const String _prefKeyOtpEmail = 'otp_email';

  @override
  void initState() {
    super.initState();
    _persistOtpState();
    _startResendTimer();
    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  /// Persist OTP state so minimizing/backgrounding doesn't reset it.
  Future<void> _persistOtpState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyOtpSent, true);
      await prefs.setString(_prefKeyOtpEmail, widget.email);
    } catch (_) {}
  }

  /// Clear persisted OTP state (called on success or "Change Email").
  Future<void> _clearOtpState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeyOtpSent);
      await prefs.remove(_prefKeyOtpEmail);
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  String get _otpValue => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all 6 digits entered
    if (_otpValue.length == 6) {
      _verifyOtp();
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpValue;
    if (otp.length < 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final response = await SupabaseService.instance.verifyOtp(
        widget.email,
        otp,
      );

      if (response.user != null && mounted) {
        // Ensure first-time setup: profile + user_coins initialized
        await SupabaseService.instance.ensureFirstTimeSetup();

        await context.read<AppState>().loginWithSupabase();

        // Clear persisted OTP state on success
        await _clearOtpState();

        // Show MANDATORY location permission prompt (no skip)
        if (mounted) {
          setState(() {
            _isVerifying = false;
            _showLocationPrompt = true;
          });
        }
      } else {
        if (mounted) {
          setState(() => _errorMessage = 'Invalid OTP. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Invalid or expired OTP. Please try again.';
        });
        // Clear fields on error
        for (final c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } finally {
      if (mounted && !_showLocationPrompt) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_resendSeconds > 0) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.instance.sendOtp(widget.email);
      if (mounted) {
        _startResendTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'OTP resent to ${widget.email}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to resend OTP. Try again.');
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  /// MANDATORY location allow — user MUST tap this to proceed.
  Future<void> _handleLocationAllow() async {
    setState(() => _locationFetching = true);

    final appState = context.read<AppState>();
    await appState.fetchAndSaveLocation();

    if (mounted) {
      // Navigate to home regardless of location result
      // (if denied, home header shows retry chip)
      context.go(AppRoutes.homeScreen);
    }
  }

  void _handleChangeEmail() async {
    await _clearOtpState();
    if (mounted) context.go(AppRoutes.signUpLoginScreen);
  }

  @override
  Widget build(BuildContext context) {
    if (_showLocationPrompt) {
      return _buildLocationPromptScreen();
    }
    return _buildOtpScreen();
  }

  Widget _buildLocationPromptScreen() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: false, // Prevent back navigation from location screen
        child: Scaffold(
          backgroundColor: AppTheme.primaryNavy,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: AppTheme.tealAccent.withAlpha(30),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.tealAccent.withAlpha(100),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: AppTheme.tealAccent,
                      size: 52,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Enable Your Location',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Homaclo needs your precise location to show nearby services, auto-fill your address, and provide accurate service estimates.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.white.withAlpha(179),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.tealAccent.withAlpha(80),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: AppTheme.tealAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Location access is required to continue using Homaclo.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.white.withAlpha(200),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (_locationFetching)
                    Column(
                      children: [
                        const CircularProgressIndicator(
                          color: AppTheme.tealAccent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Fetching your precise location...',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: Colors.white.withAlpha(179),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please allow location access when prompted',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.white.withAlpha(130),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleLocationAllow,
                        icon: const Icon(Icons.my_location_rounded, size: 20),
                        label: Text(
                          'Enable Precise Location',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.tealAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpScreen() {
    // The header + card fill the full screen and the Scaffold background is
    // always AppTheme.primaryNavy (a dark navy/charcoal shade in BOTH themes),
    // so the area behind the status bar is always dark regardless of the
    // app's light/dark theme. Icons must therefore always be light — using
    // Theme.of(context).brightness here made them dark (invisible) whenever
    // the app was in light theme.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.primaryNavy,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.tealAccent.withAlpha(30),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.tealAccent.withAlpha(100),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.mark_email_read_rounded,
                          color: AppTheme.tealAccent,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Check Your Email',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We sent a 6-digit code to',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: Colors.white.withAlpha(179),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.email,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.tealAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // OTP card
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 480),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter Verification Code',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.inputTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter the 6-digit OTP sent to your email',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF9EAAB8)
                              : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // OTP boxes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (i) {
                          return SizedBox(
                            width: 46,
                            height: 56,
                            child: TextFormField(
                              controller: _controllers[i],
                              focusNode: _focusNodes[i],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.inputTextColor(context),
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                contentPadding: EdgeInsets.zero,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.tealAccent.withAlpha(100),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppTheme.tealAccent,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                // Was hardcoded to Colors.white, which made the
                                // digits (styled with the dark-mode-aware text
                                // color) invisible in dark mode — white text on
                                // a white box. Now follows the theme like the
                                // rest of the form fields.
                                fillColor: AppTheme.inputFillColor(context),
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (v) => _onDigitChanged(i, v),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                      // Error message
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.error.withAlpha(80),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: AppTheme.error,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppTheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 28),
                      // Verify button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isVerifying ? null : _verifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.tealAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isVerifying
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Verify OTP',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Resend timer
                      Center(
                        child: _resendSeconds > 0
                            ? Text(
                                'Resend OTP in ${_resendSeconds}s',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFF9EAAB8)
                                      : AppTheme.textSecondary,
                                ),
                              )
                            : TextButton(
                                onPressed: _isResending ? null : _resendOtp,
                                child: _isResending
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.tealAccent,
                                        ),
                                      )
                                    : Text(
                                        'Resend OTP',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.tealAccent,
                                        ),
                                      ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      // Change email button
                      Center(
                        child: TextButton.icon(
                          onPressed: _handleChangeEmail,
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            size: 16,
                            color: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? const Color(0xFF9EAAB8)
                                : AppTheme.textSecondary,
                          ),
                          label: Text(
                            'Change Email',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF9EAAB8)
                                  : AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
