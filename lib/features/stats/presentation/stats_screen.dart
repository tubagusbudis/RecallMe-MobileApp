import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../application/stats_controller.dart';
import '../../flashcards/application/flashcard_controller.dart';
import '../../decks/application/deck_controller.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsControllerProvider);
    final stats =
        statsAsync.value ??
        const StatsState(
          totalReviews: 0,
          ratingDistribution: {1: 0, 3: 0, 4: 0, 5: 0},
          recentLogs: [],
        );

    final totalCards =
        ref.watch(flashcardControllerProvider).value?.length ?? 0;
    final totalDecks = ref.watch(deckControllerProvider).value?.length ?? 0;
    final totalDue = ref
        .watch(flashcardControllerProvider.notifier)
        .getTotalDueCount();

    final againCount = stats.ratingDistribution[1] ?? 0;
    final hardCount = stats.ratingDistribution[3] ?? 0;
    final goodCount = stats.ratingDistribution[4] ?? 0;
    final easyCount = stats.ratingDistribution[5] ?? 0;
    final totalRatings = againCount + hardCount + goodCount + easyCount;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Progress Belajar', style: AppTextStyles.h2),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(statsControllerProvider.notifier).refresh();
          await ref.read(flashcardControllerProvider.notifier).refresh();
          await ref.read(deckControllerProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
            vertical: AppSpacing.pageVertical,
          ),
          children: [
            // Overview Numbers
            Row(
              children: [
                Expanded(
                  child: AppCard(
                    backgroundColor: AppColors.primary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TOTAL REVIEW', style: AppTextStyles.label),
                        const SizedBox(height: AppSpacing.p8),
                        Text(
                          '${stats.totalReviews}',
                          style: AppTextStyles.display,
                        ),
                        const SizedBox(height: AppSpacing.p4),
                        const Text(
                          'Sesi aktif recall',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.p12),
                Expanded(
                  child: AppCard(
                    backgroundColor: AppColors.teal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TOTAL KARTU', style: AppTextStyles.label),
                        const SizedBox(height: AppSpacing.p8),
                        Text('$totalCards', style: AppTextStyles.display),
                        const SizedBox(height: AppSpacing.p4),
                        Text(
                          'Dalam $totalDecks deck',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.p12),

            // Due Cards Card
            AppCard(
              backgroundColor: totalDue > 0
                  ? AppColors.orange
                  : AppColors.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'KARTU JATUH TEMPO',
                        style: AppTextStyles.label,
                      ),
                      const SizedBox(height: AppSpacing.p4),
                      Text(
                        '$totalDue Kartu Siap Review',
                        style: AppTextStyles.h2,
                      ),
                    ],
                  ),
                  const Icon(Icons.alarm, size: 32, color: AppColors.ink),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.p20),

            // Rating Distribution Card (no fake mastery percentages)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Distribusi Penilaian Jawaban',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: AppSpacing.p4),
                  const Text(
                    'Frekuensi penilaian untuk menghitung interval review otomatis:',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.p16),

                  _RatingRow(
                    label: 'Again (Gagal)',
                    count: againCount,
                    total: totalRatings,
                    color: AppColors.ratingAgain,
                  ),
                  const SizedBox(height: AppSpacing.p8),
                  _RatingRow(
                    label: 'Hard (Sulit)',
                    count: hardCount,
                    total: totalRatings,
                    color: AppColors.ratingHard,
                  ),
                  const SizedBox(height: AppSpacing.p8),
                  _RatingRow(
                    label: 'Good (Baik)',
                    count: goodCount,
                    total: totalRatings,
                    color: AppColors.ratingGood,
                  ),
                  const SizedBox(height: AppSpacing.p8),
                  _RatingRow(
                    label: 'Easy (Mudah)',
                    count: easyCount,
                    total: totalRatings,
                    color: AppColors.ratingEasy,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.p20),

            // Recent Review History
            const Text('Aktivitas Review Terbaru', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.p12),

            if (stats.recentLogs.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.p20),
                decoration: AppDecorations.brutalBox(
                  backgroundColor: AppColors.surface,
                ),
                child: const Center(
                  child: Text(
                    'Belum ada aktivitas review. Mulai sesi belajar untuk melihat riwayat.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ),
            ] else ...[
              for (final log in stats.recentLogs) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.p8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.p16,
                      vertical: AppSpacing.p12,
                    ),
                    decoration: AppDecorations.brutalBox(
                      backgroundColor: AppColors.surface,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _ratingColor(log.rating),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.p12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.deckTitle,
                                style: AppTextStyles.bodyMediumBold,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Rating: ${_ratingLabel(log.rating)}',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatTime(log.reviewedAt),
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Again (1)';
      case 3:
        return 'Hard (3)';
      case 4:
        return 'Good (4)';
      case 5:
        return 'Easy (5)';
      default:
        return '$rating';
    }
  }

  Color _ratingColor(int rating) {
    switch (rating) {
      case 1:
        return AppColors.ratingAgain;
      case 3:
        return AppColors.ratingHard;
      case 4:
        return AppColors.ratingGood;
      case 5:
        return AppColors.ratingEasy;
      default:
        return AppColors.ink;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}j lalu';
    } else {
      return '${diff.inDays}h lalu';
    }
  }
}

class _RatingRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _RatingRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double ratio = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: AppTextStyles.bodyMediumBold),
        ),
        Expanded(
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.disabledSurface,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: AppColors.ink, width: AppBorders.thin),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadii.sm - 2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.p12),
        SizedBox(
          width: 32,
          child: Text(
            '$count',
            textAlign: TextAlign.end,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}
