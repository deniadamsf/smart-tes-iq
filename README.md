# Smart Tes IQ

Aplikasi tes IQ dan logika dengan analisa AI. Tersedia di Google Play Store.

## Struktur Proyek

```
smart_tes_iq APK/    # Aplikasi Flutter (Android & iOS)
smarttesiq BACKEND/  # REST API (Laravel 12, PHP 8.2+)
docs/                # Catatan rilis & dokumen pendukung
```

## Tech Stack

**Mobile:**
- Flutter (Dart ^3.11.0)
- Firebase Auth & Core
- Google Sign-In
- Google AdMob & In-App Purchase
- Gemini AI (analisa hasil tes)
- SQLite (database lokal)
- Multi-bahasa (easy_localization)

**Backend:**
- Laravel 12 (PHP ^8.2)
- MySQL
- Laravel Sanctum

## Fitur

- Tes IQ dengan berbagai kategori (logika, spasial, klasifikasi, math rush)
- Analisa hasil tes menggunakan AI (Gemini)
- Tantangan harian & papan peringkat
- Login dengan Google / Firebase
- Multi-bahasa (Indonesia & English)
- In-App Purchase (premium)
- Iklan AdMob (versi gratis)
- Tanda tangan digital (signature)
- Share hasil tes

## Setup

### Flutter
```bash
cd "smart_tes_iq APK"
flutter pub get
flutter run
```

### Backend
```bash
cd "smarttesiq BACKEND"
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan serve
```

## Versi

Saat ini: **2.3.2+16** (Play Store)

## Lisensi

Proprietary — Seluruh hak cipta dilindungi.
