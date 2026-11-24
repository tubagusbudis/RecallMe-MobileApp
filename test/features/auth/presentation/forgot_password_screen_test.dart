import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:recallme/app/app.dart';
import 'package:recallme/features/auth/data/auth_repository.dart';

void main() {
  group('ForgotPasswordScreen UI & Responsiveness Tests', () {
    testWidgets(
      'ForgotPasswordScreen renders on 360x800 without overflow and executes 3-step recovery flow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockRepo = MockAuthRepository(isUnauthenticated: true);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
            child: const RecallMeApp(),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Navigate from Welcome to Login
        final ctaBtn = find.text('MULAI BELAJAR SEKARANG');
        await tester.ensureVisible(ctaBtn);
        await tester.tap(ctaBtn);
        await tester.pumpAndSettle();

        expect(find.text('Selamat Datang!'), findsOneWidget);

        // 2. Tap "Lupa Password?" on LoginScreen
        final forgotBtn = find.text('Lupa Password?');
        expect(forgotBtn, findsOneWidget);
        await tester.tap(forgotBtn);
        await tester.pumpAndSettle();

        // Verifies on ForgotPasswordScreen Step 1
        expect(find.text('Pemulihan Password'), findsOneWidget);
        expect(find.text('1. Email'), findsOneWidget);
        expect(find.text('2. OTP'), findsOneWidget);
        expect(find.text('3. Password'), findsOneWidget);
        expect(find.text('EMAIL TERDAFTAR'), findsOneWidget);

        final sendOtpBtn = find.text('Kirim Kode OTP');
        expect(sendOtpBtn, findsOneWidget);

        // 3. Test Step 1 validation failure with invalid email
        final emailInput = find.byType(TextField).first;
        await tester.enterText(emailInput, 'invalid-email');
        await tester.ensureVisible(sendOtpBtn);
        await tester.tap(sendOtpBtn);
        await tester.pumpAndSettle();

        expect(find.text('Format email tidak valid'), findsOneWidget);

        // 4. Enter valid email and send OTP
        await tester.enterText(emailInput, 'user@example.com');
        await tester.ensureVisible(sendOtpBtn);
        await tester.tap(sendOtpBtn);
        await tester.pumpAndSettle();

        // Step 2: Verifikasi OTP
        expect(find.text('Verifikasi OTP'), findsOneWidget);
        expect(find.textContaining('user@example.com'), findsOneWidget);
        expect(find.text('KODE OTP (8 DIGIT)'), findsOneWidget);
        expect(find.text('Verifikasi Kode'), findsOneWidget);

        // 5. Test Step 2 validation failure with invalid OTP
        final verifyBtn = find.text('Verifikasi Kode');
        final otpInput = find.byType(TextField).first;
        await tester.enterText(otpInput, '123'); // less than 8 digits
        await tester.ensureVisible(verifyBtn);
        await tester.tap(verifyBtn);
        await tester.pumpAndSettle();

        expect(
          find.text('Kode OTP harus berupa 8 digit angka'),
          findsOneWidget,
        );

        // 6. Enter valid OTP ('12345678') and verify
        await tester.enterText(otpInput, '12345678');
        await tester.ensureVisible(verifyBtn);
        await tester.tap(verifyBtn);
        await tester.pumpAndSettle();

        // Step 3: Buat Password Baru
        expect(find.text('Password Baru'), findsOneWidget);
        expect(find.text('PASSWORD BARU'), findsOneWidget);
        expect(find.text('KONFIRMASI PASSWORD BARU'), findsOneWidget);
        expect(find.text('Syarat Keamanan Password:'), findsOneWidget);
        expect(find.text('Simpan Password Baru'), findsOneWidget);

        // 7. Test Step 3 mismatched password confirmation
        final newPassInput = find.byType(TextField).at(0);
        final confirmPassInput = find.byType(TextField).at(1);
        await tester.enterText(newPassInput, 'RecallMe123!');
        await tester.enterText(confirmPassInput, 'DifferentPassword#1');
        final saveBtn = find.text('Simpan Password Baru');
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        expect(find.text('Konfirmasi password tidak cocok'), findsOneWidget);

        // 8. Fix confirmation password and submit
        await tester.enterText(confirmPassInput, 'RecallMe123!');
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        // Verifies redirect back to Login screen and success snackbar
        expect(find.text('Selamat Datang!'), findsOneWidget);
        expect(find.text('Masuk menggunakan Email & Password'), findsOneWidget);
        expect(find.text('Deck Saya'), findsNothing);
        expect(mockRepo.currentUser, isNull);
        expect(
          find.text(
            'Password berhasil diperbarui! Silakan masuk dengan password baru.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'completing recovery redirects directly to /login and does not hit protected /app/home',
      (WidgetTester tester) async {
        final mockRepo = MockAuthRepository(isUnauthenticated: true);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
            child: const RecallMeApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Navigate to /forgot-password
        final ctaBtn = find.text('MULAI BELAJAR SEKARANG');
        await tester.ensureVisible(ctaBtn);
        await tester.tap(ctaBtn);
        await tester.pumpAndSettle();

        final forgotBtn = find.text('Lupa Password?');
        await tester.tap(forgotBtn);
        await tester.pumpAndSettle();

        // 1. Send OTP
        final emailInput = find.byType(TextField).first;
        await tester.enterText(emailInput, 'user@example.com');
        final sendOtpBtn = find.text('Kirim Kode OTP');
        await tester.tap(sendOtpBtn);
        await tester.pumpAndSettle();

        // 2. Verify OTP
        final otpInput = find.byType(TextField).first;
        await tester.enterText(otpInput, '12345678');
        final verifyBtn = find.text('Verifikasi Kode');
        await tester.tap(verifyBtn);
        await tester.pumpAndSettle();

        // 3. Save new password
        final newPassInput = find.byType(TextField).at(0);
        final confirmPassInput = find.byType(TextField).at(1);
        await tester.enterText(newPassInput, 'RecallMe123!');
        await tester.enterText(confirmPassInput, 'RecallMe123!');
        final saveBtn = find.text('Simpan Password Baru');
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        // Verify: Lands on /login, not /app/home
        expect(find.text('Selamat Datang!'), findsOneWidget);
        expect(find.text('Masuk menggunakan Email & Password'), findsOneWidget);
        expect(find.text('Deck Saya'), findsNothing);
        expect(mockRepo.currentUser, isNull);
      },
    );

    testWidgets('ForgotPasswordScreen renders on 390x844 without overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockRepo = MockAuthRepository(isUnauthenticated: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
          child: const RecallMeApp(),
        ),
      );
      await tester.pumpAndSettle();

      final ctaBtn = find.text('MULAI BELAJAR SEKARANG');
      await tester.ensureVisible(ctaBtn);
      await tester.tap(ctaBtn);
      await tester.pumpAndSettle();

      final forgotBtn = find.text('Lupa Password?');
      await tester.tap(forgotBtn);
      await tester.pumpAndSettle();

      expect(find.text('Pemulihan Password'), findsOneWidget);
      expect(find.text('Kirim Kode OTP'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
