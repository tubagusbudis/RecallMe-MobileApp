import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../application/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (!SupabaseConfig.isConfigured) {
      _emailController.text = 'raka@example.com';
      _passwordController.text = 'RecallMe123!';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    final success = await ref
        .read(authControllerProvider.notifier)
        .login(_emailController.text, _passwordController.text);
    if (success && mounted) {
      context.go('/app/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.p20),
                  decoration: AppDecorations.brutalBox(
                    backgroundColor: AppColors.primary,
                  ),
                  child: Column(
                    children: [
                      const Text('RecallMe', style: AppTextStyles.display),
                      const SizedBox(height: AppSpacing.p4),
                      Text(
                        'Learn today, remember tomorrow.',
                        style: AppTextStyles.bodyMediumBold.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.p24),

                // Form Container
                Container(
                  padding: const EdgeInsets.all(AppSpacing.p20),
                  decoration: AppDecorations.brutalBox(
                    backgroundColor: AppColors.surface,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Selamat Datang!', style: AppTextStyles.h2),
                      const SizedBox(height: AppSpacing.p4),
                      const Text(
                        'Masuk menggunakan Email & Password',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.p20),

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

                      // Email Field
                      AppTextField(
                        label: 'EMAIL',
                        hint: 'contoh: raka@example.com',
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

                      // Password Field
                      AppTextField(
                        label: 'PASSWORD',
                        hint: '••••••••',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        onChanged: (_) => ref
                            .read(authControllerProvider.notifier)
                            .clearError(),
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
                      const SizedBox(height: AppSpacing.p8),

                      // Lupa Password link
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => context.go('/forgot-password'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              'Lupa Password?',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.p20),

                      // Submit CTA
                      AppButton(
                        label: 'Masuk Sekarang',
                        isLoading: authState.isLoading,
                        onPressed: authState.isLoading ? null : _onLogin,
                        variant: AppButtonVariant.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.p24),

                // Link to Register
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Belum punya akun? ',
                      style: AppTextStyles.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: Text(
                        'Daftar di sini',
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
