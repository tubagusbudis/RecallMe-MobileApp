import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_badge.dart';
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageHorizontal,
          vertical: AppSpacing.pageVertical,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            const SizedBox(height: AppSpacing.p20),

            // Aturan Belajar Card
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Aturan Belajar', style: AppTextStyles.h3),
                  SizedBox(height: AppSpacing.p12),
                  _InfoRow(label: 'Fokus Sesi', value: '1 Deck / Sesi'),
                  Divider(height: AppSpacing.p16),
                  _InfoRow(
                    label: 'Batas Sesi Belajar',
                    value: 'Maks. 20 Kartu',
                  ),
                  Divider(height: AppSpacing.p16),
                  _InfoRow(
                    label: 'Sistem Penjadwalan',
                    value: 'Otomatis (Spaced Repetition)',
                  ),
                  Divider(height: AppSpacing.p16),
                  _InfoRow(
                    label: 'Kartu Baru',
                    value: 'Langsung Siap Dipelajari',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.p20),

            // Cara Belajar Card
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cara Belajar', style: AppTextStyles.h3),
                  SizedBox(height: AppSpacing.p12),
                  _StepItem(
                    step: 1,
                    title: 'Buat Deck & Kartu',
                    description: 'Kelompokkan materi per topik dan isi pertanyaan serta jawabannya.',
                  ),
                  Divider(height: AppSpacing.p20),
                  _StepItem(
                    step: 2,
                    title: 'Ingat Dulu, Baru Buka',
                    description: 'Coba ingat jawaban di kepala sebelum membuka jawaban kartu.',
                  ),
                  Divider(height: AppSpacing.p20),
                  _StepItem(
                    step: 3,
                    title: 'Nilai Ingatanmu',
                    description: 'Pilih rating jujur agar jadwal belajar diatur otomatis:',
                    extraContent: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RatingGuideRow(
                          label: 'Again',
                          color: AppColors.ratingAgain,
                          description: 'Lupa — diulang lebih cepat',
                        ),
                        SizedBox(height: AppSpacing.p8),
                        _RatingGuideRow(
                          label: 'Hard',
                          color: AppColors.ratingHard,
                          description: 'Ragu — diulang dalam waktu dekat',
                        ),
                        SizedBox(height: AppSpacing.p8),
                        _RatingGuideRow(
                          label: 'Good',
                          color: AppColors.ratingGood,
                          description: 'Ingat — jeda review diperpanjang',
                        ),
                        SizedBox(height: AppSpacing.p8),
                        _RatingGuideRow(
                          label: 'Easy',
                          color: AppColors.ratingEasy,
                          description:
                              'Sangat hafal — jeda review jauh lebih lama',
                        ),
                      ],
                    ),
                  ),
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
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMediumBold,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _StepItem extends StatelessWidget {
  final int step;
  final String title;
  final String description;
  final Widget? extraContent;

  const _StepItem({
    required this.step,
    required this.title,
    required this.description,
    this.extraContent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppBadge(
              label: 'Langkah $step',
              backgroundColor: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.p8),
            Expanded(child: Text(title, style: AppTextStyles.bodyMediumBold)),
          ],
        ),
        const SizedBox(height: AppSpacing.p4),
        Text(description, style: AppTextStyles.bodyMedium),
        if (extraContent != null) ...[
          const SizedBox(height: AppSpacing.p8),
          extraContent!,
        ],
      ],
    );
  }
}

class _RatingGuideRow extends StatelessWidget {
  final String label;
  final Color color;
  final String description;

  const _RatingGuideRow({
    required this.label,
    required this.color,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 58,
          child: Align(
            alignment: Alignment.centerLeft,
            child: AppBadge(label: label, backgroundColor: color),
          ),
        ),
        const SizedBox(width: AppSpacing.p8),
        Expanded(
          child: Text(
            description,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
