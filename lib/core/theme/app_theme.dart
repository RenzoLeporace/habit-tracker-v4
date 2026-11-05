import 'package:flutter/material.dart';

import 'package:mi_espacio/core/theme/app_colors.dart';

/// Tema oscuro de la app: un solo acento verde para botones, selecciones y foco.
class AppTheme {
  static const _sobreVerde = Color(0xFF052E16);

  static ThemeData oscuro() {
    const esquema = ColorScheme.dark(
      primary: AppColors.green,
      onPrimary: _sobreVerde,
      primaryContainer: AppColors.greenDark,
      onPrimaryContainer: AppColors.green,
      secondary: AppColors.green,
      onSecondary: _sobreVerde,
      secondaryContainer: AppColors.greenDark,
      onSecondaryContainer: AppColors.green,
      tertiary: AppColors.amber,
      surface: AppColors.bg2,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.text2,
      surfaceContainerLowest: AppColors.bg,
      surfaceContainerLow: AppColors.bg2,
      surfaceContainer: AppColors.bg2,
      surfaceContainerHigh: AppColors.bg3,
      surfaceContainerHighest: AppColors.bg3,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      error: AppColors.red,
    );
    final redondeado = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: esquema,
      scaffoldBackgroundColor: AppColors.bg,
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
      cardTheme: CardThemeData(
        color: AppColors.bg2,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bg2,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bg3,
        labelStyle: const TextStyle(color: AppColors.text2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: redondeado,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: redondeado,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.bg3,
        contentTextStyle: const TextStyle(color: AppColors.text),
        actionTextColor: AppColors.green,
        shape: redondeado,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.bg2,
        indicatorColor: AppColors.greenDark,
        iconTheme: WidgetStateProperty.resolveWith(
          (estados) => IconThemeData(
            color: estados.contains(WidgetState.selected)
                ? AppColors.green
                : AppColors.text2,
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.bg3,
        shape: redondeado,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.bg3,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: AppColors.text, fontSize: 12),
      ),
    );
  }
}
