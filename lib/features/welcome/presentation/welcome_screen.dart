import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minHeight = constraints.hasBoundedHeight
                ? math.max(0.0, constraints.maxHeight - (AppSpacing.p16 * 2))
                : 0.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageHorizontal,
                vertical: AppSpacing.p16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Top Header Row
                      _buildHeader(),
                      const SizedBox(height: AppSpacing.p20),

                      // 2. Hero Stacked Flashcard Illustration
                      _buildHeroStackedCard(),
                      const SizedBox(height: AppSpacing.p20),

                      // 3. Headline & Description
                      _buildHeadlineAndDescription(),
                      const SizedBox(height: AppSpacing.p20),

                      // 4. Three Feature Mini-Cards
                      _buildFeatureCardsRow(),
                      const SizedBox(height: AppSpacing.p20),

                      // 5. Primary CTA Button
                      _buildCtaButton(context),
                      const SizedBox(height: AppSpacing.p24),

                      // 6. Spacer pushing footer to bottom of viewport on taller screens
                      const Spacer(),

                      // 7. Footer
                      const Text(
                        'VERSI 1.1 • RECALLME © 2026 BY TUBAGUS. ALL RIGHTS RESERVED',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTextStyles.bodyFont,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                          color: AppColors.disabledText,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.p8),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: AppDecorations.brutalBox(
                  backgroundColor: AppColors.primary,
                  borderRadius: AppRadii.sm,
                  borderWidth: AppBorders.standard,
                  shadows: AppDecorations.shadowSm,
                ),
                child: const Icon(Icons.bolt, size: 26, color: AppColors.ink),
              ),
              const SizedBox(width: AppSpacing.p8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'RecallMe',
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h2.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'MEMORY TRAINER',
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(
                        fontSize: 10,
                        letterSpacing: 0.8,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.p8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: AppDecorations.brutalBox(
            backgroundColor: AppColors.surface,
            borderRadius: 20,
            borderWidth: AppBorders.thin,
            shadows: AppDecorations.shadowSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF8CE02A),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'SM-2 ENGINE',
                style: TextStyle(
                  fontFamily: AppTextStyles.headingFont,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroStackedCard() {
    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Floating ornament: Top-Left Pink Star Box
          Positioned(
            top: 2,
            left: 2,
            child: Transform.rotate(
              angle: -0.18,
              child: Container(
                width: 24,
                height: 24,
                decoration: AppDecorations.brutalBox(
                  backgroundColor: AppColors.coral,
                  borderRadius: 6,
                  borderWidth: AppBorders.thin,
                  shadows: AppDecorations.shadowSm,
                ),
                child: const Icon(Icons.star, size: 14, color: AppColors.ink),
              ),
            ),
          ),

          // Floating ornament: Top-Right Cyan Circle
          Positioned(
            top: 8,
            right: 2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.sky,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.ink,
                  width: AppBorders.thin,
                ),
                boxShadow: AppDecorations.shadowSm,
              ),
            ),
          ),

          // Floating ornament: Bottom-Left Yellow Tilted Square
          Positioned(
            bottom: 6,
            left: 2,
            child: Transform.rotate(
              angle: 0.22,
              child: Container(
                width: 18,
                height: 18,
                decoration: AppDecorations.brutalBox(
                  backgroundColor: AppColors.primary,
                  borderRadius: 4,
                  borderWidth: AppBorders.thin,
                  shadows: AppDecorations.shadowSm,
                ),
              ),
            ),
          ),

          // Floating ornament: Bottom-Right Purple Bulb Circle
          Positioned(
            bottom: 6,
            right: 2,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.purple,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.ink,
                  width: AppBorders.thin,
                ),
                boxShadow: AppDecorations.shadowSm,
              ),
              child: const Icon(
                Icons.lightbulb_outline,
                size: 15,
                color: Colors.white,
              ),
            ),
          ),

          // Back Layer 1: Left-tilted Teal Card slice
          Positioned(
            left: 14,
            right: 14,
            top: 30,
            child: Transform.rotate(
              angle: -0.035,
              alignment: Alignment.topCenter,
              child: Container(
                height: 196,
                decoration: AppDecorations.brutalBox(
                  backgroundColor: AppColors.teal,
                  borderRadius: AppRadii.lg,
                  borderWidth: AppBorders.standard,
                  shadows: AppDecorations.shadowSm,
                ),
              ),
            ),
          ),

          // Back Layer 2: Right-tilted Purple Card slice
          Positioned(
            left: 14,
            right: 14,
            top: 30,
            child: Transform.rotate(
              angle: 0.035,
              alignment: Alignment.topCenter,
              child: Container(
                height: 196,
                decoration: AppDecorations.brutalBox(
                  backgroundColor: AppColors.purple,
                  borderRadius: AppRadii.lg,
                  borderWidth: AppBorders.standard,
                  shadows: AppDecorations.shadowSm,
                ),
              ),
            ),
          ),

          // Main Front Card: Clean White brutalist box
          Positioned(
            left: 14,
            right: 14,
            top: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: AppDecorations.brutalBox(
                backgroundColor: AppColors.surface,
                borderRadius: AppRadii.lg,
                borderWidth: AppBorders.bold,
                shadows: AppDecorations.shadowMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                              border: Border.all(
                                color: AppColors.ink,
                                width: AppBorders.thin,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: AppColors.ink,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'KARTU #01',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.headingFont,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.lime,
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                              border: Border.all(
                                color: AppColors.ink,
                                width: AppBorders.thin,
                              ),
                            ),
                            child: const Text(
                              '+100% RETENSI',
                              style: TextStyle(
                                fontFamily: AppTextStyles.headingFont,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Subtitle & Title
                  const Text(
                    'METODE RAHASIA JUARA',
                    style: TextStyle(
                      fontFamily: AppTextStyles.headingFont,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Active Recall & Spaced\nRepetition',
                    style: TextStyle(
                      fontFamily: AppTextStyles.headingFont,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Progress Bar + Speed Indicator
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.disabledSurface,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: AppColors.ink,
                              width: AppBorders.thin,
                            ),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.78,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.teal,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.p12),
                      const Text(
                        '2.4x Cepat',
                        style: TextStyle(
                          fontFamily: AppTextStyles.bodyFont,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadlineAndDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Verified Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: AppDecorations.brutalBox(
            backgroundColor: const Color(0xFFD6C7FF),
            borderRadius: AppRadii.sm,
            borderWidth: AppBorders.thin,
            shadows: AppDecorations.shadowSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.verified, size: 14, color: AppColors.ink),
              SizedBox(width: 6),
              Text(
                'METODE ILMIAH TERBUKTI',
                style: TextStyle(
                  fontFamily: AppTextStyles.headingFont,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Headline
        const Text(
          'Belajar hari ini,',
          style: TextStyle(
            fontFamily: AppTextStyles.headingFont,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: AppDecorations.brutalBox(
            backgroundColor: AppColors.primary,
            borderRadius: 6,
            borderWidth: AppBorders.standard,
            shadows: AppDecorations.shadowSm,
          ),
          child: const Text(
            'ingat lebih lama.',
            style: TextStyle(
              fontFamily: AppTextStyles.headingFont,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Description
        const Text(
          'Kuasai materi ujian, kosakata bahasa asing, atau sintaks coding lebih cepat dengan flashcard pintar berjadwal otomatis.',
          style: TextStyle(
            fontFamily: AppTextStyles.bodyFont,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.ink,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCardsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildFeatureCard(
            icon: Icons.bolt,
            iconBg: AppColors.primary,
            line1: 'Active',
            line2: 'Recall',
          ),
        ),
        const SizedBox(width: AppSpacing.p12),
        Expanded(
          child: _buildFeatureCard(
            icon: Icons.sync,
            iconBg: AppColors.sky,
            line1: 'Spaced',
            line2: 'SM-2',
          ),
        ),
        const SizedBox(width: AppSpacing.p12),
        Expanded(
          child: _buildFeatureCard(
            icon: Icons.insights,
            iconBg: AppColors.teal,
            line1: 'Progress',
            line2: 'Terukur',
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconBg,
    required String line1,
    required String line2,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.p12,
        horizontal: AppSpacing.p8,
      ),
      decoration: AppDecorations.brutalBox(
        backgroundColor: AppColors.surface,
        borderRadius: AppRadii.md,
        borderWidth: AppBorders.standard,
        shadows: AppDecorations.shadowSm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: AppColors.ink, width: AppBorders.thin),
            ),
            child: Icon(icon, size: 20, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          Text(
            line1,
            style: const TextStyle(
              fontFamily: AppTextStyles.bodyFont,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              height: 1.15,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            line2,
            style: const TextStyle(
              fontFamily: AppTextStyles.bodyFont,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              height: 1.15,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCtaButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/login'),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: AppDecorations.brutalBox(
          backgroundColor: AppColors.primary,
          borderRadius: AppRadii.md,
          borderWidth: AppBorders.standard,
          shadows: AppDecorations.shadowMd,
        ),
        child: Row(
          children: [
            const Expanded(
              child: Center(
                child: Text(
                  'MULAI BELAJAR SEKARANG',
                  style: TextStyle(
                    fontFamily: AppTextStyles.headingFont,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(
                  color: AppColors.ink,
                  width: AppBorders.thin,
                ),
              ),
              child: const Icon(
                Icons.arrow_forward,
                size: 20,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
