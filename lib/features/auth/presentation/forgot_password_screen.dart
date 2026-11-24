import 'dart:async';

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
import '../domain/auth_validators.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  int _currentStep = 1; // 1: Email, 2: OTP, 3: Password Baru

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  String? _localValidationError;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startCooldown([int seconds = 60]) {
    _cooldownTimer?.cancel();
    setState(() {
      _cooldownSeconds = seconds;
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _cooldownSeconds = 0;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _cooldownSeconds--;
          });
        }
      }
    });
  }

  void _onSendOtp() async {
    setState(() {
      _localValidationError = null;
    });
    final email = _emailController.text.trim();
    final err = AuthValidators.validateEmail(email);
    if (err != null) {
      setState(() {
        _localValidationError = err;
      });
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordResetOtp(email);

    if (success && mounted) {
      _startCooldown(60);
      setState(() {
        _currentStep = 2;
        _localValidationError = null;
      });
    }
  }

  void _onResendOtp() async {
    if (_cooldownSeconds > 0) return;
    final email = _emailController.text.trim();
    final success = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordResetOtp(email);

    if (success && mounted) {
      _startCooldown(60);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kode OTP baru berhasil dikirim ke $email',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          backgroundColor: AppColors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onVerifyOtp() async {
    setState(() {
      _localValidationError = null;
    });
    final otp = _otpController.text.trim();
    final err = AuthValidators.validateOtp(otp);
    if (err != null) {
      setState(() {
        _localValidationError = err;
      });
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .verifyPasswordResetOtp(
          email: _emailController.text.trim(),
          token: otp,
        );

    if (success && mounted) {
      setState(() {
        _currentStep = 3;
        _localValidationError = null;
      });
    }
  }

  void _onUpdatePassword() async {
    setState(() {
      _localValidationError = null;
    });
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    final err = AuthValidators.validatePassword(newPass);
    if (err != null) {
      setState(() {
        _localValidationError = err;
      });
      return;
    }

    if (newPass != confirmPass) {
      setState(() {
        _localValidationError = 'Konfirmasi password tidak cocok';
      });
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .completePasswordRecovery(newPass);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password berhasil diperbarui! Silakan masuk dengan password baru.',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          backgroundColor: AppColors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final activeError = _localValidationError ?? authState.errorMessage;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Brand Banner
                Container(
                  padding: const EdgeInsets.all(AppSpacing.p20),
                  decoration: AppDecorations.brutalBox(
                    backgroundColor: AppColors.primary,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.ink,
                        ),
                        onPressed: () {
                          if (_currentStep > 1) {
                            setState(() {
                              _currentStep--;
                              _localValidationError = null;
                            });
                          } else {
                            context.go('/login');
                          }
                        },
                      ),
                      const SizedBox(width: AppSpacing.p8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pemulihan Password',
                              style: AppTextStyles.h2,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'RecallMe Akun',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.p16),

                // Step Indicator Pills
                _buildStepIndicator(),
                const SizedBox(height: AppSpacing.p16),

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
                      if (activeError != null) ...[
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
                                  activeError,
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

                      // Dynamic Step View
                      if (_currentStep == 1)
                        _buildStep1Email(authState.isLoading)
                      else if (_currentStep == 2)
                        _buildStep2Otp(authState.isLoading)
                      else
                        _buildStep3NewPassword(authState.isLoading),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.p20),

                // Link Back to Login
                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.p8),
                      child: Text(
                        'Kembali ke Halaman Masuk',
                        style: AppTextStyles.bodyMediumBold.copyWith(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepPill(1, '1. Email'),
        const SizedBox(width: AppSpacing.p8),
        _buildStepPill(2, '2. OTP'),
        const SizedBox(width: AppSpacing.p8),
        _buildStepPill(3, '3. Password'),
      ],
    );
  }

  Widget _buildStepPill(int stepNumber, String title) {
    final isActive = _currentStep == stepNumber;
    final isDone = _currentStep > stepNumber;

    final bgColor = isDone
        ? AppColors.teal
        : (isActive ? AppColors.primary : AppColors.surface);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(color: AppColors.ink, width: AppBorders.standard),
          boxShadow: isActive ? AppDecorations.shadowSm : null,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              maxLines: 1,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11,
                color: AppColors.ink,
                fontWeight: isActive || isDone
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // TAHAP 1: Masukkan Email
  Widget _buildStep1Email(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lupa Password?', style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.p4),
        const Text(
          'Masukkan email yang terdaftar untuk menerima 8 digit kode OTP pemulihan.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.p20),
        AppTextField(
          label: 'EMAIL TERDAFTAR',
          hint: 'contoh: nama@example.com',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) {
            if (_localValidationError != null) {
              setState(() => _localValidationError = null);
            }
            ref.read(authControllerProvider.notifier).clearError();
          },
          prefixIcon: const Icon(Icons.email_outlined, color: AppColors.ink),
        ),
        const SizedBox(height: AppSpacing.p24),
        AppButton(
          label: 'Kirim Kode OTP',
          isLoading: isLoading,
          onPressed: isLoading ? null : _onSendOtp,
          variant: AppButtonVariant.primary,
        ),
      ],
    );
  }

  // TAHAP 2: Verifikasi OTP 8 Digit
  Widget _buildStep2Otp(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Verifikasi OTP', style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.p4),
        Text(
          'Kode OTP 8 digit telah dikirim ke:\n${_emailController.text.trim()}',
          style: AppTextStyles.bodyMediumBold,
        ),
        const SizedBox(height: AppSpacing.p20),
        AppTextField(
          label: 'KODE OTP (8 DIGIT)',
          hint: '12345678',
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 8,
          onChanged: (_) {
            if (_localValidationError != null) {
              setState(() => _localValidationError = null);
            }
            ref.read(authControllerProvider.notifier).clearError();
          },
          prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.ink),
        ),
        const SizedBox(height: AppSpacing.p8),
        Wrap(
          spacing: 16,
          runSpacing: AppSpacing.p8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentStep = 1;
                  _localValidationError = null;
                });
              },
              child: Text(
                'Ganti Email',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            if (_cooldownSeconds > 0)
              Text(
                'Kirim ulang dalam ${_cooldownSeconds}s',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.mutedText,
                ),
              )
            else
              GestureDetector(
                onTap: isLoading ? null : _onResendOtp,
                child: Text(
                  'Kirim Ulang Kode',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.p24),
        AppButton(
          label: 'Verifikasi Kode',
          isLoading: isLoading,
          onPressed: isLoading ? null : _onVerifyOtp,
          variant: AppButtonVariant.primary,
        ),
      ],
    );
  }

  // TAHAP 3: Buat Password Baru
  Widget _buildStep3NewPassword(bool isLoading) {
    final passwordText = _newPasswordController.text;
    final hasMinLength = passwordText.length >= 8;
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(passwordText);
    final hasNumber = RegExp(r'[0-9]').hasMatch(passwordText);
    final hasSymbol = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(passwordText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Password Baru', style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.p4),
        const Text(
          'Buat password baru yang aman untuk akun Anda.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.p20),
        AppTextField(
          label: 'PASSWORD BARU',
          hint: '••••••••',
          controller: _newPasswordController,
          obscureText: _obscureNewPassword,
          onChanged: (_) {
            if (_localValidationError != null) {
              setState(() => _localValidationError = null);
            }
            ref.read(authControllerProvider.notifier).clearError();
            setState(() {});
          },
          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.ink),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.ink,
            ),
            onPressed: () =>
                setState(() => _obscureNewPassword = !_obscureNewPassword),
          ),
        ),
        const SizedBox(height: AppSpacing.p16),
        AppTextField(
          label: 'KONFIRMASI PASSWORD BARU',
          hint: '••••••••',
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          onChanged: (_) {
            if (_localValidationError != null) {
              setState(() => _localValidationError = null);
            }
            ref.read(authControllerProvider.notifier).clearError();
          },
          prefixIcon: const Icon(Icons.lock_reset, color: AppColors.ink),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.ink,
            ),
            onPressed: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.p12),

        // Security checklist
        Container(
          padding: const EdgeInsets.all(AppSpacing.p12),
          decoration: BoxDecoration(
            color: AppColors.disabledSurface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(color: AppColors.ink, width: AppBorders.thin),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Syarat Keamanan Password:',
                style: AppTextStyles.label,
              ),
              const SizedBox(height: AppSpacing.p8),
              _CriteriaItem(label: 'Minimal 8 karakter', isMet: hasMinLength),
              _CriteriaItem(
                label: 'Mengandung huruf (A-Z, a-z)',
                isMet: hasLetter,
              ),
              _CriteriaItem(label: 'Mengandung angka (0-9)', isMet: hasNumber),
              _CriteriaItem(
                label: 'Mengandung simbol (!@#\$%^&*)',
                isMet: hasSymbol,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.p24),
        AppButton(
          label: 'Simpan Password Baru',
          isLoading: isLoading,
          onPressed: isLoading ? null : _onUpdatePassword,
          variant: AppButtonVariant.primary,
        ),
      ],
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
