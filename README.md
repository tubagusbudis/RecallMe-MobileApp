# ⚡ RecallMe — Smart Memory Trainer

> **Learn today, remember tomorrow.**  
> Aplikasi mobile *smart flashcard* dan *memory training* modern berbasis metode ilmiah **Active Recall** dan algoritma **SuperMemo SM-2 Spaced Repetition**, dibungkus dalam visual **Functional Neo-Brutalism** yang tegas, kontras, dan berkarakter.

---

[![Flutter](https://img.shields.io/badge/Flutter-3.50+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.14+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend%20%26%20Postgres-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Riverpod](https://img.shields.io/badge/State-Flutter%20Riverpod%203.5-blueviolet)](https://riverpod.dev)
[![GoRouter](https://img.shields.io/badge/Router-GoRouter%2018-orange)](https://pub.dev/packages/go_router)
[![Tests](https://img.shields.io/badge/Tests-65%2F65%20Passed-brightgreen)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-black.svg)](LICENSE)

---

## 📌 Daftar Isi

- [Tentang RecallMe](#-tentang-recallme)
- [Fitur Utama](#-fitur-utama)
- [Algoritma Spaced Repetition (SM-2)](#-algoritma-spaced-repetition-sm-2)
- [Desain & UI/UX (Functional Neo-Brutalism)](#-desain--uiux-functional-neo-brutalism)
- [Arsitektur Proyek](#-arsitektur-proyek)
- [Struktur Database & Keamanan (Supabase)](#-struktur-database--keamanan-supabase)
- [Persiapan & Instalasi](#-persiapan--instalasi)
- [Menjalankan Aplikasi](#-menjalankan-aplikasi)
- [Pengujian Otomatis (Testing)](#-pengujian-otomatis-testing)
- [Kontributor & Lisensi](#-kontributor--lisensi)

---

## 📖 Tentang RecallMe

Banyak pelajar, mahasiswa, dan profesional menghadapi masalah yang sama: **cepat lupa apa yang baru dipelajari** (*Ebbinghaus Forgetting Curve*). Metode belajar pasif seperti membaca ulang atau menstabilo catatan terbukti tidak efektif untuk memori jangka panjang.

**RecallMe** hadir sebagai solusi latihan memori pintar:
1. **Active Recall**: Memaksa otak memanggil kembali informasi dari ingatan sebelum melihat jawaban.
2. **Spaced Repetition (SM-2)**: Menghitung jadwal review kartu secara matematis berdasarkan tingkat kesulitan yang dirasakan pengguna, mengulang materi tepat sebelum Anda melupakannya.
3. **Single Deck Focus**: Sesi belajar terfokus maksimal 20 kartu per sesi tanpa distraksi.
4. **Offline Mock Fallback**: Tetap dapat dicoba dan dijalankan langsung tanpa koneksi Supabase berkat built-in in-memory repository.

---

## ✨ Fitur Utama

### 1. 🚀 Splash / Welcome Screen
- Onboarding visual Neo-Brutalist yang memperkenalkan konsep *Active Recall* dan *SM-2 Engine*.
- Navigasi pintar berbasis session: jika sudah login langsung diarahkan ke Beranda, jika belum dapat langsung menekan tombol *"MULAI BELAJAR SEKARANG"* menuju halaman Login.
- Responsif dan bebas `RenderFlex overflow` pada berbagai ukuran layar (`360x800` s/d `390x844+`).

### 2. 🔐 Autentikasi Tanpa Email Rumit
- Registrasi dan login cukup menggunakan **Username** dan **Password**.
- Pemetaan otomatis di balik layar ke format Supabase Auth internal: `<username>@recallme.internal`.
- Validasi keamanan password ketat:
  - Minimal 8 karakter.
  - Kombinasi huruf besar/kecil (A-Z, a-z).
  - Kombinasi angka (0-9).
  - Kombinasi simbol (`!@#$%^&*`).
- Penanganan error ramah pengguna (username sudah terpakai, format salah, kredensial keliru).

### 3. 🗂️ Manajemen Deck & Flashcard (CRUD)
- Buat, edit, lihat, dan hapus koleksi kartu (Deck) dengan kategori, warna aksen, dan deskripsi.
- Tambah dan edit kartu belajar (pertanyaan & jawaban teks).
- **Single Queue System**: Setiap kartu baru otomatis dijadwalkan untuk review hari ini (`next_review_at = now()`, `repetitions = 0`, `interval_days = 0`, `ease_factor = 2.5`).
- **Cascade Deletion**: Penghapusan deck secara aman menghapus seluruh kartu dan log review terkait (`ON DELETE CASCADE`) dengan dialog konfirmasi eksplisit.

### 4. 🎯 Sesi Belajar Terfokus (Study Engine)
- Batas maksimal **20 kartu per sesi** (`LIMIT 20`) agar sesi belajar tetap segar dan tidak menimbulkan kelelahan kognitif (*cognitive fatigue*).
- Alur belajar aktif:
  1. Tampilkan Pertanyaan.
  2. Ketuk *"Buka Jawaban"*.
  3. Beri penilaian kualitas ingatan (Again, Hard, Good, Easy).
- **Atomic Review RPC**: Menyimpan log dan memperbarui jadwal kartu melalui stored procedure PostgreSQL `submit_flashcard_review` dengan proteksi `idempotency_key` (UUID v4) dan concurrency token (`p_expected_updated_at`).

### 5. 📊 Statistik & Progres Nyata
- Dashboard statistik belajar:
  - Total kartu yang dipelajari.
  - Jumlah kartu yang jatuh tempo hari ini (*Due Today*).
  - Akurasi retensi hafalan (*Mastery Rate*).
  - Riwayat sesi review terakhir.

---

## 🧠 Algoritma Spaced Repetition (SM-2)

RecallMe mengimplementasikan algoritma standar industri **SuperMemo SM-2** murni di lapisan Domain (`Sm2Scheduler`):

### Skala Penilaian:
| Rating | Kualitas | Repetisi | Interval Baru | Dampak Ease Factor (EF) |
|---|---|---|---|---|
| **Again (1)** | Lupa sama sekali | Reset ke 0 | 1 Hari | EF turun drastis (-0.54) |
| **Hard (3)** | Ingat dengan susah payah | +1 | 1 hari (rep 1), 6 hari (rep 2), atau `round(I * 1.2)` | EF turun (-0.14) |
| **Good (4)** | Ingat dengan baik | +1 | 1 hari (rep 1), 6 hari (rep 2), atau `round(I * EF)` | EF tetap (+0.00) |
| **Easy (5)** | Sangat mudah dihafal | +1 | 1 hari (rep 1), 6 hari (rep 2), atau `round(I * EF * 1.3)` | EF naik (+0.10) |

- **Batas Bawah Ease Factor:** $EF \ge 1.3$ (mencegah *ease hell*).
- **Formula Penyesuaian EF:**
  $$EF' = EF + (0.1 - (5 - q) \times (0.08 + (5 - q) \times 0.02))$$

---

## 🎨 Desain & UI/UX (Functional Neo-Brutalism)

Mengacu pada spesifikasi desain `docs/DESIGN.md` v1.1:
- **Canvas Utama:** Warm cream canvas (`#FFF6EC`).
- **Surface:** Off-white card surface (`#FFFCF7`).
- **Ink & Border:** Near-black (`#171717`) dengan ketebalan border tegas 2.0–3.0dp.
- **Hard Shadow:** Offset box shadow tanpa blur (`Offset(3, 3)` atau `Offset(4, 4)`).
- **Aksen Fungsional:**
  - 🟡 *Primary CTA:* Vibrant Yellow (`#FFD928`)
  - 🔴 *Again / Destructive:* Coral (`#FF6B6B`)
  - 🟠 *Hard:* Orange (`#FF9F43`)
  - 🟢 *Good:* Teal / Cyan (`#20BF6B` / `#00B894`)
  - 🟣 *Easy:* Purple / Lavender (`#A55EEA` / `#D6C7FF`)
  - 🔵 *Accent / Info:* Sky Blue (`#45AAF2`)
- **Tipografi:** Space Grotesk (Header/Display) dan Inter (Body/UI).
- **Aksesibilitas:** Minimum target sentuh 48dp, kontras WCAG AA, dan penanganan overflow responsif.

---

## 🏗️ Arsitektur Proyek

RecallMe dibangun menggunakan **Clean Architecture** berbasis fitur (*Feature-First*):

```
lib/
├── app/
│   ├── app.dart                   # Root MaterialApp & Theme configuration
│   └── router.dart                # GoRouter dengan Auth Guard reactive listeners
├── core/
│   ├── config/
│   │   └── supabase_config.dart   # Inisialisasi Supabase aman via --dart-define
│   ├── theme/
│   │   ├── app_colors.dart        # Neo-Brutalism color palette tokens
│   │   ├── app_decorations.dart   # Hard shadows, borders, brutal boxes
│   │   ├── app_spacing.dart       # 4dp spacing grid & radii tokens
│   │   ├── app_text_styles.dart   # Space Grotesk & Inter typography
│   │   └── app_theme.dart         # ThemeData assembly
│   ├── utils/
│   │   └── uuid_generator.dart    # RFC 4122 v4 UUID generator
│   └── widgets/
│       ├── app_button.dart        # Neo-Brutalist interactive button
│       ├── app_text_field.dart    # Neo-Brutalist text input
│       └── brutal_card.dart       # Neo-Brutalist container card
└── features/
    ├── auth/                      # Supabase Auth, mapping username, validators
    ├── decks/                     # CRUD Deck & library list
    ├── flashcards/                # CRUD Flashcard & form editor
    ├── home/                      # Dashboard beranda & ringkasan deck
    ├── navigation/                # Bottom Navigation Bar
    ├── profile/                   # Akun profil & tombol Keluar (Sign Out)
    ├── stats/                     # Metrik analitik & riwayat review
    ├── study/                     # Study Engine, SM-2 Scheduler & Atomic RPC
    └── welcome/                   # Splash / Onboarding screen
```

Setiap fitur terbagi menjadi 4 lapisan terpisah:
- **Presentation:** Layar (*screens*), *widgets*, dan *form state*.
- **Application:** State notifier / controller Riverpod.
- **Domain:** Data models, validator bisnis, dan pure Dart logic (`Sm2Scheduler`).
- **Data:** Repository yang berkomunikasi dengan Supabase / fallback ke Mock jika belum terkonfigurasi.

---

## 🗄️ Struktur Database & Keamanan (Supabase)

Migrasi database SQL tersimpan rapi pada direktori `supabase/migrations/`:

### 1. `001_create_core_tables.sql`
- `profiles`: Menyimpan profil pengguna yang disinkronkan otomatis dari Supabase Auth melalui trigger `on_auth_user_created`.
- `decks`: Menyimpan deck kartu milik pengguna.
- `flashcards`: Menyimpan kartu pertanyaan, jawaban, dan parameter algoritma SM-2 (`repetitions`, `interval_days`, `ease_factor`, `next_review_at`, `last_review_at`).
- `review_logs`: Menyimpan riwayat setiap review untuk keperluan analitik.

### 2. `002_enable_rls_and_grants.sql`
- **Row-Level Security (RLS)** aktif 100% di semua tabel.
- Menggunakan `auth.uid() = user_id` sehingga setiap pengguna hanya dapat membaca, mengubah, dan menghapus datanya sendiri.

### 3. `003_create_submit_review_rpc.sql`
- Stored procedure `public.submit_flashcard_review` untuk menjalankan update kartu dan insert log review secara atomik (dalam 1 transaksi).
- Mencegah *race condition* dan duplikasi submit dengan `p_idempotency_key` dan pengecekan token konkurensi `p_expected_updated_at`.

---

## 🚀 Persiapan & Instalasi

### Prasyarat
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi 3.50.0 atau lebih baru)
- [Dart SDK](https://dart.dev/get-dart) (versi 3.14.0 atau lebih baru)
- Perangkat Android fisik / emulator atau Google Chrome

### Langkah Instalasi
1. **Clone repository ini:**
   ```bash
   git clone https://github.com/tubagusbudis/RecallMe-MobileApp.git
   cd RecallMe-MobileApp
   ```

2. **Pasang dependency:**
   ```bash
   flutter pub get
   ```

---

## 💻 Menjalankan Aplikasi

Aplikasi mendukung 2 mode eksekusi:

### A. Mode Terhubung ke Database Supabase (Production / Live)
Suntikkan kredensial Supabase secara aman menggunakan `--dart-define` (tanpa hardcode di dalam file kode sumber):

```bash
flutter run \
  --dart-define=SUPABASE_URL="https://your-project.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="your-anon-key"
```

> ⚠️ **Penting:** Jangan pernah menggunakan atau memasukkan Supabase *Service Role Key* ke dalam client Flutter. Gunakan selalu *Anon / Publishable Key*.

### B. Mode Mock Offline (Tanpa Backend / Testing)
Jika Anda menjalankan aplikasi tanpa argumen `--dart-define`, RecallMe akan secara otomatis beralih ke **Mock Repository** in-memory:

```bash
flutter run
```

Pada mode ini, Anda dapat langsung mencoba registrasi, login, membuat deck, menambah kartu, dan menjalankan sesi belajar tanpa memerlukan setup database terlebih dahulu.

---

## 🧪 Pengujian Otomatis (Testing)

Proyek ini dilengkapi dengan **65 automated test suites** mencakup unit test, domain logic test, repository test, dan widget/navigation test:

```bash
# Menjalankan seluruh test suite
flutter test

# Menjalankan linter & static analysis
flutter analyze

# Memformat kode sesuai standar Dart
dart format .
```

### Lingkup Pengujian:
- ✅ **SM-2 Scheduler Test:** Menghitung transisi interval dan Ease Factor untuk semua rating (*Again, Hard, Good, Easy*).
- ✅ **Auth Validator Test:** Memverifikasi kriteria password, username, dan mapping email internal.
- ✅ **Repository CRUD Test:** Pengujian Create, Read, Update, Delete untuk Decks, Flashcards, dan Review RPC.
- ✅ **Welcome Screen & Responsiveness Test:** Memastikan tidak ada *RenderFlex overflow* pada layar `360x800` dan `390x844`.
- ✅ **Navigation & Auth Guard Test:** Memverifikasi pengalihan rute unauthenticated/authenticated secara reaktif.

---

## 👨‍💻 Kontributor & Lisensi

Dibuat dengan dedikasi oleh **Tubagus Budi S** sebagai aplikasi *smart memory training* yang menyenangkan, terbukti secara ilmiah, dan berdaya guna tinggi.

Proyek ini dilisensikan di bawah lisensi [MIT](LICENSE).

---

<p align="center">
  <b>RecallMe</b> • <i>Learn today, remember tomorrow.</i>
</p>
