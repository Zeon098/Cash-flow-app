import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const emerald = Color(0xFF10B981);
  static const emeraldDeep = Color(0xFF047857);
  static const coral = Color(0xFFF43F5E);
  static const coralDeep = Color(0xFFBE123C);
  static const ink = Color(0xFF0F172A);
  static const slate = Color(0xFF64748B);
  static const lightBg = Color(0xFFF6F7F9);
  static const darkBg = Color(0xFF0A101D);
  static const darkSurface = Color(0xFF131B2C);
  static const sky = Color(0xFF0EA5E9);
  static const amber = Color(0xFFF59E0B);
  static const violet = Color(0xFF8B5CF6);

  /// Green for zero/positive, coral for negative.
  static Color signed(double v) => v < -0.004 ? coral : emerald;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final dark = b == Brightness.dark;
    final bg = dark ? AppColors.darkBg : AppColors.lightBg;
    final surface = dark ? AppColors.darkSurface : Colors.white;
    final onSurface = dark ? const Color(0xFFE8ECF4) : AppColors.ink;

    final scheme = ColorScheme.fromSeed(seedColor: AppColors.emerald, brightness: b).copyWith(
      primary: AppColors.emerald,
      onPrimary: Colors.white,
      surface: surface,
      onSurface: onSurface,
      error: AppColors.coral,
      outlineVariant: dark ? const Color(0x1FFFFFFF) : const Color(0xFFE5E8EE),
    );

    final fieldFill = dark ? const Color(0x0DFFFFFF) : const Color(0xFFF1F3F7);
    OutlineInputBorder border([Color? c, double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: c == null ? BorderSide.none : BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: onSurface, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        border: border(),
        enabledBorder: border(),
        focusedBorder: border(AppColors.emerald, 1.5),
        errorBorder: border(AppColors.coral),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: AppColors.slate),
        hintStyle: TextStyle(color: AppColors.slate.withValues(alpha: .7)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        height: 68,
        indicatorColor: AppColors.emerald.withValues(alpha: .16),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              fontSize: 11.5,
              fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: s.contains(WidgetState.selected) ? AppColors.emerald : AppColors.slate,
            )),
        iconTheme: WidgetStateProperty.resolveWith((s) =>
            IconThemeData(color: s.contains(WidgetState.selected) ? AppColors.emerald : AppColors.slate)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.emerald,
        foregroundColor: Colors.white,
        elevation: 6,
        extendedTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.emerald,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.emerald, textStyle: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
