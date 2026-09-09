# Catatan Rilis — SMART TES IQ 2.3.2 (16)

Sudah ada di Play Store: 2.2.1, 2.2.2, lalu 2.3.0. Build 15 sudah terpakai,
sehingga rilis ini memakai 2.3.2 (16).

## Judul rilis

Indonesia:

```
2.3.2 (16) — Tantangan Harian & Papan Peringkat
```

English:

```
2.3.2 (16) — Daily Challenge & Leaderboards
```

Kolom "What's new" Play Store dibatasi **500 karakter per bahasa**, jadi
kedua teks di bawah sengaja pendek. Jangan tambah baris tanpa menghitung
ulang — kalau lewat, Play Console menolak simpan.

## What's new — Indonesia (id-ID) — 415 karakter

```
TANTANGAN IQ HARIAN
30 soal baru tiap hari. Semua peserta dapat soal yang sama.

PAPAN PERINGKAT
Harian, IQ Reguler, dan IQ PRO. Selesai tes, peringkatmu langsung tampil.

ANGKA IQ TETAP PRIVAT
Peserta lain cuma melihat nama dan peringkatmu. Angka IQ hanya kamu yang tahu.

NAMA TAMPILAN
Awalnya memakai nama akun Google. Ganti kapan saja, atau sembunyikan diri dari papan.

PERBAIKAN
Grafik dan perhitungan kredit.
```

## What's new — English (en-US) — 383 karakter

```
DAILY IQ CHALLENGE
30 fresh questions daily. Everyone gets the same set.

LEADERBOARDS
Daily, Regular IQ, and PRO IQ. Finish a test and your rank shows up.

YOUR IQ STAYS PRIVATE
Others only see your name and rank. The number is yours alone.

DISPLAY NAME
Starts with your Google account name. Change it anytime, or hide yourself from the board.

FIXES
Charts and credit calculation.
```

---

## Isi rilis ini

- Tantangan IQ Harian: 30 soal (24 gratis + 6 PRO), batas 15 menit,
  dinilai di server sehingga skornya tidak bisa dipalsukan.
- Layar aturan sebelum tes dimulai; hitungan waktu baru berjalan setelah
  user menekan tombol mulai, bukan saat layar dibuka.
- Pita nomor 1-30 supaya soal yang terlewat langsung terlihat.
- Kalender riwayat berisi peringkat harian di layar pengantar dan layar
  "sudah selesai hari ini".
- Tiga papan peringkat: Harian, IQ Reguler, dan IQ PRO.
- Kartu berbagi peringkat.
- Analisa AI hasil harian (~300 kata) memakai gemini-2.5-flash-lite.
- Banner iklan di bawah layar tantangan.
- Perbaikan rumus IQ Reguler: hasil tes PRO tidak lagi tercampur.
- Perbaikan overflow grafik di beranda dan profil.
- Perbaikan perhitungan kredit: saldo kini `diberikan - terpakai`.

### Perubahan papan peringkat (9 September 2026)

Tiga hal berikut mengubah perilaku yang sempat direncanakan di atas.
Catatan lama menyebut papan bersifat opt-in dan nama akun Google tidak
pernah dipakai — keduanya sudah tidak berlaku.

- **Semua peserta tampil.** Papan tidak lagi menyaring user yang belum
  mengisi nama. Selama nama tampilan belum dipilih, papan memakai
  `users.name` dari akun Google. Alasannya papan yang sepi membuat user
  kehilangan minat sebelum sempat memilih nama.
- **Angka IQ tidak dikirim ke siapa pun kecuali pemiliknya.** Baris
  peserta lain di response API tidak membawa angka IQ sama sekali, jadi
  tidak bisa dipanen dengan memanggil endpoint langsung.
- **Nama tampilan bisa diganti kapan saja**, lewat tombol di AppBar
  papan peringkat maupun dengan mengetuk nama di kartu peringkat sendiri
  — bukan hanya sekali saat pertama ikut.
- **Saklar "Sembunyikan saya dari papan"** (`users.sembunyi_dari_papan`).
  User yang menyalakannya hilang dari daftar DAN dari hitungan peserta,
  sehingga nomor peringkat orang lain tidak melompat.

## Sebelum mengunggah

- **Backend wajib naik lebih dulu.** Rilis ini butuh `LeaderboardController`,
  `User`, `DailyAttempt`, dan `routes/api.php` versi baru, serta migration
  `2026_09_09_000001_add_sembunyi_dari_papan_to_users_table` yang sudah
  dijalankan. Tanpa itu papan peringkat error.
- **Formulir Data Safety perlu disesuaikan.** Yang berubah dari
  pernyataan sebelumnya: nama akun Google **memang ditampilkan** kepada
  pengguna lain selama user belum memilih nama tampilan sendiri, dan
  papan peringkat **tidak lagi opt-in**. Yang tetap harus dinyatakan:
  angka IQ tidak pernah dibagikan ke pengguna lain, dan user bisa menarik
  diri sepenuhnya dari dalam aplikasi.
- Kebijakan privasi web (`smarttesiq.cellanoma.my.id/privacy.html`) dan
  teks privasi di dalam aplikasi sudah diperbarui mengikuti perubahan ini.
- Berkas:
  - `app-release.aab` — unggah ini ke Play Store
  - `app-release.apk` — untuk uji pasang langsung di perangkat
