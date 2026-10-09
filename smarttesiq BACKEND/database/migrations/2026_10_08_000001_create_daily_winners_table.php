<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Tabel rekap Juara Harian (Top IQ Daily).
 *
 * Tabel BARU, non-destruktif: tidak mengubah struktur tabel yang ada.
 * Setiap tanggal tantangan yang telah selesai (lampau) memiliki 1 pemenang
 * peringkat 1 resmi yang dicatat di sini.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('daily_winners', function (Blueprint $table) {
            $table->id();
            $table->date('challenge_date')->unique();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->unsignedTinyInteger('correct');
            $table->unsignedTinyInteger('total')->default(30);
            $table->unsignedInteger('duration_ms');
            $table->unsignedSmallInteger('iq_harian')->nullable();
            $table->timestamps();

            $table->index('user_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('daily_winners');
    }
};
