import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Satu set warna YukBadmin, mengikuti koleksi variabel "YukBadmin Warna v3"
/// di Figma (halaman Final Design v4). Ada versi terang dan gelap.
///
/// Nama lama dipertahankan supaya layar tidak perlu diubah satu per satu:
/// `ink` = text/primary, `muted` = text/secondary, `bg` = surface/page,
/// `surface` = surface/card, `line` = border/subtle, `primary` =
/// action/primary, `primarySoft`/`primaryDark` = selection/bg dan
/// selection/text, `night` = brand/hero.
class YbPalette {
  const YbPalette({
    required this.ink,
    required this.muted,
    required this.bg,
    required this.surface,
    required this.line,
    required this.control,
    required this.primary,
    required this.onPrimary,
    required this.pressed,
    required this.primaryDark,
    required this.primarySoft,
    required this.accent,
    required this.accentSoft,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.error,
    required this.onError,
    required this.errorSoft,
    required this.pending,
    required this.pendingSoft,
    required this.night,
    required this.onNight,
  });

  final Color ink;
  final Color muted;
  final Color bg;
  final Color surface;
  final Color line;
  final Color control;
  final Color primary;
  final Color onPrimary;
  final Color pressed;
  final Color primaryDark;
  final Color primarySoft;
  final Color accent;
  final Color accentSoft;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color error;
  final Color onError;
  final Color errorSoft;
  final Color pending;
  final Color pendingSoft;
  final Color night;
  final Color onNight;

  static const light = YbPalette(
    ink: Color(0xFF192533),
    muted: Color(0xFF526173),
    bg: Color(0xFFF7F7F2),
    surface: Color(0xFFFFFFFF),
    line: Color(0xFFE2E5E9),
    control: Color(0xFF6A7888),
    primary: Color(0xFF244B76),
    onPrimary: Color(0xFFFFFFFF),
    pressed: Color(0xFF193B60),
    primaryDark: Color(0xFF1F426C),
    primarySoft: Color(0xFFE4EEF9),
    accent: Color(0xFFD5E88A),
    accentSoft: Color(0xFFEEF5D3),
    success: Color(0xFF20643D),
    successSoft: Color(0xFFE1F2E5),
    warning: Color(0xFF764807),
    warningSoft: Color(0xFFFFF0CF),
    error: Color(0xFFA33136),
    onError: Color(0xFFFFFFFF),
    errorSoft: Color(0xFFFCE8E7),
    pending: Color(0xFF475369),
    pendingSoft: Color(0xFFECF0F5),
    night: Color(0xFF13283F),
    onNight: Color(0xFFFFFFFF),
  );

  static const dark = YbPalette(
    ink: Color(0xFFF0F3F6),
    muted: Color(0xFFBCC8D4),
    bg: Color(0xFF101820),
    surface: Color(0xFF1C2835),
    line: Color(0xFF2C3846),
    control: Color(0xFF8592A2),
    primary: Color(0xFFA9C8EF),
    onPrimary: Color(0xFF10263E),
    pressed: Color(0xFF93B9E6),
    primaryDark: Color(0xFFD6E7FA),
    primarySoft: Color(0xFF2C425C),
    accent: Color(0xFFD5E88A),
    accentSoft: Color(0xFF2B3520),
    success: Color(0xFF9CE5B3),
    successSoft: Color(0xFF173C2A),
    warning: Color(0xFFF4CB8B),
    warningSoft: Color(0xFF45351D),
    error: Color(0xFFFFB6B4),
    onError: Color(0xFF5C1114),
    errorSoft: Color(0xFF48252A),
    pending: Color(0xFFD0D9E6),
    pendingSoft: Color(0xFF303A49),
    night: Color(0xFF13283F),
    onNight: Color(0xFFF0F3F6),
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

  /// Garis kontrol yang perlu terlihat jelas, misalnya radio dan kotak centang.
  static Color get control => _palette.control;
  static Color get primary => _palette.primary;

  /// Teks dan ikon di atas [primary].
  static Color get onPrimary => _palette.onPrimary;
  static Color get pressed => _palette.pressed;
  static Color get primaryDark => _palette.primaryDark;
  static Color get primarySoft => _palette.primarySoft;
  static Color get accent => _palette.accent;
  static Color get accentSoft => _palette.accentSoft;
  static Color get success => _palette.success;
  static Color get successSoft => _palette.successSoft;
  static Color get warning => _palette.warning;
  static Color get warningSoft => _palette.warningSoft;
  static Color get error => _palette.error;
  static Color get errorSoft => _palette.errorSoft;
  static Color get pending => _palette.pending;
  static Color get pendingSoft => _palette.pendingSoft;

  /// Latar biru tua yang tetap gelap di kedua tema, misalnya hero dashboard.
  static Color get night => _palette.night;

  /// Teks di atas [night].
  static Color get onNight => _palette.onNight;
  static Color get onError => _palette.onError;

  /// Teks di atas warna aksen hijau limau. Tetap gelap di kedua tema.
  static const onAccent = Color(0xFF192533);
}

abstract final class YbRadius {
  static const sm = 8.0;
  static const md = 14.0;
  static const lg = 22.0;
  static const pill = 999.0;
}

/// Gaya teks Final Design v4: semuanya Inter. Judul tebal tegak, angka besar
/// (jam, nominal) tebal miring seperti papan skor.
abstract final class YbText {
  /// Judul. 32 untuk judul layar, 20 untuk judul seksi, 17 untuk judul kartu.
  static TextStyle display({
    double size = 28,
    Color? color,
    double height = 1.15,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: size >= 24 ? FontWeight.w700 : FontWeight.w600,
    color: color ?? YbColors.ink,
    height: height,
    letterSpacing: size >= 24 ? -0.6 : -0.2,
  );

  /// Angka besar miring, misalnya "19.00–22.00" atau "Rp150.000".
  static TextStyle score({double size = 32, Color? color}) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: FontWeight.w800,
    fontStyle: FontStyle.italic,
    color: color ?? YbColors.ink,
    height: 1.05,
    letterSpacing: -0.8,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle body({
    double size = 15,
    Color? color,
    FontWeight weight = FontWeight.w400,
    double height = 1.4,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    color: color ?? YbColors.ink,
    height: height,
  );

  static TextStyle label({Color? color}) =>
      body(size: 13, color: color ?? YbColors.muted);
}

/// Membangun tema dari palet yang sedang aktif di [YbColors].
ThemeData buildYbTheme() {
  final dark = YbColors.isDark;
  final base = ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      brightness: dark ? Brightness.dark : Brightness.light,
      seedColor: YbColors.primary,
      primary: YbColors.primary,
      onPrimary: YbColors.onPrimary,
      secondary: YbColors.primary,
      surface: YbColors.surface,
      onSurface: YbColors.ink,
      error: YbColors.error,
      onError: YbColors.onError,
    ),
    scaffoldBackgroundColor: YbColors.bg,
    splashFactory: InkSparkle.splashFactory,
  );

  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(YbRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );

  final pillShape = const StadiumBorder();

  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: GoogleFonts.inter().fontFamily,
      bodyColor: YbColors.ink,
      displayColor: YbColors.ink,
    ),
    dividerColor: YbColors.line,
    dividerTheme: DividerThemeData(color: YbColors.line, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: YbColors.surface,
      hintStyle: YbText.body(color: YbColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: border(YbColors.line),
      enabledBorder: border(YbColors.line),
      focusedBorder: border(YbColors.primary, 1.5),
      errorBorder: border(YbColors.error),
      focusedErrorBorder: border(YbColors.error, 1.5),
      errorStyle: YbText.body(size: 13, color: YbColors.error),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: YbColors.primary,
        foregroundColor: YbColors.onPrimary,
        disabledBackgroundColor: YbColors.line,
        disabledForegroundColor: YbColors.muted,
        minimumSize: const Size.fromHeight(52),
        shape: pillShape,
        textStyle: YbText.body(size: 16, weight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: YbColors.ink,
        backgroundColor: YbColors.surface,
        minimumSize: const Size(0, 44),
        side: BorderSide(color: YbColors.control),
        shape: pillShape,
        textStyle: YbText.body(size: 15, weight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: YbColors.primary,
        textStyle: YbText.body(size: 15, weight: FontWeight.w600),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(YbColors.surface),
      trackColor: WidgetStateProperty.resolveWith(
        (s) =>
            s.contains(WidgetState.selected) ? YbColors.success : YbColors.line,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? YbColors.primary
            : Colors.transparent,
      ),
      checkColor: WidgetStatePropertyAll(YbColors.onPrimary),
      side: BorderSide(color: YbColors.control, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? YbColors.primary
            : YbColors.control,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: YbColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(YbRadius.lg)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: YbColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(YbRadius.lg),
      ),
      titleTextStyle: YbText.display(size: 20),
      contentTextStyle: YbText.body(color: YbColors.muted),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: YbColors.night,
      contentTextStyle: YbText.body(color: YbColors.onNight),
      actionTextColor: YbColors.accent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(YbRadius.md),
      ),
    ),
  );
}
