<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Menyimpan rekor tertinggi (High Score) 5 game Asah Otak per user:
 * anagram, stroop, math_rush, memory_match, sudoku.
 *
 * Aman dijalankan saat aplikasi live: kolom JSON nullable, tidak mengubah
 * kolom lama, dan APK versi lama mengabaikannya.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (! Schema::hasColumn('users', 'game_high_scores')) {
                $table->json('game_high_scores')->nullable()->after('sembunyi_dari_papan');
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'game_high_scores')) {
                $table->dropColumn('game_high_scores');
            }
        });
    }
};
