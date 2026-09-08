# Catatan Rilis — SMART TES IQ 2.3.0 (14)

Sudah ada di Play Store: 2.2.1, lalu 2.2.2 (perbaikan Math Rush).

Naik ke 2.3.0 karena rilis ini menambah fitur besar, bukan perbaikan kecil.
Nomor build 14 dipilih dengan sedikit ruang lebih di atas build 2.2.2.
**Kalau build number 2.2.2 ternyata 14 atau lebih, angka ini harus dinaikkan
lagi** — Play Store menolak versionCode yang tidak lebih tinggi.

## Nama rilis (Play Console, internal)

```
2.3.0 (14) — Tantangan Harian & Papan Peringkat
```

## What's new — Indonesia (id-ID)

```
TANTANGAN IQ HARIAN
30 soal baru tiap hari: verbal, angka, logika, spasial, dan gambar. Semua peserta dapat soal yang sama, jadi persaingannya adil.

PAPAN PERINGKAT
Lihat posisimu di papan Harian, IQ Reguler, dan IQ PRO. Nama tampilan kamu pilih sendiri; nama akun Google tidak pernah ditampilkan.

ANALISA AI
Ulasan kekuatan kognitifmu tiap selesai tantangan harian.

BERBAGI
Bagikan peringkatmu sebagai kartu.

PERBAIKAN
Tampilan grafik di beranda dan profil, serta perhitungan kredit.
```

## What's new — English (en-US)

```
DAILY IQ CHALLENGE
30 fresh questions daily: verbal, numbers, logic, spatial, and images. Everyone gets the same set, so the race is fair.

LEADERBOARDS
See where you stand on the Daily, Regular IQ, and PRO IQ boards. You pick your own display name; your Google name is never shown.

AI ANALYSIS
A read on your cognitive strengths after each daily challenge.

SHARING
Share your rank as a card.

FIXES
Chart layout on home and profile, plus credit calculation.
```

---

## Isi rilis ini

- Tantangan IQ Harian: 30 soal (24 gratis + 6 PRO), batas 15 menit,
  dinilai di server sehingga skornya tidak bisa dipalsukan.
- Tiga papan peringkat: Harian, IQ Reguler, dan IQ PRO.
- Nama tampilan bersifat opt-in; `users.name` dari akun Google tidak
  pernah dipakai di papan mana pun.
- Kartu berbagi peringkat.
- Analisa AI hasil harian memakai gemini-2.5-flash-lite.
- Perbaikan rumus IQ Reguler: hasil tes PRO tidak lagi tercampur.
- Perbaikan overflow grafik di beranda dan profil.
- Perbaikan perhitungan kredit: saldo kini `diberikan - terpakai`,
  sehingga tidak bisa dipulihkan penuh setelah dipakai.

## Sebelum mengunggah

- Backend sudah terpasang lebih dulu di produksi, jadi client lama yang
  masih beredar tetap berjalan normal selama masa rollout bertahap.
- Kebijakan privasi dan formulir Data Safety perlu menyebut bahwa nama
  tampilan pilihan user ditampilkan ke pengguna lain lewat papan
  peringkat. Nama akun Google tidak pernah ditampilkan.
- Berkas:
  - `app-release.aab` — unggah ini ke Play Store
  - `app-release.apk` — untuk uji pasang langsung di perangkat
