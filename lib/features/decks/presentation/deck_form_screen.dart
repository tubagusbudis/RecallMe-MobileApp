import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../application/deck_controller.dart';

class DeckFormScreen extends ConsumerStatefulWidget {
  final String? deckId;

  const DeckFormScreen({super.key, this.deckId});

  @override
  ConsumerState<DeckFormScreen> createState() => _DeckFormScreenState();
}

class _DeckFormScreenState extends ConsumerState<DeckFormScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _titleError;
  String? _serverError;
  bool _isSaving = false;

  bool get isEdit => widget.deckId != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final deck = ref
          .read(deckControllerProvider.notifier)
          .getDeckById(widget.deckId!);
      if (deck != null) {
        _titleController.text = deck.title;
        _descriptionController.text = deck.description;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      if (widget.deckId != null) {
        context.go('/app/decks/${widget.deckId}');
      } else {
        context.go('/app/decks');
      }
    }
  }

  Future<void> _saveDeck() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Judul deck tidak boleh kosong');
      return;
    }

    setState(() {
      _isSaving = true;
      _serverError = null;
    });

    try {
      if (isEdit) {
        await ref
            .read(deckControllerProvider.notifier)
            .updateDeck(
              deckId: widget.deckId!,
              title: title,
              description: _descriptionController.text.trim(),
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Deck berhasil diperbarui'),
              backgroundColor: AppColors.ink,
            ),
          );
        }
      } else {
        await ref
            .read(deckControllerProvider.notifier)
            .addDeck(
              title: title,
              description: _descriptionController.text.trim(),
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Deck baru berhasil dibuat'),
              backgroundColor: AppColors.ink,
            ),
          );
        }
      }

      if (mounted) {
        _handleBack();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _serverError = ref.read(deckControllerProvider.notifier).mapError(e);
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
          isEdit ? 'Edit Deck' : 'Buat Deck Baru',
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
              AppTextField(
                label: 'JUDUL DECK *',
                hint: 'misal: Kosakata Biologi Bab 3',
                controller: _titleController,
                errorText: _titleError,
                onChanged: (_) {
                  if (_titleError != null) {
                    setState(() => _titleError = null);
                  }
                  if (_serverError != null) {
                    setState(() => _serverError = null);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.p20),
              AppTextField(
                label: 'DESKRIPSI (OPSIONAL)',
                hint: 'Catatan ringkas tentang topik dalam deck ini',
                controller: _descriptionController,
                maxLines: 4,
                minLines: 3,
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
                      label: isEdit ? 'Simpan Perubahan' : 'Buat Deck',
                      variant: AppButtonVariant.primary,
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _saveDeck,
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
