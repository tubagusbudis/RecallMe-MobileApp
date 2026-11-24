import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../flashcards/application/flashcard_controller.dart';

class FlashcardFormScreen extends ConsumerStatefulWidget {
  final String? deckId;
  final String? cardId;

  const FlashcardFormScreen({super.key, this.deckId, this.cardId});

  @override
  ConsumerState<FlashcardFormScreen> createState() =>
      _FlashcardFormScreenState();
}

class _FlashcardFormScreenState extends ConsumerState<FlashcardFormScreen> {
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  String? _questionError;
  String? _answerError;
  String? _serverError;
  String? _resolvedDeckId;
  bool _isSaving = false;

  bool get isEdit => widget.cardId != null;

  @override
  void initState() {
    super.initState();
    _resolvedDeckId = widget.deckId;
    if (isEdit) {
      final card = ref
          .read(flashcardControllerProvider.notifier)
          .getCardById(widget.cardId!);
      if (card != null) {
        _questionController.text = card.question;
        _answerController.text = card.answer;
        _resolvedDeckId ??= card.deckId;
      }
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      if (_resolvedDeckId != null) {
        context.go('/app/decks/$_resolvedDeckId');
      } else {
        context.go('/app/decks');
      }
    }
  }

  Future<void> _saveCard() async {
    bool valid = true;
    final question = _questionController.text.trim();
    final answer = _answerController.text.trim();

    if (question.isEmpty) {
      setState(() => _questionError = 'Pertanyaan tidak boleh kosong');
      valid = false;
    }
    if (answer.isEmpty) {
      setState(() => _answerError = 'Jawaban tidak boleh kosong');
      valid = false;
    }

    if (!valid) return;

    setState(() {
      _isSaving = true;
      _serverError = null;
    });

    try {
      if (isEdit) {
        await ref
            .read(flashcardControllerProvider.notifier)
            .updateCard(
              cardId: widget.cardId!,
              question: question,
              answer: answer,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Flashcard berhasil diperbarui'),
              backgroundColor: AppColors.ink,
            ),
          );
        }
      } else {
        if (_resolvedDeckId != null) {
          await ref
              .read(flashcardControllerProvider.notifier)
              .addCard(
                deckId: _resolvedDeckId!,
                question: question,
                answer: answer,
              );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Flashcard baru langsung siap dipelajari!'),
                backgroundColor: AppColors.ink,
              ),
            );
          }
        }
      }

      if (mounted) {
        _handleBack();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _serverError = ref
              .read(flashcardControllerProvider.notifier)
              .mapError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Flashcard' : 'Tambah Flashcard Baru',
          style: AppTextStyles.h2,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          tooltip: 'Kembali',
          onPressed: _isSaving ? null : _handleBack,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageHorizontal,
          vertical: AppSpacing.pageVertical,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.p20),
          decoration: AppDecorations.brutalBox(
            backgroundColor: AppColors.surface,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice text-only MVP
              Container(
                padding: const EdgeInsets.all(AppSpacing.p12),
                decoration: BoxDecoration(
                  color: AppColors.sky.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(
                    color: AppColors.ink,
                    width: AppBorders.thin,
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, size: 18, color: AppColors.ink),
                    SizedBox(width: AppSpacing.p8),
                    Expanded(
                      child: Text(
                        'Flashcard saat ini berbasis teks. Fitur tambah gambar akan tersedia di versi selanjutnya.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.p20),

              if (_serverError != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.p12),
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(
                      color: AppColors.coral,
                      width: AppBorders.standard,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.coral,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.p8),
                      Expanded(
                        child: Text(
                          _serverError!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.p16),
              ],

              // Question Field
              AppTextField(
                label: 'PERTANYAAN (FRONT) *',
                hint: 'Tulis pertanyaan yang memicu active recall...',
                controller: _questionController,
                errorText: _questionError,
                maxLines: 4,
                minLines: 3,
                onChanged: (_) {
                  if (_questionError != null) {
                    setState(() => _questionError = null);
                  }
                  if (_serverError != null) {
                    setState(() => _serverError = null);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.p20),

              // Answer Field
              AppTextField(
                label: 'JAWABAN (BACK) *',
                hint: 'Tulis jawaban lengkap dan jelas...',
                controller: _answerController,
                errorText: _answerError,
                maxLines: 5,
                minLines: 3,
                onChanged: (_) {
                  if (_answerError != null) {
                    setState(() => _answerError = null);
                  }
                  if (_serverError != null) {
                    setState(() => _serverError = null);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.p32),

              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Batal',
                      variant: AppButtonVariant.secondary,
                      onPressed: _isSaving ? null : _handleBack,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.p12),
                  Expanded(
                    child: AppButton(
                      label: isEdit ? 'Simpan Perubahan' : 'Tambah Kartu',
                      variant: AppButtonVariant.primary,
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _saveCard,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
