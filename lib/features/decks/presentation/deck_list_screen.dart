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
import '../application/deck_controller.dart';
import '../../flashcards/application/flashcard_controller.dart';

class DeckListScreen extends ConsumerWidget {
  const DeckListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(deckControllerProvider);
    final flashcardNotifier = ref.watch(flashcardControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Deck Saya', style: AppTextStyles.h2)),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(deckControllerProvider.notifier).refresh();
          await ref.read(flashcardControllerProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.pageVertical,
            AppSpacing.pageHorizontal,
            96.0,
          ),
          children: [
            // Create Deck CTA Button
            AppButton(
              label: 'Buat Deck Baru',
              icon: const Icon(Icons.add, color: AppColors.ink),
              variant: AppButtonVariant.primary,
              onPressed: () => context.push('/app/decks/new'),
            ),
            const SizedBox(height: AppSpacing.p20),

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
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.coral,
                      size: 40,
                    ),
                    const SizedBox(height: AppSpacing.p12),
                    Text(
                      ref.read(deckControllerProvider.notifier).mapError(err),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.p16),
                    AppButton(
                      label: 'Coba Lagi',
                      variant: AppButtonVariant.secondary,
                      onPressed: () =>
                          ref.read(deckControllerProvider.notifier).refresh(),
                    ),
                  ],
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
                        children: const [
                          Icon(
                            Icons.layers_clear,
                            size: 48,
                            color: AppColors.mutedText,
                          ),
                          SizedBox(height: AppSpacing.p12),
                          Text('Belum ada deck', style: AppTextStyles.h3),
                          SizedBox(height: AppSpacing.p4),
                          Text(
                            'Mulai dengan membuat deck untuk mengorganisir flashcard belajarmu.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium,
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
                          final cardCount = flashcardNotifier
                              .getCardsForDeck(deck.id)
                              .length;
                          final dueCount = flashcardNotifier.getDueCountForDeck(
                            deck.id,
                          );

                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.p16,
                            ),
                            child: AppCard(
                              onTap: () => context.go('/app/decks/${deck.id}'),
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
                                          Icons.layers,
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
                                              '$cardCount kartu',
                                              style: AppTextStyles.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (dueCount > 0)
                                        AppBadge(
                                          label: '$dueCount jatuh tempo',
                                          backgroundColor: AppColors.coral,
                                          textColor: AppColors.ink,
                                        )
                                      else
                                        const AppBadge(
                                          label: 'Selesai',
                                          backgroundColor: AppColors.lime,
                                          textColor: AppColors.ink,
                                        ),
                                    ],
                                  ),
                                  if (deck.description.isNotEmpty) ...[
                                    const SizedBox(height: AppSpacing.p12),
                                    Text(
                                      deck.description,
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                  ],
                                  const SizedBox(height: AppSpacing.p16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AppButton(
                                          label: 'Buka Deck',
                                          variant: AppButtonVariant.secondary,
                                          height: 40,
                                          onPressed: () => context.go(
                                            '/app/decks/${deck.id}',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.p12),
                                      Expanded(
                                        child: AppButton(
                                          label: 'Mulai Belajar',
                                          variant: AppButtonVariant.primary,
                                          height: 40,
                                          onPressed: () => context.push(
                                            '/app/study/session/${deck.id}',
                                          ),
                                        ),
                                      ),
                                    ],
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
