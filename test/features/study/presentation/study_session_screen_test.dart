import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:recallme/core/theme/app_theme.dart';
import 'package:recallme/features/study/presentation/study_session_screen.dart';

void main() {
  Widget buildTestableStudySessionScreen({String deckId = 'deck-1'}) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.theme,
        home: StudySessionScreen(deckId: deckId),
      ),
    );
  }

  group('StudySessionScreen UI & Responsiveness Tests', () {
    testWidgets(
      'Question state renders responsive flashcard, hint footer, and focus indicator',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildTestableStudySessionScreen());
        await tester.pumpAndSettle();

        // 1. Progress Bar
        expect(find.text('KARTU SESI INI'), findsOneWidget);

        // 2. Badge PERTANYAAN
        expect(find.text('PERTANYAAN'), findsOneWidget);
        expect(find.byIcon(Icons.help_outline), findsOneWidget);

        // 3. Question text & lightbulb hint footer
        expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
        expect(
          find.text(
            'Pikirkan jawabanmu di memori atau ucapkan dalam hati sebelum membuka kunci jawaban.',
          ),
          findsOneWidget,
        );

        // 4. Focus indicator
        expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
        expect(find.text('Fokus maksimal: Tanpa gangguan'), findsOneWidget);

        // 5. Action button "Lihat Jawaban"
        expect(find.text('Lihat Jawaban'), findsOneWidget);
        expect(find.text('JAWABAN'), findsNothing);
      },
    );

    testWidgets(
      'Revealing answer transitions to Answer state, hides hint footer, shows JAWABAN badge and ratings',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestableStudySessionScreen());
        await tester.pumpAndSettle();

        // Tap "Lihat Jawaban"
        final revealButton = find.text('Lihat Jawaban');
        expect(revealButton, findsOneWidget);
        await tester.tap(revealButton);
        await tester.pumpAndSettle();

        // 1. Hint footer must be hidden
        expect(find.byIcon(Icons.lightbulb_outline), findsNothing);
        expect(
          find.text(
            'Pikirkan jawabanmu di memori atau ucapkan dalam hati sebelum membuka kunci jawaban.',
          ),
          findsNothing,
        );

        // 2. Badge JAWABAN must be visible
        expect(find.text('JAWABAN'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

        // 3. Focus indicator remains visible
        expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
        expect(find.text('Fokus maksimal: Tanpa gangguan'), findsOneWidget);

        // 4. Rating prompt and 4 rating buttons must be visible
        expect(find.text('Seberapa mudah kamu mengingatnya?'), findsOneWidget);
        expect(find.text('Again (1)'), findsOneWidget);
        expect(find.text('Hard (3)'), findsOneWidget);
        expect(find.text('Good (4)'), findsOneWidget);
        expect(find.text('Easy (5)'), findsOneWidget);
      },
    );

    testWidgets(
      'StudySessionScreen renders without overflow on 360x800 and 390x844 viewports',
      (WidgetTester tester) async {
        // Test 360x800 (narrow screen)
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildTestableStudySessionScreen());
        await tester.pumpAndSettle();

        expect(find.text('PERTANYAAN'), findsOneWidget);
        expect(find.text('Fokus maksimal: Tanpa gangguan'), findsOneWidget);

        // Reveal answer on 360x800
        await tester.tap(find.text('Lihat Jawaban'));
        await tester.pumpAndSettle();

        expect(find.text('JAWABAN'), findsOneWidget);
        expect(find.text('Again (1)'), findsOneWidget);
        expect(find.text('Easy (5)'), findsOneWidget);

        // Test 390x844
        tester.view.physicalSize = const Size(390, 844);
        await tester.pumpWidget(buildTestableStudySessionScreen());
        await tester.pumpAndSettle();

        expect(find.text('PERTANYAAN'), findsOneWidget);
        expect(find.text('Fokus maksimal: Tanpa gangguan'), findsOneWidget);
      },
    );
  });
}
