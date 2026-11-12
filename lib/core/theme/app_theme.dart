import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
    );
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final background = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      visualDensity: VisualDensity.standard,
      appBarTheme: _appBarTheme(scheme, background),
      textTheme: _textTheme(scheme),
      cardTheme: _cardTheme(isDark, border),
      inputDecorationTheme: _inputTheme(isDark, border, scheme.primary),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: border),
        labelStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      filledButtonTheme: _filledButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(border),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.onPrimary;
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.surfaceContainerHighest;
        }),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        elevation: 0,
        showDragHandle: false,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
    );
  }

  static AppBarTheme _appBarTheme(ColorScheme scheme, Color background) =>
      AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      );

  static CardThemeData _cardTheme(bool isDark, Color border) => CardThemeData(
    elevation: 0,
    color: isDark ? AppColors.darkCard : AppColors.lightCard,
    surfaceTintColor: Colors.transparent,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: border),
    ),
  );

  static InputDecorationTheme _inputTheme(
    bool isDark,
    Color border,
    Color focus,
  ) {
    final shape = BorderRadius.circular(16);
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? AppColors.darkInput : AppColors.lightInput,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: shape,
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: shape,
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: shape,
        borderSide: BorderSide(color: focus, width: 1.5),
      ),
    );
  }

  static FilledButtonThemeData _filledButtonTheme() => FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    ),
  );

  static OutlinedButtonThemeData _outlinedButtonTheme(Color border) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: border),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      );

  static TextTheme _textTheme(ColorScheme scheme) => TextTheme(
    displaySmall: TextStyle(
      color: scheme.onSurface,
      fontSize: 36,
      fontWeight: FontWeight.w700,
      letterSpacing: -1,
    ),
    headlineMedium: TextStyle(
      color: scheme.onSurface,
      fontSize: 26,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    titleLarge: TextStyle(
      color: scheme.onSurface,
      fontSize: 20,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: TextStyle(
      color: scheme.onSurface,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(color: scheme.onSurface, fontSize: 16, height: 1.45),
    bodyMedium: TextStyle(
      color: scheme.onSurfaceVariant,
      fontSize: 14,
      height: 1.4,
    ),
    labelLarge: TextStyle(
      color: scheme.onSurface,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );
}
