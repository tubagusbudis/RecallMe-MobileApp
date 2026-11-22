import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Typography tokens for RecallMe
/// Headings: Space Grotesk Bold/SemiBold
/// Body/UI: Inter Regular/SemiBold/Bold
/// Source: docs/DESIGN.md v1.1
class AppTextStyles {
  AppTextStyles._();

  static const String headingFont = 'Space Grotesk';
  static const String bodyFont = 'Inter';
  static const List<String> fallbackFonts = ['Inter', 'sans-serif'];

  // Headings
  static const TextStyle display = TextStyle(
    fontFamily: headingFont,
    fontFamilyFallback: fallbackFonts,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    height: 1.15,
    color: AppColors.ink,
    letterSpacing: -0.5,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: headingFont,
    fontFamilyFallback: fallbackFonts,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.ink,
    letterSpacing: -0.3,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: headingFont,
    fontFamilyFallback: fallbackFonts,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.ink,
    letterSpacing: -0.2,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: headingFont,
    fontFamilyFallback: fallbackFonts,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.ink,
  );

  // Body Styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: bodyFont,
    fontFamilyFallback: fallbackFonts,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: AppColors.ink,
  );

  static const TextStyle bodyLargeBold = TextStyle(
    fontFamily: bodyFont,
    fontFamilyFallback: fallbackFonts,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.45,
    color: AppColors.ink,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: bodyFont,
    fontFamilyFallback: fallbackFonts,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.ink,
  );

  static const TextStyle bodyMediumBold = TextStyle(
    fontFamily: bodyFont,
    fontFamilyFallback: fallbackFonts,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.ink,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: bodyFont,
    fontFamilyFallback: fallbackFonts,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: AppColors.mutedText,
  );

  static const TextStyle label = TextStyle(
    fontFamily: headingFont,
    fontFamilyFallback: fallbackFonts,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: AppColors.ink,
  );

  static const TextStyle button = TextStyle(
    fontFamily: headingFont,
    fontFamilyFallback: fallbackFonts,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: AppColors.ink,
  );
}
