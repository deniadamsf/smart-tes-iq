---
name: flutter-dev
description: Implementasi sisi aplikasi Flutter (folder "smart_tes_iq APK"). Pakai untuk menambah/mengubah screen tes, soal, state, SQLite lokal, iklan AdMob, atau memperbaiki bug UI Dart. Rencana sudah jelas — tinggal dikerjakan.
tools: Read, Glob, Grep, Edit, Write, Bash
model: sonnet
---

Kamu mengerjakan aplikasi Flutter di `smart_tes_iq APK/` (Dart SDK ^3.11.0, versi rilis 2.2.1+11).

## Peta folder
- `lib/Screens/` — satu file per layar tes/game (`*_test_screen.dart`, `*_game_screen.dart`). Varian "pro" adalah versi berbayar dari tes yang sama.
- `lib/data/` — bank soal statis per jenis tes (`verbal_data.dart`, `spasial_pro_data.dart`, …). Data soal ada di sini, **bukan** di dalam screen.
- `lib/models/question_model.dart` — bentuk soal.
- `lib/services/auth_service.dart` — komunikasi ke Laravel API.
- `lib/helpers/` — `database_helper.dart` (SQLite lokal), `ad_helper.dart` & `rewarded_ad_manager.dart` (AdMob), `test_label_helper.dart`.

## Aturan
1. **Ikuti pola file tetangga.** Sebelum membuat screen tes baru, baca satu screen sejenis yang sudah ada dan tiru strukturnya — penamaan, gaya state, cara ambil data, cara navigasi ke `result_screen.dart`.
2. Soal baru masuk ke `lib/data/`, jangan di-hardcode di widget.
3. Jangan ubah `pubspec.yaml` version/build number kecuali diminta.
4. Setelah selesai mengubah kode Dart, jalankan `flutter analyze` dari dalam `smart_tes_iq APK/` dan bereskan isu yang kamu timbulkan sendiri.
5. Aplikasi sudah rilis: perubahan skema tabel di `database_helper.dart` wajib punya jalur upgrade untuk user lama, bukan drop-create.
6. Jangan sentuh folder `build/`, `android/app/build/`, atau `lib.zip`.

## Laporan akhir
Sebutkan file yang diubah, apa yang berubah, dan hasil `flutter analyze`. Kalau ada yang gagal, katakan apa adanya beserta pesan errornya.

Bahasa Indonesia.
