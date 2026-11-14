import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../routes/app_routes.dart';
import '../../services/clerk/clerk_bridge.dart';
import '../../services/supabase_service.dart';

/// Sign in / register screen. Mirrors the website's /login page
/// (same copy, same flow: email one-time code + Google), backed by the same
/// Supabase project and the same Clerk (production) instance.
class SignUpLoginScreen extends StatefulWidget {
  const SignUpLoginScreen({super.key});

  @override
  State<SignUpLoginScreen> createState() => _SignUpLoginScreenState();
}

class _SignUpLoginScreenState extends State<SignUpLoginScreen> {
  static const Color _cyan = Color(0xFF1ACBE8);
  static const Color _cyanDark = Color(0xFF0BB5D6);
  static const Color _ink = Color(0xFF04121F);

  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;
  StreamSubscription<ClerkBridgeEvent>? _clerkSub;
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  static const List<List<String>> _benefits = [
    ['🪙', 'Get 50 Welcome Coins', 'Free when you sign up, use them on a booking'],
    ['📦', 'Track bookings & offers', 'Every cleaning, coupon and reward in one place'],
    ['🏷️', '₹100 off your first booking', 'Apply code WEL100 at checkout'],
    ['🔒', 'No password, fully secure', 'Just a one-time code sent to your email'],
  ];

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()
      ..onTap = () => context.push(AppRoutes.termsScreen);
    _privacyTap = TapGestureRecognizer()
      ..onTap = () => context.push(AppRoutes.privacyPolicyScreen);

    // Show Google (Clerk) sign-in problems on this screen.
    _clerkSub = ClerkBridge.events.listen((event) {
      if (!mounted) return;
      if (event.type == ClerkBridgeEventType.error) {
        setState(() {
          _isGoogleLoading = false;
          _errorMessage = event.message;
        });
      } else if (event.type == ClerkBridgeEventType.signedIn) {
        setState(() => _isGoogleLoading = false);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (SupabaseService.instance.isLoggedIn && mounted) {
        context.go(AppRoutes.homeScreen);
        return;
      }
      await _checkPersistedOtpState();
    });
  }

  Future<void> _checkPersistedOtpState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final otpSent = prefs.getBool('otp_sent') ?? false;
      final otpEmail = prefs.getString('otp_email') ?? '';
      if (otpSent && otpEmail.isNotEmpty && mounted) {
        context.push(AppRoutes.otpVerifyScreen, extra: otpEmail);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _clerkSub?.cancel();
    _termsTap.dispose();
    _privacyTap.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim().toLowerCase();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await SupabaseService.instance.sendOtp(email);
      if (mounted) context.push(AppRoutes.otpVerifyScreen, extra: email);
    } catch (e) {
      if (mounted) {
        final m = e.toString().replaceAll('Exception: ', '');
        setState(() {
          _errorMessage = RegExp(r'rate|security|seconds', caseSensitive: false)
                  .hasMatch(m)
              ? 'Please wait a few seconds before requesting another code.'
              : m;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _continueWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });
    try {
      await ClerkBridge.signInWithGoogle(context);
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Google sign-in failed. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Widget _brand() {
    return Row(
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
            borderRadius: const BorderRadius.all(Radius.elliptical(8, 12)),
            boxShadow: [
              BoxShadow(color: _cyan.withAlpha(120), blurRadius: 12),
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
    );
  }

  Widget _card() {
    final busy = _isLoading || _isGoogleLoading;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(22),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withAlpha(46)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Continue with email',
            style: GoogleFonts.fraunces(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We’ll email you a one-time code. New here? Your account is created automatically.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              height: 1.45,
              color: Colors.white.withAlpha(190),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Email address',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white.withAlpha(230),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onSubmitted: (_) => busy ? null : _sendOtp(),
            style: GoogleFonts.plusJakartaSans(fontSize: 16, color: _ink),
            decoration: InputDecoration(
              hintText: 'you@example.com',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: const Color(0xFF8493A8),
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 14, right: 8),
                child: Text('✉️', style: TextStyle(fontSize: 18)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0),
              filled: true,
              fillColor: const Color(0xFFF5F7FB),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
                borderSide: const BorderSide(color: _cyan, width: 2),
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFFFFA3A3),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Opacity(
            opacity: busy ? 0.7 : 1,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: busy ? null : _sendOtp,
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
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: _ink,
                            ),
                          )
                        : Text(
                            'Send code  →',
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
          if (ClerkBridge.isSupported) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.white.withAlpha(60))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.white.withAlpha(170),
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.white.withAlpha(60))),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: busy ? null : _continueWithGoogle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white.withAlpha(200),
                  foregroundColor: _ink,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _isGoogleLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: _cyanDark,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _GoogleG(size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Continue with Google',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1B2433),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Center(
            child: Text.rich(
              TextSpan(
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.white.withAlpha(190),
                ),
                children: [
                  const TextSpan(text: 'By continuing you agree to our '),
                  TextSpan(
                    text: 'Terms',
                    recognizer: _termsTap,
                    style: const TextStyle(
                      color: Color(0xFF6FE3F5),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    recognizer: _privacyTap,
                    style: const TextStyle(
                      color: Color(0xFF6FE3F5),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefitTile(List<String> b) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(16),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _cyan.withAlpha(36),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _cyan.withAlpha(70)),
            ),
            child: Text(b[0], style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(height: 12),
          Text(
            b[1],
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.3,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            b[2],
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              height: 1.4,
              color: Colors.white.withAlpha(165),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  _brand(),
                  const SizedBox(height: 22),
                  Text(
                    'Welcome to Homaclo',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fraunces(
                      fontSize: 38,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sign in or create your account in seconds. No password needed.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      height: 1.45,
                      color: Colors.white.withAlpha(190),
                    ),
                  ),
                  const SizedBox(height: 26),
                  _card(),
                  const SizedBox(height: 18),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.88,
                    children: _benefits.map(_benefitTile).toList(),
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

/// The multicolour Google "G" mark, drawn in code (no asset needed).
class _GoogleG extends StatelessWidget {
  const _GoogleG({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _GoogleGPainter());
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final stroke = size.width * 0.22;
    final rect = Rect.fromCircle(
      center: Offset(r, r),
      radius: r - stroke / 2,
    );
    double rad(double d) => d * 3.1415926535 / 180;
    void arc(Color c, double start, double sweep) {
      canvas.drawArc(
        rect,
        rad(start),
        rad(sweep),
        false,
        Paint()
          ..color = c
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
    }

    arc(const Color(0xFFEA4335), 205, 110);
    arc(const Color(0xFFFBBC05), 145, 60);
    arc(const Color(0xFF34A853), 55, 90);
    arc(const Color(0xFF4285F4), 0, 55);
    canvas.drawRect(
      Rect.fromLTWH(r, r - stroke / 2, r, stroke),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
