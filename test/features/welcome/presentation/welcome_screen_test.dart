import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:recallme/app/app.dart';
import 'package:recallme/features/auth/data/auth_repository.dart';

void main() {
  group('WelcomeScreen & Navigation Tests', () {
    testWidgets(
      'Welcome screen renders on 360x800 without overflow and navigates to Login',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // Use unauthenticated mock repository so app stays on /welcome
        final unauthRepo = MockAuthRepository(isUnauthenticated: true);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authRepositoryProvider.overrideWithValue(unauthRepo)],
            child: const RecallMeApp(),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify Top Header
        expect(find.text('RecallMe'), findsOneWidget);
        expect(find.text('MEMORY TRAINER'), findsOneWidget);
        expect(find.text('SM-2 ENGINE'), findsOneWidget);

        // 2. Verify Hero Card
        expect(find.text('KARTU #01'), findsOneWidget);
        expect(find.text('+100% RETENSI'), findsOneWidget);
        expect(find.text('METODE RAHASIA JUARA'), findsOneWidget);
        expect(find.text('Active Recall & Spaced\nRepetition'), findsOneWidget);
        expect(find.text('2.4x Cepat'), findsOneWidget);

        // 3. Verify Headline & Description
        expect(find.text('METODE ILMIAH TERBUKTI'), findsOneWidget);
        expect(find.text('Belajar hari ini,'), findsOneWidget);
        expect(find.text('ingat lebih lama.'), findsOneWidget);

        // 4. Verify 3 Feature Mini-Cards
        expect(find.text('Active'), findsOneWidget);
        expect(find.text('Recall'), findsOneWidget);
        expect(find.text('Spaced'), findsOneWidget);
        expect(find.text('SM-2'), findsOneWidget);
        expect(find.text('Progress'), findsOneWidget);
        expect(find.text('Terukur'), findsOneWidget);

        // 5. Verify CTA Button
        final ctaBtn = find.text('MULAI BELAJAR SEKARANG');
        expect(ctaBtn, findsOneWidget);

        // 6. Verify Footer
        expect(
          find.text(
            'VERSI 1.1 • RECALLME © 2026 BY TUBAGUS. ALL RIGHTS RESERVED',
          ),
          findsOneWidget,
        );

        // 7. Scroll to CTA Button, tap, and verify navigation to Login screen
        await tester.ensureVisible(ctaBtn);
        await tester.pumpAndSettle();
        await tester.tap(ctaBtn);
        await tester.pumpAndSettle();

        expect(find.text('Selamat Datang!'), findsOneWidget);
        expect(
          find.text('Masuk menggunakan Username & Password'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Welcome screen renders on 390x844 without overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final unauthRepo = MockAuthRepository(isUnauthenticated: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(unauthRepo)],
          child: const RecallMeApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RecallMe'), findsOneWidget);
      expect(find.text('MULAI BELAJAR SEKARANG'), findsOneWidget);
    });
  });
}
