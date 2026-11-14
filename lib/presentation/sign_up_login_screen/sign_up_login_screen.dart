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

/// Sign in / register screen (email one-time code + Google), backed by the
/// same Supabase project and the same Clerk (production) instance as the
/// website. It has no app header / footer.
///
/// On a cold start a Google (Clerk) session is restored asynchronously, so for
/// a returning Google user we show a short splash instead of flashing this
/// login form and redirecting a few seconds later.
class SignUpLoginScreen extends StatefulWidget {
  const SignUpLoginScreen({super.key});

  @override
  State<SignUpLoginScreen> createState() => _SignUpLoginScreenState();
}

class _SignUpLoginScreenState extends State<SignUpLoginScreen> {
  static const Color _cyan = Color(0xFF1ACBE8);
  static const Color _cyanDark = Color(0xFF0BB5D6);
  static const Color _ink = Color(0xFF04121F);
  static const Color _link = Color(0xFF6FE3F5);
  static const String _hintKey = 'google_session_hint';

  /// True once the cold-start session check finished in this app process.
  static bool _gateDone = false;

  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _authReady = _gateDone;
  String? _errorMessage;
  StreamSubscription<ClerkBridgeEvent>? _clerkSub;
  Timer? _gateTimer;
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

    // Show Google (Clerk) sign-in problems on this screen, and remember that
    // this device has a Google session so the next cold start can wait for it.
    _clerkSub = ClerkBridge.events.listen((event) {
      if (event.type == ClerkBridgeEventType.signedIn ||
          event.type == ClerkBridgeEventType.initialSession) {
        _gateDone = true;
        _gateTimer?.cancel();
        SharedPreferences.getInstance()
            .then((p) => p.setBool(_hintKey, true))
            .catchError((_) => false);
      }
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
        _gateDone = true;
        context.go(AppRoutes.homeScreen);
        return;
      }
      await _initGate();
      await _checkPersistedOtpState();
    });
  }

  /// Decides whether to show the login form right away or wait briefly for a
  /// persisted Google (Clerk) session to be restored (cold start only).
  Future<void> _initGate() async {
    if (_gateDone) {
      if (mounted && !_authReady) setState(() => _authReady = true);
      return;
    }
    var hint = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      hint = prefs.getBool(_hintKey) ?? false;
    } catch (_) {}
    if (!mounted) return;
    if (!hint) {
      _gateDone = true;
      setState(() => _authReady = true);
      return;
    }
    _gateTimer = Timer(const Duration(seconds: 4), () async {
      // No Google session came back: the user really is signed out.
      _gateDone = true;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_hintKey);
      } catch (_) {}
      if (mounted) setState(() => _authReady = true);
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
    _gateTimer?.cancel();
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
    FocusScope.of(context).unfocus();
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });
    try {
      await ClerkBridge.signInWithGoogle(context);
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      if (mounted) {
        // Short technical reason is shown so a failure can be diagnosed from a
        // screenshot (e.g. redirect not allow-listed, Native API disabled).
        var detail = e.toString().split('\n').first.trim();
        if (detail.length > 140) detail = '${detail.substring(0, 140)}…';
        setState(() {
          _errorMessage = 'Google sign-in failed. Please try again.\n($detail)';
        });
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  OutlineInputBorder _border([Color? c, double w = 0]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: c == null ? BorderSide.none : BorderSide(color: c, width: w),
      );

  Widget _card() {
    final busy = _isLoading || _isGoogleLoading;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(22),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(46)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Continue with email',
            style: GoogleFonts.fraunces(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'We’ll email you a one-time code. New here? Your account is created automatically.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.4,
              color: Colors.white.withAlpha(190),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Email address',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withAlpha(230),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onSubmitted: (_) => busy ? null : _sendOtp(),
            style: GoogleFonts.plusJakartaSans(fontSize: 15, color: _ink),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'you@example.com',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                color: const Color(0xFF8493A8),
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 12, right: 8),
                child: Text('✉️', style: TextStyle(fontSize: 16)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0),
              filled: true,
              fillColor: const Color(0xFFF5F7FB),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: _border(),
              enabledBorder: _border(),
              focusedBorder: _border(_cyan, 2),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                height: 1.35,
                color: const Color(0xFFFFA3A3),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Opacity(
            opacity: busy ? 0.7 : 1,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: busy ? null : _sendOtp,
                child: Ink(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_cyanDark, _cyan]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _cyan.withAlpha(80),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: _ink,
                            ),
                          )
                        : Text(
                            'Send code  →',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.5,
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.white.withAlpha(60))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'or',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.white.withAlpha(170),
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.white.withAlpha(60))),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: busy ? null : _continueWithGoogle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white.withAlpha(200),
                  foregroundColor: _ink,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isGoogleLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: _cyanDark,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _GoogleG(size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Continue with Google',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1B2433),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Center(
            child: Text.rich(
              TextSpan(
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  height: 1.45,
                  color: Colors.white.withAlpha(190),
                ),
                children: [
                  const TextSpan(text: 'By continuing you agree to our '),
                  TextSpan(
                    text: 'Terms',
                    recognizer: _termsTap,
                    style: const TextStyle(
                      color: _link,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    recognizer: _privacyTap,
                    style: const TextStyle(
                      color: _link,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _cyan.withAlpha(36),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _cyan.withAlpha(70)),
            ),
            child: Text(b[0], style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 8),
          Text(
            b[1],
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            b[2],
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              height: 1.35,
              color: Colors.white.withAlpha(165),
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefitRow(int i) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _benefitTile(_benefits[i])),
          const SizedBox(width: 10),
          Expanded(child: _benefitTile(_benefits[i + 1])),
        ],
      ),
    );
  }

  static const BoxDecoration _bg = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF061126), Color(0xFF0A2149), Color(0xFF0B4A7F)],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF0B4A7F),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF061126),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: _bg,
          child: SafeArea(
            child: !_authReady
                // Restoring a saved Google session: no login form flash.
                ? const Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: _cyan,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
                    child: Column(
                      children: [
                        Text(
                          'Welcome to Homaclo',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fraunces(
                            fontSize: 29,
                            height: 1.12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in or create your account in seconds. No password needed.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            height: 1.4,
                            color: Colors.white.withAlpha(190),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _card(),
                        const SizedBox(height: 14),
                        _benefitRow(0),
                        const SizedBox(height: 10),
                        _benefitRow(2),
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
