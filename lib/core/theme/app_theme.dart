import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// RecallMe ThemeData Configuration
/// Functional Neo-Brutalism with Warm Cream Canvas
class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.canvas,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.ink,
        secondary: AppColors.purple,
        onSecondary: Colors.white,
        error: AppColors.coral,
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
      ),
      fontFamily: AppTextStyles.bodyFont,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.h2,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.ink, width: AppBorders.standard),
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.md)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.ink,
        thickness: AppBorders.thin,
        space: AppSpacing.p24,
      ),
    );
  }
}
