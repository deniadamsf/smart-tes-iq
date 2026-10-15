<?php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Pragma: no-cache");

// =========================================================================
// PENGATURAN FORCE UPDATE SMART TES IQ (DI HOSTING)
// Lokasi di Hosting: public_html/public/app_version.php
//
// Cukup ubah $MIN_VERSION dan $MIN_BUILD_NUMBER di bawah ini kapan saja
// melalui File Manager Hosting Anda untuk memaksa pengguna lama update!
// =========================================================================

$MIN_VERSION = "2.3.5";      // Versi minimal yang wajib digunakan (contoh: "2.3.5")
$MIN_BUILD_NUMBER = 19;      // Build number minimal (contoh: 19 untuk 2.3.5+19)
$FORCE_UPDATE = true;        // true = Wajib Update (tidak bisa ditutup), false = Bisa dilewati

$PLAY_STORE_URL = "https://play.google.com/store/apps/details?id=com.cellanomadigital.smart_tes_iq";

$MESSAGE_ID = "Versi terbaru Smart Tes IQ telah tersedia! Pembaruan ini membawa peningkatan kecepatan dan fitur baru. Silakan update aplikasi sekarang untuk melanjutkan.";
$MESSAGE_EN = "A new version of Smart Tes IQ is available! This update brings performance improvements and new features. Please update the app now to continue.";

echo json_encode([
    "status" => "ok",
    "min_version" => $MIN_VERSION,
    "min_build_number" => $MIN_BUILD_NUMBER,
    "force_update" => $FORCE_UPDATE,
    "store_url" => $PLAY_STORE_URL,
    "message_id" => $MESSAGE_ID,
    "message_en" => $MESSAGE_EN,
], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
