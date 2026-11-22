import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.ink, width: AppBorders.standard),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Beranda',
                    isSelected: currentIndex == 0,
                    onTap: () => _onTap(0),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.layers_rounded,
                    label: 'Deck',
                    isSelected: currentIndex == 1,
                    onTap: () => _onTap(1),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.bolt_rounded,
                    label: 'Belajar',
                    isSelected: currentIndex == 2,
                    onTap: () => _onTap(2),
                    isCenterAction: true,
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.bar_chart_rounded,
                    label: 'Progress',
                    isSelected: currentIndex == 3,
                    onTap: () => _onTap(3),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.person_rounded,
                    label: 'Profil',
                    isSelected: currentIndex == 4,
                    onTap: () => _onTap(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCenterAction;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isCenterAction = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCenterAction) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: AppColors.ink, width: AppBorders.thin),
              boxShadow: isSelected
                  ? const [
                      BoxShadow(
                        color: AppColors.ink,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: AppColors.ink),
                const SizedBox(width: 4),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: AppTextStyles.label.copyWith(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: isSelected
                    ? BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        border: Border.all(
                          color: AppColors.ink,
                          width: AppBorders.thin,
                        ),
                      )
                    : null,
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppColors.ink : AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: isSelected
                      ? AppTextStyles.label.copyWith(fontSize: 10)
                      : AppTextStyles.bodySmall.copyWith(
                          fontSize: 10,
                          color: AppColors.mutedText,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
