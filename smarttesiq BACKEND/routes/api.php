<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\SyncController;

Route::post('/auth/google', [AuthController::class, 'googleLogin']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/sync', [SyncController::class, 'syncData']);
    Route::get('/user-data', [SyncController::class, 'getUserData']);
    
    // JALUR BARU UNTUK MENGHAPUS CHAT DI SERVER
    Route::delete('/clear-chats', [SyncController::class, 'clearChats']);
});