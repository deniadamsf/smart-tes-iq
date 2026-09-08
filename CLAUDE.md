# SMART TES IQ — Aturan Agent

Proyek ini terdiri dari dua sub-proyek dalam satu folder:

| Folder | Isi |
|---|---|
| `smart_tes_iq APK/` | Aplikasi Flutter (Dart ^3.11.0), rilis `2.2.2` di Play Store; berikutnya `2.3.0+14` |
| `smarttesiq BACKEND/` | API Laravel 12 (PHP ^8.2, Sanctum 4, MySQL) |
| `u731410318_smart_tes_iq.sql` | Dump skema + data produksi (~1,2 MB) |

Folder ini sudah di bawah git, remote privat di `github.com/deniadamsf/smart-tes-iq` (branch `main`). Perubahan pada file terlacak bisa dikembalikan lewat `git checkout`.

Yang **tidak** terlindungi git karena sengaja dikecualikan di `.gitignore`: keystore Android (`upload-keystore.jks`, `key.properties`), kedua `.env`, dump SQL produksi, dan `smarttesiq BACKEND/public/gemini_proxy.php` (memegang API key Gemini di sisi server — ini disengaja, jangan diubah jadi membaca `.env` dan jangan dimasukkan ke repo). File-file itu tidak punya cadangan di git.

---

## 1. Hirarki model

**Opus 5 adalah otak.** Semua thread utama, perencanaan, keputusan, dan review berjalan di Opus 5. Sonnet 5 dan Haiku 4.5 adalah model turunan — dipakai lewat subagent untuk pekerjaan yang sudah jelas jalurnya.

```
                 ┌──────────────────────┐
                 │   OPUS 5  (otak)     │  thread utama, rencana, keputusan
                 └──────────┬───────────┘
              ┌─────────────┼─────────────┐
              ▼             ▼             ▼
        arsitek       flutter-dev      scout
        reviewer      laravel-dev      db-scout
        (Opus 5)      (Sonnet 5)     (Haiku 4.5)
```

### Pemilihan model otomatis

Thread utama **selalu Opus 5** (`model: "opus"` di `.claude/settings.json`). Penurunan ke Sonnet/Haiku terjadi otomatis dengan mendelegasikan ke subagent — tiap subagent sudah mengunci modelnya sendiri di frontmatter, jadi tidak perlu ada yang memilih model secara manual.

Aturan routing yang dipakai Opus 5 saat memutuskan delegasi:

| Sifat pekerjaan | Model | Cara |
|---|---|---|
| Ambigu, lintas-lapis, ada trade-off, akar bug belum jelas, menyentuh keamanan/kontrak API/skema DB | **Opus 5** | kerjakan sendiri, atau `arsitek` / `reviewer` |
| Rencana sudah jelas, tinggal menulis kode di satu sub-proyek | **Sonnet 5** | `flutter-dev` atau `laravel-dev` |
| Pencarian, pendataan, lookup skema — jawaban mekanis, konteksnya besar | **Haiku 4.5** | `scout` atau `db-scout` |

Fallback saat model utama penuh: Opus 5 → Sonnet 5 → Haiku 4.5.

**Yang tidak boleh diturunkan ke Sonnet/Haiku:** keputusan arsitektur, perubahan kontrak API, migration produksi, apa pun yang menyentuh autentikasi atau data user, dan keputusan "apakah ini aman untuk dirilis".

**Jangan spawn subagent kalau tidak perlu.** Setiap subagent mulai dari nol dan harus menurunkan ulang konteks yang sudah ada di thread utama. Kerjakan langsung kalau pekerjaannya muat dikerjakan sendiri; delegasikan kalau memang menghemat konteks (sapuan file besar) atau memang pekerjaan mekanis paralel.

---

## 2. Izin

Untuk proyek ini semua operasi kerja **sudah disetujui** — tidak perlu bertanya sebelum membaca, mengedit, atau menjalankan perkakas proyek (`flutter`, `dart`, `php`, `artisan`, `composer`, `npm`, `git`). Diatur di `.claude/settings.json`.

Yang tetap diblokir, dan alasannya:

- `rm -rf` ke root/home — git hanya melindungi file terlacak; keystore, `.env`, dan dump SQL tidak ada di dalamnya dan hilang selamanya.
- `git push --force`, `git reset --hard` — menghapus kerja yang belum tersimpan.
- `php artisan migrate:fresh`, `db:wipe` — menghapus database.
- Membaca `.env` — berisi kredensial produksi.

Tetap konfirmasi dulu untuk: deploy, push ke remote, menaikkan version/build number, apa pun yang menyentuh database produksi, dan menghapus file yang tidak kamu buat sendiri.

---

## 3. Aturan teknis

**Aplikasi sudah rilis di perangkat user (2.2.1 dan 2.2.2).** Ini membatasi dua hal:

1. **Kontrak API** — mengubah nama field atau bentuk response di `routes/api.php` akan merusak client lama. Tambah field baru, jangan ubah atau hapus yang lama tanpa jalur kompatibilitas.
2. **Skema SQLite lokal** — perubahan di `lib/helpers/database_helper.dart` butuh jalur upgrade untuk user lama, bukan drop-create.

Lainnya:

- Soal tes ada di `lib/data/*_data.dart`, bukan di dalam widget. Varian `*_pro_*` adalah versi berbayar dari tes yang sama.
- Sebelum membuat screen tes baru, baca screen sejenis yang sudah ada dan ikuti polanya.
- Endpoint yang butuh identitas user: lindungi dengan `auth:sanctum`, ambil user dari `$request->user()` — jangan dari body request.
- Verifikasi setelah mengubah kode: `flutter analyze` (Flutter), `vendor/bin/pint --dirty` + `php artisan test` (Laravel). Jalankan dari dalam folder sub-proyek masing-masing.
- Jangan sentuh: `build/`, `vendor/`, `node_modules/`, `.dart_tool/`, `lib.zip`, `backend.zip`.
- Dump SQL jangan dibaca utuh — pakai `grep`, atau delegasikan ke `db-scout`.

---

## 4. Backend produksi di hosting

Selain salinan lokal `smarttesiq BACKEND/`, ada **backend asli yang sedang melayani user** di hosting Hostinger. Host SSH-nya sudah terdaftar di `~/.ssh/config` dengan alias **`hostinger`** (`153.92.8.198:65002`, user `u731410318` — sama dengan nama database produksi).

**Satu-satunya folder yang boleh disentuh:**

```
/home/u731410318/domains/cellanoma.my.id/public_html/smarttesiq
```

(`~/public_html` adalah symlink ke domain lain yang kosong — bukan lokasi proyek ini. Domain aplikasi: `smarttesiq.cellanoma.my.id`, base URL API `https://smarttesiq.cellanoma.my.id/public/api`.)

Struktur Laravel di dalamnya (`app/`, `routes/`, `public/`, dsb.) dipetakan lewat `ls` pada koneksi pertama — jangan berasumsi tata letaknya sama persis dengan salinan lokal.

**Tetangganya di `domains/cellanoma.my.id/public_html/` bukan milik proyek ini** dan tidak boleh dibaca, diubah, apalagi dihapus: `zenvi/`, `clara/`, `persona/`, `public/`, `files/`, serta file di akar (`.htaccess`, `app-ads.txt`, `default.php`, `kebijakan-privasi.html`). `.htaccess` di akar mengatur routing seluruh domain — mengubahnya bisa mematikan semua situs sekaligus, bukan cuma SMART TES IQ.

Akses ini juga **hanya untuk alias `hostinger`**. Host lain di config SSH (`mywowin`, `rajakuvps`) milik proyek lain dan tidak boleh disentuh dari sesi ini.

### Yang berubah dibanding kerja lokal

Di lokal ada git sebagai jaring pengaman. Di server produksi **tidak ada** — tidak ada git, tidak ada staging, tidak ada undo, dan salah edit berarti **aplikasi user langsung rusak**. Perlakukan setiap perintah ke `hostinger` seperti perintah yang tidak bisa ditarik kembali.

### Urutan wajib sebelum mengubah file produksi

1. **Petakan dulu.** `ls`, `stat`, baca file targetnya. Pastikan kamu tahu file mana yang dipakai dan mana sisa lama.
2. **Bandingkan dengan lokal.** Salinan di `smarttesiq BACKEND/` belum tentu sama dengan produksi. Cek selisihnya sebelum menimpa apa pun — kalau produksi lebih baru, salinan lokal yang harus menyesuaikan, bukan sebaliknya.
3. **Backup file yang akan diubah**, di server itu sendiri: `cp file.php file.php.bak-YYYYMMDD`. Sebutkan nama backup-nya ke user.
4. **Ubah seminimal mungkin.** Satu perbaikan satu kali jalan. Jangan sekalian merapikan hal lain.
5. **Verifikasi setelah upload** — minimal `php -l` pada file yang diubah, lalu panggil endpoint terkait dan pastikan responsnya benar. Belum diverifikasi berarti belum selesai.
6. **Laporkan**: file apa, backup di mana, cara mengembalikannya kalau ternyata rusak.

### Tetap wajib konfirmasi user

- Menimpa atau menghapus file apa pun di produksi.
- `php artisan` apa pun yang menulis (`migrate`, `cache:clear`, `config:cache`, `queue:restart`).
- Menyentuh `.env` produksi — **jangan dibaca, jangan disalin, jangan ditampilkan**.
- Apa pun yang menyentuh database: tidak ada `mysql`, `mysqldump`, atau migration lewat sesi ini. Kalau butuh data, minta user yang mengambilkan.
- Menyentuh apa pun di luar `domains/cellanoma.my.id/public_html/smarttesiq/` — folder tetangga dan file di akar `public_html/` sekalipun hanya untuk dilihat sekilas, bukan diubah.

### Pembagian model

Pekerjaan di produksi **tidak boleh didelegasikan ke `laravel-dev` (Sonnet 5) atau agent mana pun**. Subagent tidak punya konteks percakapan ini dan tidak tahu file mana yang sudah di-backup. Semua sentuhan ke server dikerjakan sendiri oleh Opus 5 di thread utama. `laravel-dev` tetap untuk salinan lokal saja.

---

## 5. Komunikasi

Bahasa Indonesia. Laporkan hasil apa adanya: kalau test gagal, tempelkan outputnya; kalau ada bagian yang dilewati, sebutkan bagian mana dan kenapa. Jangan bilang "selesai" untuk pekerjaan yang belum diverifikasi.
