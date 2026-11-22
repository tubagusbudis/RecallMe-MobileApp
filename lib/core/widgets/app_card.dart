import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_spacing.dart';

/// Neo-Brutalist card container with bold border and hard shadow
class AppCard extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final List<BoxShadow> shadows;

  const AppCard({
    super.key,
    required this.child,
    this.backgroundColor = AppColors.surface,
    this.borderColor = AppColors.ink,
    this.borderWidth = AppBorders.standard,
    this.borderRadius = AppRadii.md,
    this.padding = const EdgeInsets.all(AppSpacing.p16),
    this.onTap,
    this.shadows = AppDecorations.shadowMd,
  });

  @override
  Widget build(BuildContext context) {
    final Widget card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap == null) {
      return card;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: card,
    );
  }
}
