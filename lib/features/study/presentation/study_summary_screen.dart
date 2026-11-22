import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../flashcards/application/flashcard_controller.dart';

class StudySummaryScreen extends ConsumerWidget {
  final String deckId;
  final int count;

  const StudySummaryScreen({
    super.key,
    required this.deckId,
    required this.count,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remainingDue = ref
        .watch(flashcardControllerProvider.notifier)
        .getDueCountForDeck(deckId);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
            vertical: AppSpacing.p24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Celebration Banner
              Container(
                padding: const EdgeInsets.all(AppSpacing.p24),
                decoration: AppDecorations.brutalBox(
                  backgroundColor: AppColors.lime,
                  borderWidth: AppBorders.bold,
                  shadows: AppDecorations.shadowLg,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.ink,
                          width: AppBorders.standard,
                        ),
                        boxShadow: AppDecorations.shadowSm,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.ink,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.p16),
                    const Text('Review Selesai!', style: AppTextStyles.h1),
                    const SizedBox(height: AppSpacing.p8),
                    Text(
                      'Kamu telah menyelesaikan $count kartu pada sesi belajar ini. Jadwal review selanjutnya telah diperbarui menggunakan Spaced Repetition.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.p24),

              // Summary Metric Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.p16),
                decoration: AppDecorations.brutalBox(
                  backgroundColor: AppColors.surface,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'KARTU DIREVIEW',
                          style: AppTextStyles.label,
                        ),
                        const SizedBox(height: AppSpacing.p4),
                        Text('$count', style: AppTextStyles.h1),
                      ],
                    ),
                    Container(width: 2, height: 40, color: AppColors.ink),
                    Column(
                      children: [
                        const Text(
                          'SISA JATUH TEMPO',
                          style: AppTextStyles.label,
                        ),
                        const SizedBox(height: AppSpacing.p4),
                        Text('$remainingDue Kartu', style: AppTextStyles.h1),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Actions
              if (remainingDue > 0) ...[
                AppButton(
                  label: 'Lanjut Sesi Berikutnya (Maks. 20)',
                  variant: AppButtonVariant.primary,
                  icon: const Icon(Icons.bolt, color: AppColors.ink),
                  onPressed: () => context.go('/app/study/session/$deckId'),
                ),
                const SizedBox(height: AppSpacing.p12),
              ],
              AppButton(
                label: 'Kembali ke Beranda',
                variant: AppButtonVariant.secondary,
                onPressed: () => context.go('/app/home'),
              ),
              const SizedBox(height: AppSpacing.p12),
              AppButton(
                label: 'Lihat Progress Belajar',
                variant: AppButtonVariant.secondary,
                onPressed: () => context.go('/app/stats'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
