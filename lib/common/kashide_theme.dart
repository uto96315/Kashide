import 'package:flutter/material.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';

ThemeData kashideLightTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: mainColor);
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.white,
    canvasColor: Colors.white,
    dividerColor: const Color(0xFFE5E5EA),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1C1C1E),
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color(0xFFF2F2F7),
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: mainColor.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ),
  );
}

ThemeData kashideDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: mainColor,
    brightness: Brightness.dark,
  );
  const scaffold = Color(0xFF0F0F10);
  const elevated = Color(0xFF1C1C1E);
  const border = Color(0xFF2C2C2E);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme.copyWith(
      surface: elevated,
      surfaceContainerHighest: const Color(0xFF2C2C2E),
    ),
    scaffoldBackgroundColor: scaffold,
    canvasColor: scaffold,
    dividerColor: border,
    appBarTheme: const AppBarTheme(
      backgroundColor: scaffold,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: elevated,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: elevated,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: elevated,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2E),
      labelStyle: const TextStyle(color: Color(0xFFAEAEB2)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textTheme: Typography.whiteMountainView,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: elevated,
      indicatorColor: mainColor.withValues(alpha: 0.35),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ),
  );
}

/// 一覧・マイページなどのグループ背景。
Color kashideGroupedBackground(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF0F0F10)
      : const Color(0xFFF2F2F7);
}

Color kashideToolbarIcon(BuildContext context, {bool muted = false}) {
  if (muted) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF8E8E93);
  }
  return Theme.of(context).colorScheme.onSurface;
}

Color kashideFilterBannerFill(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? mainColor.withValues(alpha: 0.14)
      : const Color(0xFFFFF1F5);
}

Color kashideFilterBannerText(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFFFE4EC)
      : const Color(0xFF59434B);
}

Color kashideViewToggleTrackFill(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF2C2C2E)
      : const Color(0xFFFFF1F5);
}

Color kashideViewToggleTrackBorder(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF3A3A3C)
      : const Color(0xFFFFD6E4);
}

Color kashideViewToggleIdleIcon(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFAEAEB2)
      : const Color(0xFF6B6B70);
}

Color kashideGenreTabBarFill(BuildContext context) {
  return Theme.of(context).colorScheme.surface;
}

Color kashidePostCardBackground(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF1C1C1E)
      : Colors.white;
}

Color kashidePostLyricsFill(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF2C2C2E)
      : const Color(0xFFF7F9F9);
}

Color kashidePostLyricsBorder(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF3A3A3C)
      : const Color(0xFFEFF3F4);
}

Color kashidePrimaryText(BuildContext context) {
  return Theme.of(context).colorScheme.onSurface;
}

Color kashideSecondaryText(BuildContext context) {
  return Theme.of(context).colorScheme.onSurfaceVariant;
}
