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
import '../../auth/application/auth_controller.dart';
import '../../decks/application/deck_controller.dart';
import '../../flashcards/application/flashcard_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final decksAsync = ref.watch(deckControllerProvider);
    final flashcardsAsync = ref.watch(flashcardControllerProvider);
    final flashcardNotifier = ref.watch(flashcardControllerProvider.notifier);

    final decks = decksAsync.value ?? [];
    final totalCards = flashcardsAsync.value?.length ?? 0;
    final totalDue = flashcardNotifier.getTotalDueCount();

    // Find decks with due cards
    final decksWithDue = decks.where((d) {
      return flashcardNotifier.getDueCountForDeck(d.id) > 0;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('RecallMe', style: AppTextStyles.h2),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.pageHorizontal),
            child: GestureDetector(
              onTap: () => context.go('/app/profile'),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.p8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppBorders.thin,
                  ),
                  boxShadow: AppDecorations.shadowSm,
                ),
                child: const Icon(Icons.person, size: 20, color: AppColors.ink),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(deckControllerProvider.notifier).refresh();
          await ref.read(flashcardControllerProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
            vertical: AppSpacing.pageVertical,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Greeting Hero
              Text(
                'Halo, ${user?.displayName ?? "Pelajar"}! 👋',
                style: AppTextStyles.h1,
              ),
              const SizedBox(height: AppSpacing.p4),
              const Text(
                'Siap melatih ingatanmu hari ini?',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.p20),

              // Due Cards Hero Card
              AppCard(
                backgroundColor: totalDue > 0
                    ? AppColors.primary
                    : AppColors.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppBadge(
                          label: 'HARI INI',
                          backgroundColor: totalDue > 0
                              ? AppColors.surface
                              : AppColors.lime,
                          icon: Icons.calendar_today,
                        ),
                        const SizedBox(width: AppSpacing.p8),
                        const Flexible(
                          child: Text(
                            'Target Spaced Repetition',
                            style: AppTextStyles.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.p16),
                    Text('$totalDue Kartu', style: AppTextStyles.display),
                    const SizedBox(height: AppSpacing.p4),
                    Text(
                      totalDue > 0
                          ? 'Jatuh tempo dan siap di-review untuk memperkuat ingatan jangka panjang.'
                          : 'Hebat! Semua kartu jatuh tempo sudah kamu selesaikan hari ini.',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.p20),
                    if (totalDue > 0)
                      AppButton(
                        label: 'Mulai Review Sekarang',
                        icon: const Icon(Icons.bolt, color: AppColors.ink),
                        onPressed: () {
                          final targetDeckId = decksWithDue.isNotEmpty
                              ? decksWithDue.first.id
                              : (decks.isNotEmpty ? decks.first.id : '');
                          if (targetDeckId.isNotEmpty) {
                            context.push('/app/study/session/$targetDeckId');
                          }
                        },
                        variant: AppButtonVariant.secondary,
                      )
                    else
                      AppButton(
                        label: 'Lihat Semua Deck',
                        icon: const Icon(Icons.layers, color: AppColors.ink),
                        onPressed: () => context.go('/app/decks'),
                        variant: AppButtonVariant.primary,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.p20),

              // Quick Stats Row
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      backgroundColor: AppColors.lime,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TOTAL DECK', style: AppTextStyles.label),
                          const SizedBox(height: AppSpacing.p8),
                          Text('${decks.length} Deck', style: AppTextStyles.h2),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.p12),
                  Expanded(
                    child: AppCard(
                      backgroundColor: AppColors.sky,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TOTAL KARTU', style: AppTextStyles.label),
                          const SizedBox(height: AppSpacing.p8),
                          Text('$totalCards Kartu', style: AppTextStyles.h2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.p24),

              // Decks Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Siap Direview',
                      style: AppTextStyles.h2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.p8),
                  GestureDetector(
                    onTap: () => context.go('/app/decks'),
                    child: Text(
                      'Lihat Semua (${decks.length})',
                      style: AppTextStyles.bodyMediumBold.copyWith(
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.p16),

              decksAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.p24),
                    child: CircularProgressIndicator(color: AppColors.ink),
                  ),
                ),
                error: (err, _) => Container(
                  padding: const EdgeInsets.all(AppSpacing.p16),
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
                data: (deckList) {
                  if (deckList.isEmpty) {
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
                              size: 48,
                              color: AppColors.mutedText,
                            ),
                            const SizedBox(height: AppSpacing.p12),
                            const Text(
                              'Belum ada deck',
                              style: AppTextStyles.h3,
                            ),
                            const SizedBox(height: AppSpacing.p4),
                            const Text(
                              'Buat deck pertamamu untuk mulai belajar flashcard.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.p16),
                            AppButton(
                              label: 'Buat Deck Baru',
                              onPressed: () => context.go('/app/decks/new'),
                              variant: AppButtonVariant.primary,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      for (final deck in deckList) ...[
                        Builder(
                          builder: (context) {
                            final dueCount = flashcardNotifier
                                .getDueCountForDeck(deck.id);
                            final cardCount = flashcardNotifier
                                .getCardsForDeck(deck.id)
                                .length;

                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.p12,
                              ),
                              child: AppCard(
                                onTap: () =>
                                    context.go('/app/decks/${deck.id}'),
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
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(
                                                height: AppSpacing.p4,
                                              ),
                                              Text(
                                                '$cardCount kartu total',
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
                                    const SizedBox(height: AppSpacing.p16),
                                    AppButton(
                                      label: dueCount > 0
                                          ? 'Belajar Deck Ini ($dueCount Kartu)'
                                          : 'Review Latihan Deck Ini',
                                      height: 40,
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
      ),
    );
  }
}
