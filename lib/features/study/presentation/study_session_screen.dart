import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../application/study_controller.dart';
import '../data/review_repository.dart';
import '../domain/study_session_model.dart';

class StudySessionScreen extends ConsumerStatefulWidget {
  final String deckId;

  const StudySessionScreen({super.key, required this.deckId});

  @override
  ConsumerState<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends ConsumerState<StudySessionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studyControllerProvider.notifier).startSession(widget.deckId);
    });
  }

  void _handleClose() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/app/home');
    }
  }

  void _onRatingPressed(int rating) async {
    try {
      final hasNext = await ref
          .read(studyControllerProvider.notifier)
          .submitRating(rating);

      if (!hasNext && mounted) {
        final session = ref.read(studyControllerProvider);
        if (session?.state == StudySessionState.completed) {
          final count = session?.totalReviewedInSession ?? 1;
          context.go('/app/study/summary/${widget.deckId}?count=$count');
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = ref.read(reviewRepositoryProvider).mapError(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: AppColors.coral),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(studyControllerProvider);

    if (session == null || session.state == StudySessionState.loading) {
      return const Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(child: CircularProgressIndicator(color: AppColors.ink)),
      );
    }

    if (session.state == StudySessionState.empty || session.queue.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          title: Text(session.deckTitle, style: AppTextStyles.h3),
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.ink),
            tooltip: 'Keluar Sesi',
            onPressed: _handleClose,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: AppColors.teal,
                ),
                const SizedBox(height: AppSpacing.p16),
                const Text(
                  'Belum ada kartu di deck ini',
                  style: AppTextStyles.h2,
                ),
                const SizedBox(height: AppSpacing.p8),
                const Text(
                  'Tambahkan flashcard ke dalam deck ini terlebih dahulu untuk memulai sesi belajar.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.p24),
                AppButton(
                  label: '+ Tambah Flashcard Baru',
                  onPressed: () =>
                      context.go('/app/decks/${widget.deckId}/cards/new'),
                ),
                const SizedBox(height: AppSpacing.p12),
                AppButton(
                  label: 'Kembali',
                  variant: AppButtonVariant.secondary,
                  onPressed: _handleClose,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentCard = session.currentCard!;
    final isAnswerRevealed =
        session.state == StudySessionState.answer ||
        session.state == StudySessionState.saving;
    final isSaving = session.state == StudySessionState.saving;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          session.deckTitle,
          style: AppTextStyles.h3,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.ink),
          tooltip: 'Keluar Sesi',
          onPressed: _handleClose,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
            vertical: AppSpacing.p12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Session Progress Bar (e.g. 3 / 20)
              AppProgressBar(
                current: session.currentProgressNumber,
                total: session.totalCards,
                prefixLabel: 'KARTU SESI INI',
                fillColor: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.p16),

              // Main Flashcard Study Container (Responsive height)
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 180),
                    decoration: AppDecorations.brutalBox(
                      backgroundColor: AppColors.surface,
                      borderWidth: AppBorders.bold,
                      shadows: AppDecorations.shadowLg,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card Header & Question (+ Answer if revealed)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.p20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Badge PERTANYAAN (Neo-Brutalist purple)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.p8,
                                      vertical: AppSpacing.p4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.purple,
                                      borderRadius: BorderRadius.circular(
                                        AppRadii.sm,
                                      ),
                                      border: Border.all(
                                        color: AppColors.ink,
                                        width: AppBorders.standard,
                                      ),
                                      boxShadow: AppDecorations.shadowSm,
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.help_outline,
                                          size: 14,
                                          color: AppColors.ink,
                                        ),
                                        SizedBox(width: AppSpacing.p4),
                                        Text(
                                          'PERTANYAAN',
                                          style: AppTextStyles.label,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.p12),
                              const Divider(
                                color: AppColors.lightBorder,
                                thickness: AppBorders.thin,
                                height: 1,
                              ),
                              const SizedBox(height: AppSpacing.p20),

                              // Question Text (centered, bold, legible)
                              Text(
                                currentCard.question,
                                style: AppTextStyles.h2,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.p16),

                              // Yellow short accent line below question
                              Container(
                                width: 48,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),

                              // Answer Section (Answer State)
                              if (isAnswerRevealed) ...[
                                const SizedBox(height: AppSpacing.p24),
                                const Divider(
                                  color: AppColors.lightBorder,
                                  thickness: AppBorders.thin,
                                  height: 1,
                                ),
                                const SizedBox(height: AppSpacing.p20),

                                // Badge JAWABAN (Neo-Brutalist teal)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.p8,
                                        vertical: AppSpacing.p4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.teal,
                                        borderRadius: BorderRadius.circular(
                                          AppRadii.sm,
                                        ),
                                        border: Border.all(
                                          color: AppColors.ink,
                                          width: AppBorders.standard,
                                        ),
                                        boxShadow: AppDecorations.shadowSm,
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline,
                                            size: 14,
                                            color: AppColors.ink,
                                          ),
                                          SizedBox(width: AppSpacing.p4),
                                          Text(
                                            'JAWABAN',
                                            style: AppTextStyles.label,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.p12),
                                const Divider(
                                  color: AppColors.lightBorder,
                                  thickness: AppBorders.thin,
                                  height: 1,
                                ),
                                const SizedBox(height: AppSpacing.p20),

                                // Answer Text
                                Text(
                                  currentCard.answer,
                                  style: AppTextStyles.bodyLargeBold.copyWith(
                                    fontSize: 18,
                                    height: 1.45,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Question State Footer Hint (hidden when answer revealed)
                        if (!isAnswerRevealed) ...[
                          Container(
                            decoration: const BoxDecoration(
                              color: AppColors.canvas,
                              border: Border(
                                top: BorderSide(
                                  color: AppColors.lightBorder,
                                  width: AppBorders.thin,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.p16,
                              vertical: AppSpacing.p12,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline,
                                  size: 20,
                                  color: AppColors.ink,
                                ),
                                const SizedBox(width: AppSpacing.p8),
                                Expanded(
                                  child: Text(
                                    'Pikirkan jawabanmu di memori atau ucapkan dalam hati sebelum membuka kunci jawaban.',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.mutedText,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.p16),

              // Focus Indicator (above action controls)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.verified_outlined,
                    size: 14,
                    color: AppColors.mutedText,
                  ),
                  const SizedBox(width: AppSpacing.p4),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Fokus maksimal: Tanpa gangguan',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.p12),

              // Bottom Action Controls
              if (!isAnswerRevealed) ...[
                AppButton(
                  label: 'Lihat Jawaban',
                  icon: const Icon(Icons.visibility, color: AppColors.ink),
                  variant: AppButtonVariant.primary,
                  height: 52,
                  onPressed: () =>
                      ref.read(studyControllerProvider.notifier).revealAnswer(),
                ),
              ] else ...[
                // Rating Prompt
                const Center(
                  child: Text(
                    'Seberapa mudah kamu mengingatnya?',
                    style: AppTextStyles.bodyMediumBold,
                  ),
                ),
                const SizedBox(height: AppSpacing.p12),

                // 2x2 Grid Rating Buttons for accessibility on 360-390dp phones
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Again (1)',
                        variant: AppButtonVariant.ratingAgain,
                        isLoading: isSaving,
                        onPressed: isSaving ? null : () => _onRatingPressed(1),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.p12),
                    Expanded(
                      child: AppButton(
                        label: 'Hard (3)',
                        variant: AppButtonVariant.ratingHard,
                        isLoading: isSaving,
                        onPressed: isSaving ? null : () => _onRatingPressed(3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.p12),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Good (4)',
                        variant: AppButtonVariant.ratingGood,
                        isLoading: isSaving,
                        onPressed: isSaving ? null : () => _onRatingPressed(4),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.p12),
                    Expanded(
                      child: AppButton(
                        label: 'Easy (5)',
                        variant: AppButtonVariant.ratingEasy,
                        isLoading: isSaving,
                        onPressed: isSaving ? null : () => _onRatingPressed(5),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
