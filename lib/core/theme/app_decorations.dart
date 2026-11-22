import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Neo-Brutalist shadow and decoration helpers
/// Strict hard offset shadows with zero blur
/// Source: docs/DESIGN.md v1.1
class AppDecorations {
  AppDecorations._();

  // Hard Box Shadows
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: AppColors.ink,
      offset: Offset(2, 2),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: AppColors.ink,
      offset: Offset(4, 4),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: AppColors.ink,
      offset: Offset(5, 5),
      blurRadius: 0,
      spreadRadius: 0,
    ),
  ];

  // Common Container Decoration
  static BoxDecoration brutalBox({
    Color backgroundColor = AppColors.surface,
    Color borderColor = AppColors.ink,
    double borderWidth = AppBorders.standard,
    double borderRadius = AppRadii.md,
    List<BoxShadow> shadows = shadowMd,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: shadows,
    );
  }
}
