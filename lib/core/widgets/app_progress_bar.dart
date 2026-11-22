import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Neo-Brutalist progress bar with numeric label (e.g., "3 / 20")
class AppProgressBar extends StatelessWidget {
  final int current;
  final int total;
  final Color fillColor;
  final String? prefixLabel;

  const AppProgressBar({
    super.key,
    required this.current,
    required this.total,
    this.fillColor = AppColors.primary,
    this.prefixLabel,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (prefixLabel != null)
              Text(prefixLabel!, style: AppTextStyles.label),
            Text('$current / $total', style: AppTextStyles.bodyMediumBold),
          ],
        ),
        const SizedBox(height: AppSpacing.p8),
        Container(
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.disabledSurface,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(
              color: AppColors.ink,
              width: AppBorders.standard,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    width: constraints.maxWidth * progress,
                    decoration: BoxDecoration(
                      color: fillColor,
                      borderRadius: BorderRadius.circular(AppRadii.sm - 2),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
