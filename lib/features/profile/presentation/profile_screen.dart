import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../auth/application/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _onLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppDialog.show(
      context,
      title: 'Keluar dari Akun?',
      message: 'Kamu perlu memasukkan kembali username dan password untuk mengakses deck dan kartu belajarmu.',
      confirmLabel: 'Ya, Keluar',
      cancelLabel: 'Batal',
      isDestructive: false,
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Profil Saya', style: AppTextStyles.h2)),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageHorizontal,
          vertical: AppSpacing.pageVertical,
        ),
        children: [
          // User Card
          AppCard(
            backgroundColor: AppColors.primary,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: AppColors.ink,
                      width: AppBorders.standard,
                    ),
                    boxShadow: AppDecorations.shadowSm,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 32,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: AppSpacing.p16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Pengguna RecallMe',
                        style: AppTextStyles.h2,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${user?.username ?? "user"}',
                        style: AppTextStyles.bodyMediumBold,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.p24),

          // App Information Section (reflecting locked PRD v1.1 decisions)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Arsitektur & Aturan Belajar', style: AppTextStyles.h3),
                SizedBox(height: AppSpacing.p12),
                _InfoRow(label: 'Versi Aplikasi', value: '1.1 (Frontend MVP)'),
                Divider(height: AppSpacing.p16),
                _InfoRow(label: 'Metode Pengulangan', value: 'Adapted SM-2'),
                Divider(height: AppSpacing.p16),
                _InfoRow(label: 'Cakupan Sesi', value: '1 Deck / Sesi'),
                Divider(height: AppSpacing.p16),
                _InfoRow(label: 'Batas Sesi Belajar', value: 'Maks. 20 Kartu'),
                Divider(height: AppSpacing.p16),
                _InfoRow(label: 'Antrean Kartu Baru', value: 'Single Queue'),
                Divider(height: AppSpacing.p16),
                _InfoRow(label: 'Kebijakan Hapus', value: 'ON DELETE CASCADE'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.p32),

          // Logout Button
          AppButton(
            label: 'Keluar dari Akun',
            variant: AppButtonVariant.destructive,
            icon: const Icon(Icons.logout, color: AppColors.ink),
            onPressed: () => _onLogout(context, ref),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
        const SizedBox(width: AppSpacing.p12),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.bodyMediumBold,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
