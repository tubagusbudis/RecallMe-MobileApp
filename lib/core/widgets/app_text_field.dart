import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Neo-Brutalist text field with bold borders and clear labels
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final TextInputType keyboardType;
  final int maxLines;
  final int minLines;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.minLines = 1,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: hasError ? AppColors.coral : AppColors.ink,
          ),
        ),
        const SizedBox(height: AppSpacing.p8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? AppColors.surface : AppColors.disabledSurface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hasError ? AppColors.coral : AppColors.ink,
              width: AppBorders.standard,
            ),
            boxShadow: AppDecorations.shadowSm,
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLines: obscureText ? 1 : maxLines,
            minLines: obscureText ? 1 : minLines,
            enabled: enabled,
            onChanged: onChanged,
            style: AppTextStyles.bodyLarge,
            cursorColor: AppColors.ink,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.mutedText,
              ),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.p16,
                vertical: AppSpacing.p12,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.p4),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 14, color: AppColors.coral),
              const SizedBox(width: AppSpacing.p4),
              Expanded(
                child: Text(
                  errorText!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.coral,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ] else if (helperText != null && helperText!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.p4),
          Text(helperText!, style: AppTextStyles.bodySmall),
        ],
      ],
    );
  }
}
