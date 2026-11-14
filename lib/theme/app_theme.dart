import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// App-wide theme tokens, taken from the Homaclo website (web/site/styles.css).
///
/// The neutral tokens (background, surfaceWhite, textPrimary, ...) are
/// getters that resolve to the light or the dark palette depending on
/// [isDark]. [isDark] is updated by [applySystemUI], which the root
/// Consumer<AppState> calls on every theme-mode change; at that point the
/// whole widget tree is force-rebuilt so every screen picks up the new
/// palette (including widgets that never call Theme.of(context)).
///
/// Brand / status colours (tealAccent, success, warning, error) are
/// identical in both themes and stay `const`.
class AppTheme {
  AppTheme._();

  /// Current brightness. Do not set directly; call [applySystemUI].
  static bool isDark = false;

  // -- Brand / status (same in both themes) --
  static const Color tealAccent = Color(0xFF06B6D4);
  static const Color brandCyan = Color(0xFF22D3EE);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);

  // -- Light palette (website :root) --
  static const Color lightNavy = Color(0xFF072654);
  static const Color lightNavy2 = Color(0xFF0A3B66);
  static const Color lightBackground = Color(0xFFF5F8FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFEEF3F9);
  static const Color lightTextPrimary = Color(0xFF0B1F3A);
  static const Color lightTextSecondary = Color(0xFF5B6B82);
  static const Color lightTextMuted = Color(0xFF8A99AF);
  static const Color lightDivider = Color(0xFFE2E9F2);
  static const Color lightTealTint = Color(0xFFDDF4F8);
  static const Color lightShadow = Color(0x17072654);
  static const Color lightInputFill = Color(0xFFF5F8FC);
  static const Color lightOutline = Color(0xFFD3DDEA);

  // -- Dark palette (website :root[data-theme=dark]) --
  static const Color darkNavy = Color(0xFF0F2D57); // buttons, app bars
  static const Color darkNavy2 = Color(0xFF0B3A63);
  static const Color darkBackground = Color(0xFF06142A);
  static const Color darkSurface = Color(0xFF0C2142);
  static const Color darkSurfaceAlt = Color(0xFF0A1B36);
  static const Color darkTextPrimary = Color(0xFFEAF2FF);
  static const Color darkTextSecondary = Color(0xFF9DB0CC);
  static const Color darkTextMuted = Color(0xFF6F85A6);
  static const Color darkDivider = Color(0xFF1B3359);
  static const Color darkTealTint = Color(0xFF0C3A52);
  static const Color darkShadow = Color(0x59000000);
  static const Color darkInputFill = Color(0xFF06142A);
  static const Color darkOutline = Color(0xFF27436E);

  // -- Theme-aware tokens (use these in screens) --
  static Color get primaryNavy => isDark ? darkNavy : lightNavy;
  static Color get headerAlt => isDark ? darkNavy2 : lightNavy2;
  static Color get background => isDark ? darkBackground : lightBackground;
  static Color get surfaceWhite => isDark ? darkSurface : lightSurface;
  static Color get surfaceAlt => isDark ? darkSurfaceAlt : lightSurfaceAlt;
  static Color get textPrimary => isDark ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary =>
      isDark ? darkTextSecondary : lightTextSecondary;
  static Color get textMuted => isDark ? darkTextMuted : lightTextMuted;
  static Color get divider => isDark ? darkDivider : lightDivider;
  static Color get tealLight => isDark ? darkTealTint : lightTealTint;
  static Color get cardShadow => isDark ? darkShadow : lightShadow;

  /// Strong text / icon colour for content sitting on a card or background
  /// (navy in light mode, near-white in dark mode).
  static Color get onSurfaceStrong => isDark ? darkTextPrimary : lightNavy;

  /// Brand gradients for cards, buttons and highlights (website .btn).
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF22D3EE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color inputTextColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkTextPrimary
      : lightTextPrimary;

  static Color inputFillColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? darkInputFill
      : lightInputFill;

  /// Status / navigation bar style for the current theme. The website header
  /// follows the theme (light header in light mode), so the icons must too.
  static SystemUiOverlayStyle overlayFor(bool dark) => SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    statusBarBrightness: dark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
  );

  /// Call whenever the theme mode changes. Updates [isDark], keeps the status
  /// bar / navigation bar icons readable and forces a full rebuild so that
  /// every widget re-reads the palette.
  static void applySystemUI(ThemeMode mode) {
    final dark = mode == ThemeMode.dark;
    final changed = dark != isDark;
    isDark = dark;
    SystemChrome.setSystemUIOverlayStyle(overlayFor(dark));
    if (changed) _rebuildEverything();
  }

  static void _rebuildEverything() {
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      void rebuild(Element element) {
        element.markNeedsBuild();
        element.visitChildren(rebuild);
      }

      binding.rootElement?.visitChildren(rebuild);
    });
    binding.ensureVisualUpdate();
  }

  static ThemeData get lightTheme => _buildTheme(dark: false);
  static ThemeData get darkTheme => _buildTheme(dark: true);

  static TextTheme _textTheme(Color p, Color s, Color m) {
    TextStyle t(double size, FontWeight w, Color c) =>
        TextStyle(fontSize: size, fontWeight: w, color: c);
    final base = GoogleFonts.plusJakartaSansTextTheme(
      TextTheme(
        displayLarge: t(32, FontWeight.w700, p),
        displayMedium: t(28, FontWeight.w700, p),
        displaySmall: t(24, FontWeight.w700, p),
        headlineLarge: t(22, FontWeight.w700, p),
        headlineMedium: t(20, FontWeight.w600, p),
        headlineSmall: t(18, FontWeight.w600, p),
        titleLarge: t(16, FontWeight.w600, p),
        titleMedium: t(15, FontWeight.w600, p),
        titleSmall: t(14, FontWeight.w500, p),
        bodyLarge: t(15, FontWeight.w400, p),
        bodyMedium: t(14, FontWeight.w400, p),
        bodySmall: t(12, FontWeight.w400, s),
        labelLarge: t(14, FontWeight.w600, p),
        labelMedium: t(12, FontWeight.w600, s),
        labelSmall: t(11, FontWeight.w500, m),
      ),
    );
    // Website headings use Fraunces (serif), body text Plus Jakarta Sans.
    TextStyle serif(TextStyle? st) =>
        GoogleFonts.fraunces(textStyle: st, fontWeight: FontWeight.w700);
    return base.copyWith(
      displayLarge: serif(base.displayLarge),
      displayMedium: serif(base.displayMedium),
      displaySmall: serif(base.displaySmall),
      headlineLarge: serif(base.headlineLarge),
      headlineMedium: serif(base.headlineMedium),
      headlineSmall: serif(base.headlineSmall),
    );
  }

  static ThemeData _buildTheme({required bool dark}) {
    final navy = dark ? darkNavy : lightNavy;
    final bg = dark ? darkBackground : lightBackground;
    final surface = dark ? darkSurface : lightSurface;
    final textP = dark ? darkTextPrimary : lightTextPrimary;
    final textS = dark ? darkTextSecondary : lightTextSecondary;
    final textM = dark ? darkTextMuted : lightTextMuted;
    final dividerColor = dark ? darkDivider : lightDivider;
    final outline = dark ? darkOutline : lightOutline;
    final fill = dark ? darkInputFill : lightInputFill;

    final ColorScheme scheme = dark
        ? ColorScheme.dark(
            primary: tealAccent,
            onPrimary: const Color(0xFF04202A),
            primaryContainer: darkTealTint,
            onPrimaryContainer: lightTealTint,
            secondary: tealAccent,
            onSecondary: const Color(0xFF04202A),
            secondaryContainer: darkTealTint,
            onSecondaryContainer: lightTealTint,
            surface: surface,
            onSurface: textP,
            surfaceContainerLowest: bg,
            surfaceContainerLow: surface,
            surfaceContainer: surface,
            surfaceContainerHigh: surface,
            surfaceContainerHighest: darkInputFill,
            onSurfaceVariant: textS,
            error: const Color(0xFFCF6679),
            onError: Colors.white,
            outline: darkOutline,
            outlineVariant: darkDivider,
          )
        : ColorScheme.light(
            primary: lightNavy,
            onPrimary: Colors.white,
            primaryContainer: lightTealTint,
            onPrimaryContainer: lightNavy,
            secondary: tealAccent,
            onSecondary: const Color(0xFF04202A),
            secondaryContainer: lightTealTint,
            onSecondaryContainer: lightNavy,
            surface: lightSurface,
            onSurface: lightTextPrimary,
            surfaceContainerHighest: lightBackground,
            onSurfaceVariant: lightTextSecondary,
            error: error,
            onError: Colors.white,
            outline: lightOutline,
            outlineVariant: lightDivider,
            inverseSurface: lightNavy,
            onInverseSurface: Colors.white,
          );

    OutlineInputBorder border(Color c, [double w = 1.5]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c, width: w),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: surface,
      // Tap / hover / focus feedback everywhere (buttons, list tiles, InkWells)
      splashFactory: InkRipple.splashFactory,
      splashColor: tealAccent.withAlpha(48),
      highlightColor: tealAccent.withAlpha(22),
      hoverColor: tealAccent.withAlpha(20),
      focusColor: tealAccent.withAlpha(26),
      // Smooth animated screen transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: _textTheme(textP, textS, textM),
      appBarTheme: AppBarThemeData(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        // App bars stay a dark navy bar in both themes -> light status icons.
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
        ),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: dividerColor),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tealAccent,
          foregroundColor: const Color(0xFF04202A),
          elevation: 0,
          animationDuration: const Duration(milliseconds: 250),
          overlayColor: Colors.white.withAlpha(38),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: border(outline),
        enabledBorder: border(outline),
        focusedBorder: border(tealAccent, 2),
        errorBorder: border(dark ? const Color(0xFFCF6679) : error),
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: textS),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: dark ? textS : textM,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: tealAccent,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: dark ? textP : null,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        side: BorderSide(color: outline),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      dividerTheme: DividerThemeData(color: dividerColor, thickness: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
