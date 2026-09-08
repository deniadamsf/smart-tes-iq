<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Skor IQ yang sudah dihitung di muka, untuk papan peringkat.
 *
 * Menghitung ulang komposit seluruh user setiap kali papan dibuka akan
 * berat begitu jumlah user bertambah. Tabel ini diperbarui saat user
 * melakukan /sync, sehingga papan peringkat cukup jadi query indeks biasa.
 *
 * SENGAJA TIDAK memakai cache Laravel: driver cache di produksi diset ke
 * `database` tapi tabel `cache` tidak pernah dibuat, jadi Cache::remember()
 * akan langsung gagal. Indeks di tabel ini sudah cukup cepat.
 *
 * Tabel baru, tidak menyentuh test_results maupun users.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_iq_scores', function (Blueprint $table) {
            $table->foreignId('user_id')->primary()->constrained()->onDelete('cascade');

            // Dari tes kognitif GRATIS saja. Null kalau user belum pernah
            // mengerjakan satu pun — mereka tidak bisa diperingkat pada
            // dasar yang tidak pernah mereka kerjakan.
            $table->unsignedSmallInteger('iq_reguler')->nullable();

            // Dari 'Tes IQ Komprehensif (PRO)'. Null kalau belum pernah.
            $table->unsignedSmallInteger('iq_pro')->nullable();

            $table->timestamp('updated_at')->nullable();

            $table->index('iq_reguler');
            $table->index('iq_pro');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_iq_scores');
    }
};
