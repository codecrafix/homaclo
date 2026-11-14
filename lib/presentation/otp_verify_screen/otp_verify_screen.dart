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

/// "Enter your code" step. Mirrors the website's code screen: one code field,
/// "Verify & continue", 30s resend timer, "Change email".
class OtpVerifyScreen extends StatefulWidget {
  final String email;
  const OtpVerifyScreen({super.key, required this.email});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  static const Color _cyan = Color(0xFF1ACBE8);
  static const Color _cyanDark = Color(0xFF0BB5D6);
  static const Color _ink = Color(0xFF04121F);

  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();

  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;
  int _resendSeconds = 30;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _codeFocus.requestFocus();
    });
  }

  Future<void> _persistOtpState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyOtpSent, true);
      await prefs.setString(_prefKeyOtpEmail, widget.email);
    } catch (_) {}
  }

  Future<void> _clearOtpState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeyOtpSent);
      await prefs.remove(_prefKeyOtpEmail);
    } catch (_) {}
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocus.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = 30;
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

  Future<void> _verifyOtp() async {
    if (_isVerifying) return;
    final otp = _codeController.text.replaceAll(RegExp(r'\s'), '');
    if (otp.length < 4) {
      setState(() => _errorMessage = 'Enter the code from your email.');
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
          setState(() => _errorMessage =
              'That code is invalid or has expired. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'That code is invalid or has expired. Please try again.';
        });
        _codeController.clear();
        _codeFocus.requestFocus();
      }
    } finally {
      if (mounted && !_showLocationPrompt) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_resendSeconds > 0 || _isResending) return;

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
              'A new code is on its way ✉️',
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
        setState(() => _errorMessage =
            'Please wait a few seconds before requesting another code.');
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF061126),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF061126), Color(0xFF0A2149), Color(0xFF0B4A7F)],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 16,
                        height: 22,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF3DE0F5), _cyanDark],
                          ),
                          borderRadius:
                              const BorderRadius.all(Radius.elliptical(8, 12)),
                          boxShadow: [
                            BoxShadow(
                              color: _cyan.withAlpha(120),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Homaclo',
                        style: GoogleFonts.fraunces(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(22),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withAlpha(46)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton(
                          onPressed: _handleChangeEmail,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            '← Change email',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6FE3F5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Enter your code',
                          style: GoogleFonts.fraunces(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text.rich(
                          TextSpan(
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              height: 1.45,
                              color: Colors.white.withAlpha(190),
                            ),
                            children: [
                              const TextSpan(text: 'We sent a code to '),
                              TextSpan(
                                text: widget.email,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const TextSpan(
                                text:
                                    '. Check your spam folder if you don’t see it.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'One-time code',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withAlpha(230),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _codeController,
                          focusNode: _codeFocus,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 10,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onSubmitted: (_) => _verifyOtp(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 8,
                            color: _ink,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: '••••••',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 26,
                              letterSpacing: 8,
                              color: const Color(0xFF8493A8),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF5F7FB),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide:
                                  const BorderSide(color: _cyan, width: 2),
                            ),
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _errorMessage!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFFFFA3A3),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Opacity(
                          opacity: _isVerifying ? 0.7 : 1,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: _isVerifying ? null : _verifyOtp,
                              child: Ink(
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_cyanDark, _cyan],
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _cyan.withAlpha(90),
                                      blurRadius: 22,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _isVerifying
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: _ink,
                                          ),
                                        )
                                      : Text(
                                          'Verify & continue  →',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            color: _ink,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: _resendSeconds > 0
                              ? Text.rich(
                                  TextSpan(
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      color: Colors.white.withAlpha(190),
                                    ),
                                    children: [
                                      const TextSpan(text: 'Resend code in '),
                                      TextSpan(
                                        text: '$_resendSeconds',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const TextSpan(text: 's'),
                                    ],
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Didn’t get it? ',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        color: Colors.white.withAlpha(190),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _isResending ? null : _resendOtp,
                                      child: Text(
                                        'Resend code',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF6FE3F5),
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
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
      ),
    );
  }
}
