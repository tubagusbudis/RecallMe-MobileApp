import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:recallme/core/theme/app_theme.dart';
import 'package:recallme/features/profile/presentation/profile_screen.dart';

void main() {
  Widget buildTestableProfileScreen() {
    return ProviderScope(
      child: MaterialApp(theme: AppTheme.theme, home: const ProfileScreen()),
    );
  }

  group('ProfileScreen User-Facing Presentation Tests', () {
    testWidgets(
      'ProfileScreen renders without overflow on 360x800 and 390x844 viewports',
      (WidgetTester tester) async {
        // Test 360x800 viewport
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildTestableProfileScreen());
        await tester.pumpAndSettle();

        expect(find.text('Profil Saya'), findsOneWidget);
        expect(find.text('Aturan Belajar'), findsOneWidget);
        expect(find.text('Cara Belajar'), findsOneWidget);

        // Test 390x844 viewport
        tester.view.physicalSize = const Size(390, 844);
        await tester.pumpWidget(buildTestableProfileScreen());
        await tester.pumpAndSettle();

        expect(find.text('Profil Saya'), findsOneWidget);
        expect(find.text('Aturan Belajar'), findsOneWidget);
        expect(find.text('Cara Belajar'), findsOneWidget);
      },
    );

    testWidgets(
      'Developer/technical texts are completely removed from ProfileScreen',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestableProfileScreen());
        await tester.pumpAndSettle();

        expect(find.textContaining('Versi Aplikasi'), findsNothing);
        expect(find.textContaining('1.1 Frontend MVP'), findsNothing);
        expect(find.textContaining('Single Queue'), findsNothing);
        expect(find.textContaining('Antrean Kartu Baru'), findsNothing);
        expect(find.textContaining('Kebijakan Hapus'), findsNothing);
        expect(find.textContaining('ON DELETE CASCADE'), findsNothing);
        expect(find.textContaining('Arsitektur &'), findsNothing);
        expect(find.textContaining('Adapted SM-2'), findsNothing);
      },
    );

    testWidgets('Aturan Belajar card shows all 4 user-friendly items', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableProfileScreen());
      await tester.pumpAndSettle();

      expect(find.text('Aturan Belajar'), findsOneWidget);
      expect(find.text('Fokus Sesi'), findsOneWidget);
      expect(find.text('1 Deck / Sesi'), findsOneWidget);
      expect(find.text('Batas Sesi Belajar'), findsOneWidget);
      expect(find.text('Maks. 20 Kartu'), findsOneWidget);
      expect(find.text('Sistem Penjadwalan'), findsOneWidget);
      expect(find.text('Otomatis (Spaced Repetition)'), findsOneWidget);
      expect(find.text('Kartu Baru'), findsOneWidget);
      expect(find.text('Langsung Siap Dipelajari'), findsOneWidget);

      // Verify all 4 value widgets are aligned to the right (TextAlign.right)
      for (final textVal in [
        '1 Deck / Sesi',
        'Maks. 20 Kartu',
        'Otomatis (Spaced Repetition)',
        'Langsung Siap Dipelajari',
      ]) {
        final textWidget = tester.widget<Text>(find.text(textVal));
        expect(textWidget.textAlign, equals(TextAlign.right));
      }
    });

    testWidgets(
      'Cara Belajar card displays 3 steps and semantic rating guide',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestableProfileScreen());
        await tester.pumpAndSettle();

        expect(find.text('Cara Belajar'), findsOneWidget);

        // Step 1
        expect(find.text('Langkah 1'), findsOneWidget);
        expect(find.text('Buat Deck & Kartu'), findsOneWidget);
        expect(
          find.text(
            'Kelompokkan materi per topik dan isi pertanyaan serta jawabannya.',
          ),
          findsOneWidget,
        );

        // Step 2
        expect(find.text('Langkah 2'), findsOneWidget);
        expect(find.text('Ingat Dulu, Baru Buka'), findsOneWidget);
        expect(
          find.text(
            'Coba ingat jawaban di kepala sebelum membuka jawaban kartu.',
          ),
          findsOneWidget,
        );

        // Step 3
        expect(find.text('Langkah 3'), findsOneWidget);
        expect(find.text('Nilai Ingatanmu'), findsOneWidget);
        expect(
          find.text('Pilih rating jujur agar jadwal belajar diatur otomatis:'),
          findsOneWidget,
        );

        // Rating rows
        expect(find.text('Again'), findsOneWidget);
        expect(find.text('Lupa — diulang lebih cepat'), findsOneWidget);

        expect(find.text('Hard'), findsOneWidget);
        expect(find.text('Ragu — diulang dalam waktu dekat'), findsOneWidget);

        expect(find.text('Good'), findsOneWidget);
        expect(find.text('Ingat — jeda review diperpanjang'), findsOneWidget);

        expect(find.text('Easy'), findsOneWidget);
        expect(
          find.text('Sangat hafal — jeda review jauh lebih lama'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Logout button opens confirmation dialog and can be cancelled',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestableProfileScreen());
        await tester.pumpAndSettle();

        final logoutBtn = find.text('Keluar dari Akun');
        expect(logoutBtn, findsOneWidget);

        await tester.ensureVisible(logoutBtn);
        await tester.pumpAndSettle();
        await tester.tap(logoutBtn);
        await tester.pumpAndSettle();

        expect(find.text('Keluar dari Akun?'), findsOneWidget);
        expect(find.text('Batal'), findsOneWidget);
        expect(find.text('Ya, Keluar'), findsOneWidget);

        // Cancel dialog
        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();

        expect(find.text('Keluar dari Akun?'), findsNothing);
        expect(find.text('Profil Saya'), findsOneWidget);
      },
    );
  });
}
