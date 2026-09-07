<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\SyncController;
use App\Http\Controllers\DailyChallengeController;

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
});