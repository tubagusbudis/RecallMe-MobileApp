import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../application/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRegister() async {
    final success = await ref
        .read(authControllerProvider.notifier)
        .register(
          _usernameController.text,
          _emailController.text,
          _passwordController.text,
          displayName: _displayNameController.text,
        );
    if (success && mounted) {
      context.go('/app/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final passwordText = _passwordController.text;

    final hasMinLength = passwordText.length >= 8;
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(passwordText);
    final hasNumber = RegExp(r'[0-9]').hasMatch(passwordText);
    final hasSymbol = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(passwordText);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.p20),
                  decoration: AppDecorations.brutalBox(
                    backgroundColor: AppColors.teal,
                  ),
                  child: Column(
                    children: [
                      const Text('Buat Akun Baru', style: AppTextStyles.h1),
                      const SizedBox(height: AppSpacing.p4),
                      Text(
                        'Mulai latih ingatanmu hari ini!',
                        style: AppTextStyles.bodyMediumBold.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.p20),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(AppSpacing.p20),
                  decoration: AppDecorations.brutalBox(
                    backgroundColor: AppColors.surface,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Inline Error Banner
                      if (authState.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.p12),
                          decoration: BoxDecoration(
                            color: AppColors.coral.withValues(alpha: 0.2),
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
                                  authState.errorMessage!,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.p16),
                      ],

                      // Username
                      AppTextField(
                        label: 'USERNAME',
                        hint: 'contoh: siswa_unggul',
                        controller: _usernameController,
                        helperText: 'Hanya huruf, angka, dan garis bawah (_)',
                        onChanged: (_) => ref
                            .read(authControllerProvider.notifier)
                            .clearError(),
                        prefixIcon: const Icon(
                          Icons.alternate_email,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.p16),

                      // Email
                      AppTextField(
                        label: 'EMAIL',
                        hint: 'contoh: siswa@example.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) => ref
                            .read(authControllerProvider.notifier)
                            .clearError(),
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.p16),

                      // Display Name (Optional)
                      AppTextField(
                        label: 'NAMA TAMPILAN (OPSIONAL)',
                        hint: 'contoh: Budi Santoso',
                        controller: _displayNameController,
                        helperText:
                            'Nama yang ditampilkan di dashboard dan profil',
                        prefixIcon: const Icon(
                          Icons.badge_outlined,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.p16),

                      // Password
                      AppTextField(
                        label: 'PASSWORD',
                        hint: '••••••••',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        onChanged: (_) {
                          ref
                              .read(authControllerProvider.notifier)
                              .clearError();
                          setState(() {});
                        },
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: AppColors.ink,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.ink,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.p12),

                      // Password criteria checklist (PRD v1.1)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.p12),
                        decoration: BoxDecoration(
                          color: AppColors.disabledSurface.withValues(
                            alpha: 0.4,
                          ),
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          border: Border.all(
                            color: AppColors.ink,
                            width: AppBorders.thin,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Syarat Keamanan Password:',
                              style: AppTextStyles.label,
                            ),
                            const SizedBox(height: AppSpacing.p8),
                            _CriteriaItem(
                              label: 'Minimal 8 karakter',
                              isMet: hasMinLength,
                            ),
                            _CriteriaItem(
                              label: 'Mengandung huruf (A-Z, a-z)',
                              isMet: hasLetter,
                            ),
                            _CriteriaItem(
                              label: 'Mengandung angka (0-9)',
                              isMet: hasNumber,
                            ),
                            _CriteriaItem(
                              label: 'Mengandung simbol (!@#\$%^&*)',
                              isMet: hasSymbol,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.p24),

                      // Submit CTA
                      AppButton(
                        label: 'Daftar Sekarang',
                        isLoading: authState.isLoading,
                        onPressed: authState.isLoading ? null : _onRegister,
                        variant: AppButtonVariant.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.p20),

                // Link to Login
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Sudah punya akun? ',
                      style: AppTextStyles.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(
                        'Masuk di sini',
                        style: AppTextStyles.bodyMediumBold.copyWith(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CriteriaItem extends StatelessWidget {
  final String label;
  final bool isMet;

  const _CriteriaItem({required this.label, required this.isMet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 14,
            color: isMet ? AppColors.teal : AppColors.mutedText,
          ),
          const SizedBox(width: AppSpacing.p8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isMet ? AppColors.ink : AppColors.mutedText,
                fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
