<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\DailyChallengeController;
use App\Http\Controllers\LeaderboardController;
use App\Http\Controllers\SyncController;
use Illuminate\Support\Facades\Route;

Route::post('/auth/google', [AuthController::class, 'googleLogin']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/sync', [SyncController::class, 'syncData']);
    Route::get('/user-data', [SyncController::class, 'getUserData']);

    // JALUR BARU UNTUK MENGHAPUS CHAT DI SERVER
    Route::delete('/clear-chats', [SyncController::class, 'clearChats']);

    // ---------------------------------------------------------------
    // TANTANGAN IQ HARIAN
    // Semuanya jalur BARU. Tidak ada endpoint lama yang diubah, jadi
    // client 2.2.1 yang beredar tidak terpengaruh sama sekali.
    // ---------------------------------------------------------------
    Route::post('/daily/start', [DailyChallengeController::class, 'start']);
    Route::post('/daily/submit', [DailyChallengeController::class, 'submit']);
    Route::get('/daily/me', [DailyChallengeController::class, 'me']);

    // ---------------------------------------------------------------
    // PAPAN PERINGKAT (Fase 2)
    // Jalur baru juga. Semua peserta yang punya skor tampil; yang belum
    // memilih nama sendiri dipajang dengan nama akun Google-nya, dan bisa
    // menarik diri lewat /leaderboard/sembunyi.
    // ---------------------------------------------------------------
    Route::get('/leaderboard/daily', [LeaderboardController::class, 'daily']);
    Route::post('/leaderboard/display-name', [LeaderboardController::class, 'setDisplayName']);
    Route::post('/leaderboard/sembunyi', [LeaderboardController::class, 'setSembunyi']);
    Route::get('/leaderboard/reguler', [LeaderboardController::class, 'reguler']);
    Route::get('/leaderboard/pro', [LeaderboardController::class, 'pro']);
});
