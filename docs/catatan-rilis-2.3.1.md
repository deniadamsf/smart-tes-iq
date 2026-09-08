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
Lihat posisimu di papan Harian, IQ Reguler, dan IQ PRO. Nama tampilan kamu pilih sendiri; nama akun Google tidak pernah ditampilkan.

ANALISA AI
Ulasan mendalam kekuatanmu tiap selesai tantangan, plus kalender riwayat peringkat harian.

BERBAGI
Bagikan peringkatmu sebagai kartu.

PERBAIKAN
Tampilan grafik dan perhitungan kredit.
```

## What's new — English (en-US)

```
DAILY IQ CHALLENGE
30 fresh questions daily: verbal, numbers, logic, spatial, and images. Everyone gets the same set, so the race is fair.

LEADERBOARDS
See where you stand on the Daily, Regular IQ, and PRO IQ boards. You pick your own display name; your Google name is never shown.

AI ANALYSIS
An in-depth read on your cognitive strengths after each challenge, plus a calendar of your daily ranks.

SHARING
Share your rank as a card.

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
- Nama tampilan bersifat opt-in; `users.name` dari akun Google tidak
  pernah dipakai di papan mana pun.
- Kartu berbagi peringkat.
- Analisa AI hasil harian (~300 kata) memakai gemini-2.5-flash-lite.
- Banner iklan di bawah layar tantangan.
- Perbaikan rumus IQ Reguler: hasil tes PRO tidak lagi tercampur.
- Perbaikan overflow grafik di beranda dan profil.
- Perbaikan perhitungan kredit: saldo kini `diberikan - terpakai`.

## Sebelum mengunggah

- Backend sudah terpasang lebih dulu di produksi, jadi client lama yang
  masih beredar tetap berjalan normal selama masa rollout bertahap.
- Kebijakan privasi dan formulir Data Safety perlu menyebut bahwa nama
  tampilan pilihan user ditampilkan ke pengguna lain lewat papan
  peringkat. Nama akun Google tidak pernah ditampilkan.
- Berkas:
  - `app-release.aab` — unggah ini ke Play Store
  - `app-release.apk` — untuk uji pasang langsung di perangkat
