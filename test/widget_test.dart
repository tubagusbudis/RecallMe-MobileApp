import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:recallme/app/app.dart';
import 'package:recallme/core/widgets/app_card.dart';

void main() {
  testWidgets('RecallMe app smoke & navigation test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: RecallMeApp()));
    await tester.pumpAndSettle();

    // 1. Verify Home screen elements
    expect(find.text('RecallMe'), findsOneWidget);
    expect(find.text('Halo, Raka Pratama! 👋'), findsOneWidget);
    expect(find.text('Target Spaced Repetition'), findsOneWidget);
    expect(find.text('Flutter & Dart Concepts'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Deck'), findsOneWidget);
    expect(find.text('Belajar'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    // 2. Tap on Deck tab
    await tester.tap(find.text('Deck'));
    await tester.pumpAndSettle();
    expect(find.text('Deck Saya'), findsOneWidget);
    expect(find.text('Buat Deck Baru'), findsOneWidget);

    // 3. Tap on Progress tab
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(find.text('Progress Belajar'), findsOneWidget);
    expect(find.text('TOTAL REVIEW'), findsOneWidget);
    expect(find.text('Distribusi Penilaian Jawaban'), findsOneWidget);

    // 4. Tap on Profil tab
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Profil Saya'), findsOneWidget);
    expect(find.text('Raka Pratama'), findsOneWidget);
    expect(find.text('@raka_belajar'), findsOneWidget);
    expect(find.text('Keluar dari Akun'), findsOneWidget);
  });

  testWidgets(
    'Edit Flashcard screen on narrow viewport (360dp) has no overflow and Batal works',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const ProviderScope(child: RecallMeApp()));
      await tester.pumpAndSettle();

      // Go to Deck tab
      await tester.tap(find.text('Deck'));
      await tester.pumpAndSettle();

      // Open first deck by tapping title
      await tester.tap(find.text('Flutter & Dart Concepts').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Daftar Flashcard'), findsOneWidget);

      // Drag down to reveal flashcards
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      final cardQuestion = find.text(
        'Apa perbedaan StatelessWidget dan StatefulWidget di Flutter?',
      );
      expect(cardQuestion, findsOneWidget);

      // Find the edit button inside that card
      final cardFinder = find.ancestor(
        of: cardQuestion,
        matching: find.byType(AppCard),
      );
      final editCardButton = find.descendant(
        of: cardFinder,
        matching: find.byIcon(Icons.edit),
      );
      await tester.tap(editCardButton);
      await tester.pumpAndSettle();

      // Verify Edit Flashcard screen is displayed without overflow
      expect(find.text('Edit Flashcard'), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);

      // Verify back button on AppBar is present
      expect(find.byTooltip('Kembali'), findsOneWidget);

      // Tap Batal button
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      // Should return to Deck Detail
      expect(find.textContaining('Daftar Flashcard'), findsOneWidget);
    },
  );

  testWidgets('Edit Flashcard saving navigates back to Deck Detail', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: RecallMeApp()));
    await tester.pumpAndSettle();

    // Go to Deck tab
    await tester.tap(find.text('Deck'));
    await tester.pumpAndSettle();

    // Open first deck by tapping title
    await tester.tap(find.text('Flutter & Dart Concepts').first);
    await tester.pumpAndSettle();

    // Drag down to reveal flashcards
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    final cardQuestion = find.text(
      'Apa perbedaan StatelessWidget dan StatefulWidget di Flutter?',
    );
    expect(cardQuestion, findsOneWidget);

    // Find the edit button inside that card
    final cardFinder = find.ancestor(
      of: cardQuestion,
      matching: find.byType(AppCard),
    );
    final editCardButton = find.descendant(
      of: cardFinder,
      matching: find.byIcon(Icons.edit),
    );
    await tester.tap(editCardButton);
    await tester.pumpAndSettle();

    expect(find.text('Edit Flashcard'), findsOneWidget);

    // Tap Simpan Perubahan
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    // Should return to Deck Detail and show SnackBar
    expect(find.textContaining('Daftar Flashcard'), findsOneWidget);
    expect(find.text('Flashcard berhasil diperbarui'), findsOneWidget);
  });

  testWidgets(
    'Study Session close (X) button closes session and returns to Home',
    (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: RecallMeApp()));
      await tester.pumpAndSettle();

      // Ensure we are on Home tab
      await tester.tap(find.text('Beranda'));
      await tester.pumpAndSettle();

      // On Home screen, tap "Mulai Review Sekarang"
      final startReviewBtn = find.text('Mulai Review Sekarang');
      expect(startReviewBtn, findsOneWidget);
      await tester.tap(startReviewBtn);
      await tester.pumpAndSettle();

      // Verify we are on Study Session screen
      expect(find.byTooltip('Keluar Sesi'), findsOneWidget);
      expect(find.text('KARTU SESI INI'), findsOneWidget);

      // Tap close (X) button
      await tester.tap(find.byTooltip('Keluar Sesi'));
      await tester.pumpAndSettle();

      // Verify we returned to Home
      expect(find.text('Target Spaced Repetition'), findsOneWidget);
      expect(find.text('Halo, Raka Pratama! 👋'), findsOneWidget);
    },
  );

  testWidgets(
    'Study Session close (X) button from Deck Detail returns to Deck Detail',
    (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: RecallMeApp()));
      await tester.pumpAndSettle();

      // Navigate to Deck tab -> open deck
      await tester.tap(find.text('Deck'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Flutter & Dart Concepts').first);
      await tester.pumpAndSettle();

      // Tap Mulai Sesi Belajar
      final studyBtn = find.textContaining('Mulai Sesi Belajar');
      expect(studyBtn, findsOneWidget);
      await tester.tap(studyBtn);
      await tester.pumpAndSettle();

      // Verify on Study Session
      expect(find.byTooltip('Keluar Sesi'), findsOneWidget);

      // Tap close (X) button
      await tester.tap(find.byTooltip('Keluar Sesi'));
      await tester.pumpAndSettle();

      // Verify returned to Deck Detail
      expect(find.textContaining('Daftar Flashcard'), findsOneWidget);
    },
  );
}
