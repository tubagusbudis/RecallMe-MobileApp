import 'package:material_ui/material_ui.dart';

/// Design tokens for RecallMe Color Palette
/// Source: docs/DESIGN.md v1.1
class AppColors {
  AppColors._();

  // Core Neutrals & Canvas
  static const Color ink = Color(0xFF171717);
  static const Color canvas = Color(0xFFFFF6EC);
  static const Color surface = Color(0xFFFFFCF7);

  // Primary Accent
  static const Color primary = Color(0xFFFFD928); // Vibrant yellow CTA

  // Semantic & Category Accents
  static const Color coral = Color(0xFFFF6477); // Again, attention, delete
  static const Color purple = Color(0xFF9878F5); // Deck accent, secondary
  static const Color teal = Color(0xFF43CDBB); // Good, success
  static const Color lime = Color(0xFFB8E64A); // Easy, fresh accent
  static const Color sky = Color(0xFF54CBE6); // Info, secondary accent
  static const Color orange = Color(0xFFFFA16B); // Hard, warning accent

  // Neutral Hierarchy
  static const Color mutedText = Color(0xFF5C5C5C);
  static const Color disabledSurface = Color(0xFFE8E3DC);
  static const Color disabledText = Color(0xFF77716B);
  static const Color lightBorder = Color(0xFFD4C8BA);

  // Semantic Spaced Repetition Rating Colors
  static const Color ratingAgain = coral;
  static const Color ratingHard = orange;
  static const Color ratingGood = teal;
  static const Color ratingEasy = lime;
}
