# SMART TES IQ — Catatan Rilis 2.2.2 (build 12)

Tanggal: 7 September 2026
Versi sebelumnya: 2.2.1+11
Jenis rilis: perbaikan bug (hotfix ANR)

---

## Ringkasan

Rilis ini memperbaiki satu bug yang membuat aplikasi **berhenti merespons total (ANR)** saat memainkan
game **Math Rush** pada level Sedang dan Sulit. Bug ini adalah penyumbang ANR terbesar di Play Console
pada versi 2.2.1 (tercatat pada entri `_MathRushGameScreenState._generateQuestion` dan `_Random.nextInt`).

Tidak ada perubahan fitur, tampilan, kontrak API, maupun skema database di rilis ini.

---

## Perbaikan

### Math Rush berhenti merespons saat soal pengurangan menghasilkan nilai minus

**Gejala bagi pengguna.** Saat bermain Math Rush level Sedang atau Sulit, aplikasi tiba-tiba membeku —
soal tidak berganti, tombol tidak bisa ditekan, dan Android menampilkan dialog "Aplikasi tidak merespons".
Terjadi secara acak, biasanya setelah beberapa soal terjawab benar.

**Penyebab.** Pada level Sedang dan Sulit, soal pengurangan bisa menghasilkan jawaban negatif
(misalnya `25 - 47 = -22`), sementara level Mudah sudah mencegahnya. Rutin pembuat 4 pilihan jawaban
hanya menerima kandidat bernilai nol atau positif. Ketika jawaban benarnya bernilai −9 atau lebih kecil,
tidak ada satu pun kandidat pengecoh yang lolos, sehingga perulangan pencari pilihan jawaban berjalan
selamanya di UI thread dan aplikasi membeku permanen.

**Frekuensi (simulasi 100.000 soal pengurangan):**

| Level | Jawaban minus | Yang berujung aplikasi membeku |
|---|---|---|
| Sedang | 9,32 % | 5,05 % |
| Sulit | 9,03 % | 6,72 % |

**Perbaikan.** Dua lapis:

1. Pencegahan hasil minus pada operasi pengurangan kini berlaku di **semua level**, bukan hanya level
   Mudah. Bilangan yang lebih besar selalu ditempatkan di depan, jadi jawabannya tidak pernah negatif.
2. Perulangan pembuat pilihan jawaban diberi batas percobaan dan penyelesai berurutan, sehingga secara
   matematis dijamin selalu berhenti. Ini menjadi jaring pengaman kalau di kemudian hari ada level atau
   rumus soal baru yang menghasilkan nilai di luar dugaan.

**Dampak ke pengguna.** Pada level Sedang dan Sulit, soal pengurangan kini selalu berjawaban nol atau
positif — sama seperti perilaku level Mudah yang sudah berjalan sejak awal. Skor, poin per level, durasi
permainan, dan data tersimpan tidak berubah.

**Berkas yang diubah:** `lib/Screens/math_rush_game_screen.dart`

---

## Perubahan konfigurasi build (tidak memengaruhi pengguna)

Build release sempat gagal di mesin pengembang dan dibetulkan lewat `android/gradle.properties`:

- `kotlin.incremental=false` — proyek berada di drive `D:` sedangkan pub cache di `C:`. Kotlin
  incremental compiler gagal menghitung path relatif lintas-drive di Windows
  (`IllegalArgumentException: different roots`) sehingga daemon compile mati sebelum build selesai.
- `org.gradle.jvmargs` diturunkan dari `-Xmx8G -XX:MaxMetaspaceSize=4G` menjadi
  `-Xmx4G -XX:MaxMetaspaceSize=1G`, ditambah `kotlin.daemon.jvmargs=-Xmx2G`. Mesin ini punya RAM 15,8 GB
  dengan sisa bebas sekitar 4,7 GB, sehingga permintaan 8 GB membuat daemon Gradle dan AAPT2 mati.

Berkas asli dicadangkan di `android/gradle.properties.bak-20260907`.

---

## Verifikasi yang sudah dilakukan

- `flutter analyze lib/Screens/math_rush_game_screen.dart` — bersih; hanya menyisakan satu info
  `withOpacity` deprecated yang sudah ada sejak sebelum perubahan ini.
- Simulasi logika lama membuktikan perulangan tidak pernah berhenti untuk jawaban ≤ −9.
- Simulasi logika baru untuk seluruh nilai jawaban −500 sampai 5000: semuanya menghasilkan tepat 4
  pilihan dan selalu memuat jawaban yang benar.
- `flutter build appbundle --release` berhasil; `versionName` di dalam bundle terkonfirmasi `2.2.2`.

**Belum diuji manual di perangkat.** Uji ini yang paling meyakinkan: mainkan Math Rush level Sulit
selama satu putaran penuh 60 detik dan pastikan tidak ada pembekuan.

---

## Belum tuntas

Entri ANR `android.os.MessageQueue.nativePollOnce` (7 kejadian di 2.2.1) belum bisa ditelusuri
penyebabnya — jejak itu hanya menunjukkan main thread sedang menunggu, tanpa memberi tahu siapa yang
menahannya. Sebagian di antaranya kemungkinan besar kejadian yang sama dengan bug di atas yang
tertangkap pada titik berbeda. Perlu dipantau ulang setelah 2.2.2 tersebar.

---

## Teks untuk kolom "Apa yang baru" di Play Store

**Indonesia**

```
Perbaikan bug:
• Memperbaiki masalah aplikasi berhenti merespons saat bermain Math Rush pada level Sedang dan Sulit.
• Soal pengurangan di semua level kini tidak lagi menghasilkan jawaban bernilai minus.
```

**English**

```
Bug fixes:
• Fixed the app freezing during Math Rush on Medium and Hard difficulty.
• Subtraction questions no longer produce negative answers on any difficulty.
```
