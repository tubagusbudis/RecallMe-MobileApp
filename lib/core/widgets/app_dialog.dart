import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

/// Neo-Brutalist Confirmation Dialog
/// Used especially for destructive cascade delete actions
class AppDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final bool isDestructive;

  const AppDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Hapus Permanen',
    this.cancelLabel = 'Batal',
    required this.onConfirm,
    this.isDestructive = true,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Hapus Permanen',
    String cancelLabel = 'Batal',
    bool isDestructive = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AppDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(ctx).pop(true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.p20),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.p24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.ink, width: AppBorders.bold),
          boxShadow: AppDecorations.shadowLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isDestructive)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.p8),
                    decoration: BoxDecoration(
                      color: AppColors.coral,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(
                        color: AppColors.ink,
                        width: AppBorders.standard,
                      ),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.ink,
                      size: 24,
                    ),
                  ),
                if (isDestructive) const SizedBox(width: AppSpacing.p12),
                Expanded(child: Text(title, style: AppTextStyles.h3)),
              ],
            ),
            const SizedBox(height: AppSpacing.p16),
            Text(message, style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.p24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: cancelLabel,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: AppSpacing.p12),
                Expanded(
                  child: AppButton(
                    label: confirmLabel,
                    variant: isDestructive
                        ? AppButtonVariant.destructive
                        : AppButtonVariant.primary,
                    onPressed: onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
