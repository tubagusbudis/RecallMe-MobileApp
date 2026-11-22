import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialog.dart';
import '../application/deck_controller.dart';
import '../domain/deck_model.dart';
import '../../flashcards/application/flashcard_controller.dart';

class DeckDetailScreen extends ConsumerStatefulWidget {
  final String deckId;

  const DeckDetailScreen({super.key, required this.deckId});

  @override
  ConsumerState<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends ConsumerState<DeckDetailScreen> {
  bool _isDeleting = false;

  void _confirmDeleteDeck(String title) async {
    final confirmed = await AppDialog.show(
      context,
      title: 'Hapus Deck "$title"?',
      message: 'Menghapus deck ini akan menghapus SELURUH flashcard dan histori review di dalamnya secara permanen (ON DELETE CASCADE). Tindakan ini tidak dapat dibatalkan.',
      confirmLabel: 'Hapus Permanen',
      cancelLabel: 'Batal',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);
      try {
        await ref
            .read(deckControllerProvider.notifier)
            .deleteDeck(widget.deckId);
        ref
            .read(flashcardControllerProvider.notifier)
            .deleteCardsByDeckId(widget.deckId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deck "$title" berhasil dihapus'),
              backgroundColor: AppColors.ink,
            ),
          );
          context.go('/app/decks');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus deck: $e'),
              backgroundColor: AppColors.coral,
            ),
          );
        }
      }
    }
  }

  void _confirmDeleteCard(String cardId) async {
    final confirmed = await AppDialog.show(
      context,
      title: 'Hapus Flashcard?',
      message: 'Flashcard ini beserta riwayat review-nya akan dihapus permanen. Lanjutkan?',
      confirmLabel: 'Hapus Kartu',
      cancelLabel: 'Batal',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(flashcardControllerProvider.notifier).deleteCard(cardId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Flashcard berhasil dihapus'),
              backgroundColor: AppColors.ink,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus kartu: $e'),
              backgroundColor: AppColors.coral,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final decksAsync = ref.watch(deckControllerProvider);
    final flashcardsAsync = ref.watch(flashcardControllerProvider);
    final flashcardNotifier = ref.watch(flashcardControllerProvider.notifier);

    final DeckModel? deck = decksAsync.value?.firstWhere(
      (d) => d.id == widget.deckId,
      orElse: () => DeckModel(
        id: '',
        userId: '',
        title: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final isDeckFound = deck != null && deck.id.isNotEmpty;

    if (decksAsync.isLoading && !isDeckFound) {
      return const Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(child: CircularProgressIndicator(color: AppColors.ink)),
      );
    }

    if (!isDeckFound) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(title: const Text('Detail Deck')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Deck tidak ditemukan', style: AppTextStyles.h3),
              const SizedBox(height: AppSpacing.p16),
              AppButton(
                label: 'Kembali ke Daftar Deck',
                fullWidth: false,
                onPressed: () => context.go('/app/decks'),
              ),
            ],
          ),
        ),
      );
    }

    final flashcards = flashcardNotifier.getCardsForDeck(widget.deckId);
    final dueCount = flashcardNotifier.getDueCountForDeck(widget.deckId);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(deck.title, style: AppTextStyles.h2),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.ink),
            tooltip: 'Edit Deck',
            onPressed: () => context.push('/app/decks/${widget.deckId}/edit'),
          ),
          IconButton(
            icon: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.coral,
                    ),
                  )
                : const Icon(Icons.delete_outline, color: AppColors.coral),
            tooltip: 'Hapus Deck',
            onPressed: _isDeleting
                ? null
                : () => _confirmDeleteDeck(deck.title),
          ),
        ],
      ),
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
            // Deck Info Card
            AppCard(
              backgroundColor: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.p8,
                    runSpacing: AppSpacing.p8,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      AppBadge(
                        label: 'DECK AKTIF',
                        backgroundColor: deck.color,
                        textColor: Colors.white,
                      ),
                      if (dueCount > 0)
                        AppBadge(
                          label: '$dueCount Jatuh Tempo',
                          backgroundColor: AppColors.coral,
                          textColor: AppColors.ink,
                        )
                      else
                        const AppBadge(
                          label: 'Semua Selesai',
                          backgroundColor: AppColors.lime,
                          textColor: AppColors.ink,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.p12),
                  Text(deck.title, style: AppTextStyles.h1),
                  if (deck.description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.p8),
                    Text(deck.description, style: AppTextStyles.bodyMedium),
                  ],
                  const SizedBox(height: AppSpacing.p20),
                  AppButton(
                    label: dueCount > 0
                        ? 'Mulai Sesi Belajar ($dueCount Kartu)'
                        : 'Mulai Latihan Bebas',
                    icon: const Icon(Icons.bolt, color: AppColors.ink),
                    variant: AppButtonVariant.primary,
                    onPressed: () =>
                        context.push('/app/study/session/${widget.deckId}'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.p24),

            // Cards Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Daftar Flashcard (${flashcards.length})',
                    style: AppTextStyles.h3,
                  ),
                ),
                const SizedBox(width: AppSpacing.p8),
                AppButton(
                  label: '+ Tambah Kartu',
                  variant: AppButtonVariant.secondary,
                  height: 38,
                  fullWidth: false,
                  onPressed: () =>
                      context.push('/app/decks/${widget.deckId}/cards/new'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.p16),

            // Flashcards List
            if (flashcardsAsync.isLoading && flashcards.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.p32),
                  child: CircularProgressIndicator(color: AppColors.ink),
                ),
              ),
            ] else if (flashcards.isEmpty) ...[
              AppCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.p20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.note_alt_outlined,
                          size: 40,
                          color: AppColors.mutedText,
                        ),
                        const SizedBox(height: AppSpacing.p8),
                        const Text(
                          'Belum ada flashcard di deck ini',
                          style: AppTextStyles.bodyLargeBold,
                        ),
                        const SizedBox(height: AppSpacing.p4),
                        const Text(
                          'Tambahkan kartu pertanyaan & jawaban pertamamu.',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.p16),
                        AppButton(
                          label: 'Tambah Flashcard Sekarang',
                          fullWidth: false,
                          onPressed: () => context.push(
                            '/app/decks/${widget.deckId}/cards/new',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              for (final card in flashcards) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.ink,
                                width: AppBorders.thin,
                              ),
                            ),
                            child: const Text('Q', style: AppTextStyles.label),
                          ),
                          const SizedBox(width: AppSpacing.p8),
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: card.isDue
                                      ? const AppBadge(
                                          label: 'Jatuh Tempo',
                                          backgroundColor: AppColors.coral,
                                          textColor: AppColors.ink,
                                        )
                                      : AppBadge(
                                          label:
                                              'Interval ${card.intervalDays}h',
                                          backgroundColor:
                                              AppColors.disabledSurface,
                                          textColor: AppColors.ink,
                                        ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  onPressed: () => context.push(
                                    '/app/cards/${card.id}/edit',
                                  ),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    size: 18,
                                    color: AppColors.coral,
                                  ),
                                  onPressed: () => _confirmDeleteCard(card.id),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.p8),
                      Text(card.question, style: AppTextStyles.bodyLargeBold),
                      const SizedBox(height: AppSpacing.p8),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpacing.p8),
                      Text(card.answer, style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.p12),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
