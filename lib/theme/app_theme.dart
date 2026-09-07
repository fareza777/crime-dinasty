import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Theme-aware colors. Default is paper light; dark is the neo-noir navy set.
class Palette {
  static bool light = false;

  static Color get navy => light ? const Color(0xFFE8E4DC) : const Color(0xFF0B1220);
  static Color get navy2 => light ? const Color(0xFFDDD6CB) : const Color(0xFF121A2B);
  static Color get charcoal => light ? const Color(0xFFD2CBC0) : const Color(0xFF1A2334);
  static Color get card => light ? const Color(0xFFF7F3EA) : const Color(0xFF161D2B);
  static Color get line => light ? const Color(0xFFC4BBAE) : const Color(0xFF2A3348);
  static Color get red => const Color(0xFF8B1E3F);
  static Color get redSoft => light ? const Color(0xFF9A3A48) : const Color(0xFFC45C6A);
  static Color get gold => light ? const Color(0xFF8B6F1E) : const Color(0xFFC9A227);
  static Color get goldSoft => light ? const Color(0xFF6E5818) : const Color(0xFFE8CC6E);
  static Color get cream => light ? const Color(0xFF1A1814) : const Color(0xFFE8E4D9);
  static Color get muted => light ? const Color(0xFF3D3830) : const Color(0xFFC2C8D4);
  static Color get good => const Color(0xFF5E8A5E);
  static Color get warn => const Color(0xFFB07828);
  static Color get onGold => light ? const Color(0xFFF6F0E4) : const Color(0xFF0B1220);
  static Color get scrim => light ? const Color(0xCC2C2820) : const Color(0xC7000000);

  static SystemUiOverlayStyle get overlay => light
      ? SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent)
      : SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent);
}

class AppTheme {
  static ThemeData get dark => _build(light: false);
  static ThemeData get paper => _build(light: true);

  static ThemeData _build({required bool light}) {
    final gold = light ? const Color(0xFF8B6F1E) : const Color(0xFFC9A227);
    final goldSoft = light ? const Color(0xFF6E5818) : const Color(0xFFE8CC6E);
    final ink = light ? const Color(0xFF1A1814) : const Color(0xFFE8E4D9);
    final muted = light ? const Color(0xFF3D3830) : const Color(0xFFC2C8D4);
    final bg = light ? const Color(0xFFE8E4DC) : const Color(0xFF0B1220);
    final scheme = (light ? ColorScheme.light : ColorScheme.dark)(
      surface: bg,
      primary: gold,
      secondary: const Color(0xFF8B1E3F),
      onSurface: ink,
      onPrimary: light ? const Color(0xFFF6F0E4) : const Color(0xFF0B1220),
      error: light ? const Color(0xFF9A3A48) : const Color(0xFFC45C6A),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: light ? Brightness.light : Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      fontFamily: 'DMSans',
      textTheme: TextTheme(
        displayLarge: TextStyle(fontFamily: 'Cinzel', color: gold, fontWeight: FontWeight.w700, letterSpacing: 1.2),
        displayMedium: TextStyle(fontFamily: 'Cinzel', color: goldSoft, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(fontFamily: 'Cinzel', color: ink, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontFamily: 'Cinzel', color: ink, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontFamily: 'DMSans', color: ink, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontFamily: 'DMSans', color: ink, height: 1.35),
        bodyMedium: TextStyle(fontFamily: 'DMSans', color: ink, height: 1.4),
        bodySmall: TextStyle(fontFamily: 'DMSans', color: muted, height: 1.35),
        labelLarge: TextStyle(fontFamily: 'DMSans', color: scheme.onPrimary, fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: gold,
        titleTextStyle: TextStyle(
          fontFamily: 'Cinzel',
          color: gold,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          overflow: TextOverflow.visible,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? gold : muted),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? gold.withValues(alpha: 0.35) : muted.withValues(alpha: 0.25),
        ),
      ),
      sliderTheme: SliderThemeData(activeTrackColor: gold, thumbColor: gold),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: light ? const Color(0xFF2C2820) : const Color(0xFF1A2334),
        contentTextStyle: TextStyle(color: Color(0xFFE8E4D9)),
      ),
    );
  }
}
