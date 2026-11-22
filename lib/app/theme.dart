import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Satu set warna YukBadmin. Ada versi terang (dari desain final Figma)
/// dan versi gelap (permintaan UAT).
class YbPalette {
  const YbPalette({
    required this.ink,
    required this.muted,
    required this.bg,
    required this.surface,
    required this.line,
    required this.primary,
    required this.primaryDark,
    required this.primarySoft,
    required this.accent,
    required this.accentSoft,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.night,
  });

  final Color ink;
  final Color muted;
  final Color bg;
  final Color surface;
  final Color line;
  final Color primary;
  final Color primaryDark;
  final Color primarySoft;
  final Color accent;
  final Color accentSoft;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color night;

  static const light = YbPalette(
    ink: Color(0xFF14110F),
    muted: Color(0xFF6B625D),
    bg: Color(0xFFFAF7F5),
    surface: Color(0xFFFFFFFF),
    line: Color(0xFFE8DFDA),
    primary: Color(0xFFD71920),
    primaryDark: Color(0xFFA81016),
    primarySoft: Color(0xFFFBE1E1),
    accent: Color(0xFFFFC629),
    accentSoft: Color(0xFFFFF1C2),
    success: Color(0xFF17693F),
    successSoft: Color(0xFFD9F0E1),
    warning: Color(0xFF8A4B00),
    warningSoft: Color(0xFFFDE8CF),
    night: Color(0xFF14110F),
  );

  static const dark = YbPalette(
    ink: Color(0xFFF3EEEA),
    muted: Color(0xFFA9A09A),
    bg: Color(0xFF14110F),
    surface: Color(0xFF211C19),
    line: Color(0xFF3A322D),
    primary: Color(0xFFE5393F),
    primaryDark: Color(0xFFFFADB0),
    primarySoft: Color(0xFF42191B),
    accent: Color(0xFFFFC629),
    accentSoft: Color(0xFF3B3012),
    success: Color(0xFF6FD39A),
    successSoft: Color(0xFF173322),
    warning: Color(0xFFFFC27A),
    warningSoft: Color(0xFF3D2A12),
    night: Color(0xFF3D3430),
  );
}

/// Token warna YukBadmin. Nilainya mengikuti tema yang sedang aktif
/// (lihat [YbColors.use]), jadi tidak bisa dipakai di dalam `const`.
abstract final class YbColors {
  static YbPalette _palette = YbPalette.light;

  /// Mengganti palet aktif. Dipanggil `YukBadminApp` saat tema berubah.
  static void use(Brightness brightness) => _palette =
      brightness == Brightness.dark ? YbPalette.dark : YbPalette.light;

  static bool get isDark => identical(_palette, YbPalette.dark);

  static Color get ink => _palette.ink;
  static Color get muted => _palette.muted;
  static Color get bg => _palette.bg;
  static Color get surface => _palette.surface;
  static Color get line => _palette.line;
  static Color get primary => _palette.primary;
  static Color get primaryDark => _palette.primaryDark;
  static Color get primarySoft => _palette.primarySoft;
  static Color get accent => _palette.accent;
  static Color get accentSoft => _palette.accentSoft;
  static Color get success => _palette.success;
  static Color get successSoft => _palette.successSoft;
  static Color get warning => _palette.warning;
  static Color get warningSoft => _palette.warningSoft;

  /// Latar yang tetap gelap di kedua tema, misalnya hero dashboard.
  static Color get night => _palette.night;

  /// Teks di atas warna aksen kuning. Tetap gelap di kedua tema.
  static const onAccent = Color(0xFF14110F);
}

abstract final class YbRadius {
  static const sm = 8.0;
  static const md = 14.0;
  static const pill = 999.0;
}

/// Gaya teks. Judul memakai Archivo miring tebal, isi memakai Red Hat Display.
abstract final class YbText {
  static TextStyle display({
    double size = 28,
    Color? color,
    double height = 1.1,
  }) => GoogleFonts.archivo(
    fontSize: size,
    fontWeight: FontWeight.w800,
    fontStyle: FontStyle.italic,
    color: color ?? YbColors.ink,
    height: height,
    letterSpacing: -0.4,
  );

  static TextStyle body({
    double size = 14,
    Color? color,
    FontWeight weight = FontWeight.w500,
    double height = 1.4,
  }) => GoogleFonts.redHatDisplay(
    fontSize: size,
    fontWeight: weight,
    color: color ?? YbColors.ink,
    height: height,
  );

  static TextStyle label({Color? color}) =>
      body(size: 12, color: color ?? YbColors.muted);
}

/// Membangun tema dari palet yang sedang aktif di [YbColors].
ThemeData buildYbTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: YbColors.isDark ? Brightness.dark : Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      brightness: YbColors.isDark ? Brightness.dark : Brightness.light,
      seedColor: YbColors.primary,
      primary: YbColors.primary,
      onPrimary: Colors.white,
      surface: YbColors.surface,
      onSurface: YbColors.ink,
    ),
    scaffoldBackgroundColor: YbColors.bg,
  );

  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(YbRadius.sm),
    borderSide: BorderSide(color: color),
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: GoogleFonts.redHatDisplay().fontFamily,
      bodyColor: YbColors.ink,
      displayColor: YbColors.ink,
    ),
    dividerColor: YbColors.line,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: YbColors.surface,
      hintStyle: YbText.body(color: YbColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(YbColors.line),
      enabledBorder: border(YbColors.line),
      focusedBorder: border(YbColors.primary),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: YbColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(YbRadius.sm),
        ),
        textStyle: YbText.body(size: 16, weight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: YbColors.ink,
        backgroundColor: YbColors.surface,
        minimumSize: const Size(0, 44),
        side: BorderSide(color: YbColors.line, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(YbRadius.sm),
        ),
        textStyle: YbText.body(size: 14, weight: FontWeight.w700),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: YbColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: YbColors.night,
      contentTextStyle: YbText.body(color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
