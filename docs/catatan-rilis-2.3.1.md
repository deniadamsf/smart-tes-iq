# Catatan Rilis — SMART TES IQ 2.3.1 (15)

Sudah ada di Play Store: 2.2.1, 2.2.2, lalu 2.3.0.

## Judul rilis

Indonesia:

```
2.3.1 (15) — Tantangan Harian & Papan Peringkat
```

English:

```
2.3.1 (15) — Daily Challenge & Leaderboards
```

## What's new — Indonesia (id-ID)

```
TANTANGAN IQ HARIAN
30 soal baru tiap hari: verbal, angka, logika, spasial, dan gambar. Semua peserta dapat soal yang sama, jadi persaingannya adil.

PAPAN PERINGKAT
Lihat posisimu di papan Harian, IQ Reguler, dan IQ PRO. Begitu kamu mengerjakan tes, peringkatmu langsung ikut tampil.

ANGKA IQ KAMU TETAP PRIVAT
Peserta lain hanya melihat nama dan posisi peringkatmu. Angka IQ tidak pernah ditampilkan ke siapa pun — hanya kamu yang tahu, dan hanya ikut terbawa kalau kamu sendiri yang membagikan kartu peringkat.

NAMA TAMPILAN BISA DIGANTI
Awalnya papan memakai nama akun Google kamu. Ganti kapan saja dengan nama pilihanmu sendiri, atau sembunyikan diri sepenuhnya dari papan lewat satu saklar.

ANALISA AI
Ulasan mendalam kekuatanmu tiap selesai tantangan, plus kalender riwayat peringkat harian.

PERBAIKAN
Tampilan grafik dan perhitungan kredit.
```

## What's new — English (en-US)

```
DAILY IQ CHALLENGE
30 fresh questions daily: verbal, numbers, logic, spatial, and images. Everyone gets the same set, so the race is fair.

LEADERBOARDS
See where you stand on the Daily, Regular IQ, and PRO IQ boards. Take a test and your rank shows up right away.

YOUR IQ NUMBER STAYS PRIVATE
Other players only see your name and your rank. Your IQ number is never shown to anyone — only you can see it, and it only travels if you share your own rank card.

CHANGE YOUR DISPLAY NAME
The board starts with your Google account name. Change it to a name of your own at any time, or hide yourself from the board entirely with a single switch.

AI ANALYSIS
An in-depth read on your cognitive strengths after each challenge, plus a calendar of your daily ranks.

FIXES
Chart layout and credit calculation.
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
