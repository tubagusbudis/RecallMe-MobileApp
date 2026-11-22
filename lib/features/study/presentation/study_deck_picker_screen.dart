import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../decks/application/deck_controller.dart';
import '../../flashcards/application/flashcard_controller.dart';

class StudyDeckPickerScreen extends ConsumerWidget {
  const StudyDeckPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(deckControllerProvider);
    final flashcardNotifier = ref.watch(flashcardControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Mulai Belajar', style: AppTextStyles.h2),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(deckControllerProvider.notifier).refresh();
          await ref.read(flashcardControllerProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
            vertical: AppSpacing.pageVertical,
          ),
          children: [
            // Banner explaining 1 deck per session rule
            Container(
              padding: const EdgeInsets.all(AppSpacing.p16),
              decoration: AppDecorations.brutalBox(
                backgroundColor: AppColors.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Sesi Belajar Fokus (1 Deck)', style: AppTextStyles.h3),
                  SizedBox(height: AppSpacing.p4),
                  Text(
                    'Setiap sesi fokus pada 1 deck dengan batas maksimal 20 kartu per sesi untuk retensi ingatan yang efektif.',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.p24),

            const Text('Pilih Deck untuk Direview:', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.p16),

            decksAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.p32),
                  child: CircularProgressIndicator(color: AppColors.ink),
                ),
              ),
              error: (err, _) => Container(
                padding: const EdgeInsets.all(AppSpacing.p20),
                decoration: AppDecorations.brutalBox(
                  backgroundColor: AppColors.coral.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(
                    ref.read(deckControllerProvider.notifier).mapError(err),
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ),
              data: (decks) {
                if (decks.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.p24),
                    decoration: AppDecorations.brutalBox(
                      backgroundColor: AppColors.surface,
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.folder_open,
                            size: 40,
                            color: AppColors.mutedText,
                          ),
                          const SizedBox(height: AppSpacing.p12),
                          const Text('Belum ada deck', style: AppTextStyles.h3),
                          const SizedBox(height: AppSpacing.p16),
                          AppButton(
                            label: 'Buat Deck Baru',
                            onPressed: () => context.go('/app/decks/new'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    for (final deck in decks) ...[
                      Builder(
                        builder: (context) {
                          final dueCount = flashcardNotifier.getDueCountForDeck(
                            deck.id,
                          );
                          final totalCount = flashcardNotifier
                              .getCardsForDeck(deck.id)
                              .length;

                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.p16,
                            ),
                            child: AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: deck.color,
                                          borderRadius: BorderRadius.circular(
                                            AppRadii.sm,
                                          ),
                                          border: Border.all(
                                            color: AppColors.ink,
                                            width: AppBorders.standard,
                                          ),
                                          boxShadow: AppDecorations.shadowSm,
                                        ),
                                        child: const Icon(
                                          Icons.bolt,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.p12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              deck.title,
                                              style: AppTextStyles.h3,
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.p4,
                                            ),
                                            Text(
                                              '$totalCount kartu total',
                                              style: AppTextStyles.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (dueCount > 0)
                                        AppBadge(
                                          label: '$dueCount siap review',
                                          backgroundColor: AppColors.coral,
                                          textColor: AppColors.ink,
                                        )
                                      else
                                        const AppBadge(
                                          label: 'Semua selesai',
                                          backgroundColor: AppColors.lime,
                                          textColor: AppColors.ink,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.p16),
                                  AppButton(
                                    label: dueCount > 0
                                        ? 'Mulai Sesi Belajar (Maks. 20 Kartu)'
                                        : 'Latihan Bebas Deck Ini',
                                    variant: dueCount > 0
                                        ? AppButtonVariant.primary
                                        : AppButtonVariant.secondary,
                                    onPressed: () => context.push(
                                      '/app/study/session/${deck.id}',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
