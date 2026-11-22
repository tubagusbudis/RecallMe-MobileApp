import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum AppButtonVariant {
  primary,
  secondary,
  destructive,
  ratingAgain,
  ratingHard,
  ratingGood,
  ratingEasy,
}

/// Neo-Brutalist Button with bold black border, hard offset shadow, and min 48dp height
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? icon;
  final bool isLoading;
  final bool fullWidth;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    this.height = AppSpacing.minTouchTarget,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  Color get _backgroundColor {
    if (widget.onPressed == null || widget.isLoading) {
      return AppColors.disabledSurface;
    }
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.primary;
      case AppButtonVariant.secondary:
        return AppColors.surface;
      case AppButtonVariant.destructive:
        return AppColors.coral;
      case AppButtonVariant.ratingAgain:
        return AppColors.ratingAgain;
      case AppButtonVariant.ratingHard:
        return AppColors.ratingHard;
      case AppButtonVariant.ratingGood:
        return AppColors.ratingGood;
      case AppButtonVariant.ratingEasy:
        return AppColors.ratingEasy;
    }
  }

  Color get _textColor {
    if (widget.onPressed == null || widget.isLoading) {
      return AppColors.disabledText;
    }
    return AppColors.ink;
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;

    final Widget buttonContent = AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p12),
      transform: _isPressed && isEnabled
          ? Matrix4.translationValues(2, 2, 0)
          : Matrix4.identity(),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: isEnabled ? AppColors.ink : AppColors.disabledText,
          width: AppBorders.standard,
        ),
        boxShadow: isEnabled
            ? (_isPressed ? AppDecorations.shadowSm : AppDecorations.shadowMd)
            : null,
      ),
      child: Center(
        child: widget.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
                ),
              )
            : Row(
                mainAxisSize: widget.fullWidth
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    widget.icon!,
                    const SizedBox(width: AppSpacing.p8),
                  ],
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.label,
                        style: AppTextStyles.button.copyWith(color: _textColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: isEnabled ? widget.onPressed : null,
      child: widget.fullWidth
          ? SizedBox(width: double.infinity, child: buttonContent)
          : buttonContent,
    );
  }
}
