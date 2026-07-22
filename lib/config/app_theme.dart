import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppColorsGold {
  AppColorsGold._();

  static const primary = Color(0xFFFFD700);
  static const onPrimary = Color(0xFF1E1E1E);
  static const primaryContainer = Color(0xFFFFF8E1);
  static const onPrimaryContainer = Color(0xFF3E2E00);
  static const secondary = Color(0xFF1E40AF);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFDBEAFE);
  static const tertiary = Color(0xFF059669);
  static const background = Color(0xFFFAFAFA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF2F2F2);
  static const onSurface = Color(0xFF1E1E1E);
  static const onSurfaceVariant = Color(0xFF666666);
  static const outline = Color(0xFFE0E0E0);
  static const outlineVariant = Color(0xFFF0F0F0);
  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFFF5252);
  static const onError = Color(0xFFFFFFFF);
  static const shadow = Color(0xFF000000);
}

class AppColors {
  AppColors._();

  static const primary = Color(0xFF2563EB); // Blue 600
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFDBEAFE); // Blue 100
  static const onPrimaryContainer = Color(0xFF1E3A8A); // Blue 900
  static const secondary = Color(0xFFFFD700); // Gold
  static const onSecondary = Color(0xFF1E1E1E);
  static const secondaryContainer = Color(0xFFFFF8E1);
  static const tertiary = Color(0xFF059669);
  static const background = Color(0xFFF8FAFC); // Slate 50
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFF1F5F9); // Slate 100
  static const onSurface = Color(0xFF0F172A); // Slate 900
  static const onSurfaceVariant = Color(0xFF475569); // Slate 600
  static const outline = Color(0xFFCBD5E1); // Slate 300
  static const outlineVariant = Color(0xFFE2E8F0); // Slate 200
  static const success = Color(0xFF10B981); // Emerald 500
  static const error = Color(0xFFEF4444); // Red 500
  static const onError = Color(0xFFFFFFFF);
  static const shadow = Color(0xFF000000);
}

class AppColorsDark {
  AppColorsDark._();

  static const primary = Color(0xFF3B82F6); // Blue 500 (lighter for dark mode)
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF1E3A8A); // Blue 900
  static const onPrimaryContainer = Color(0xFFDBEAFE); // Blue 100
  static const secondary = Color(0xFFFFD700); // Gold
  static const onSecondary = Color(0xFF1E1E1E);
  static const secondaryContainer = Color(0xFF3E2E00);
  static const tertiary = Color(0xFF34D399); // Emerald 400
  static const background = Color(0xFF0F172A); // Slate 900
  static const surface = Color(0xFF1E293B); // Slate 800
  static const surfaceDim = Color(0xFF0F172A); // Slate 900
  static const onSurface = Color(0xFFF8FAFC); // Slate 50
  static const onSurfaceVariant = Color(0xFF94A3B8); // Slate 400
  static const outline = Color(0xFF475569); // Slate 600
  static const outlineVariant = Color(0xFF334155); // Slate 700
  static const success = Color(0xFF34D399); // Emerald 400
  static const error = Color(0xFFF87171); // Red 400
  static const onError = Color(0xFFFFFFFF);
  static const shadow = Color(0xFF000000);
}

class AppTheme {
  AppTheme._();

  static const _borderRadius = 16.0;

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        tertiary: AppColors.tertiary,
        surface: AppColors.surface,
        surfaceDim: AppColors.surfaceDim,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        error: AppColors.error,
        onError: AppColors.onError,
        shadow: AppColors.shadow,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        foregroundColor: AppColors.onSurface,
        shape: Border(
          bottom: BorderSide(color: AppColors.outline.withValues(alpha: 0.5)),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: AppColors.shadow.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          side: BorderSide(color: AppColors.outline.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 2,
        shadowColor: AppColors.shadow.withValues(alpha: 0.08),
        indicatorColor: AppColors.primary,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: AppColors.onSurface, size: 22);
          }
          return IconThemeData(color: AppColors.onSurfaceVariant, size: 22);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDim,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primaryContainer,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.onPrimaryContainer,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.outline.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: const CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColorsDark.primary,
        onPrimary: AppColorsDark.onPrimary,
        primaryContainer: AppColorsDark.primaryContainer,
        onPrimaryContainer: AppColorsDark.onPrimaryContainer,
        secondary: AppColorsDark.secondary,
        onSecondary: AppColorsDark.onSecondary,
        secondaryContainer: AppColorsDark.secondaryContainer,
        tertiary: AppColorsDark.tertiary,
        surface: AppColorsDark.surface,
        surfaceDim: AppColorsDark.surfaceDim,
        onSurface: AppColorsDark.onSurface,
        onSurfaceVariant: AppColorsDark.onSurfaceVariant,
        outline: AppColorsDark.outline,
        outlineVariant: AppColorsDark.outlineVariant,
        error: AppColorsDark.error,
        onError: AppColorsDark.onError,
        shadow: AppColorsDark.shadow,
      ),
      scaffoldBackgroundColor: AppColorsDark.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorsDark.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        foregroundColor: AppColorsDark.onSurface,
        shape: Border(
          bottom: BorderSide(color: AppColorsDark.outline.withValues(alpha: 0.5)),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColorsDark.surface,
        elevation: 0,
        shadowColor: AppColorsDark.shadow.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          side: BorderSide(color: AppColorsDark.outline.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColorsDark.surface,
        elevation: 2,
        shadowColor: AppColorsDark.shadow.withValues(alpha: 0.2),
        indicatorColor: AppColorsDark.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColorsDark.onSurface,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColorsDark.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: AppColorsDark.onPrimaryContainer, size: 22);
          }
          return IconThemeData(color: AppColorsDark.onSurfaceVariant, size: 22);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsDark.surfaceDim,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsDark.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsDark.error),
        ),
        labelStyle: const TextStyle(
          color: AppColorsDark.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: AppColorsDark.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsDark.primary,
          foregroundColor: AppColorsDark.onPrimary,
          elevation: 0,
          shadowColor: AppColorsDark.primary.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColorsDark.primaryContainer,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColorsDark.onPrimaryContainer,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dividerTheme: DividerThemeData(
        color: AppColorsDark.outline.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        backgroundColor: AppColorsDark.surface,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColorsDark.surfaceDim,
        contentTextStyle: const TextStyle(color: AppColorsDark.onSurface),
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: const CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
