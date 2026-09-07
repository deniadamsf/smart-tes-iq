<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Tabel untuk Tantangan IQ Harian.
 *
 * Ketiganya TABEL BARU — tidak ada ALTER pada tabel lama. Aman dijalankan
 * saat aplikasi live: client 2.2.1 tidak tahu tabel ini ada dan tidak
 * terpengaruh sama sekali.
 */
return new class extends Migration
{
    public function up(): void
    {
        // Bank soal. Dipindah ke server supaya KUNCI JAWABAN tidak pernah
        // ikut terkirim ke HP — syarat mutlak agar papan peringkat harian
        // tidak bisa dipalsukan.
        //
        // Efek samping yang menguntungkan: soal baru bisa ditambah lewat
        // INSERT tanpa perlu rilis ulang APK ke Play Store.
        Schema::create('question_bank', function (Blueprint $table) {
            $table->id();
            $table->enum('pool', ['free', 'pro']);
            $table->string('category', 32);          // verbal|deret|logika|spasial|klasifikasi
            $table->text('question_id')->nullable(); // teks Bahasa Indonesia
            $table->text('question_en')->nullable();
            $table->string('image_path')->nullable(); // aset lokal APK, bukan URL
            $table->json('options_id');
            $table->json('options_en');
            $table->char('answer', 1);               // SELALU satu huruf A-E
            $table->date('last_used_on')->nullable(); // untuk rotasi merata
            $table->unsignedInteger('use_count')->default(0);
            $table->timestamps();

            $table->index(['pool', 'category']);
            $table->index(['pool', 'last_used_on']);
        });

        // Set soal per hari. SENGAJA global: semua user mengerjakan 5 soal
        // yang sama persis, karena peringkat harian tidak adil kalau tiap
        // orang dapat set acak sendiri.
        Schema::create('daily_sets', function (Blueprint $table) {
            $table->date('challenge_date')->primary();
            $table->json('question_ids');   // [id, id, id, id, id] — 4 free + 1 pro
            $table->timestamps();
        });

        Schema::create('daily_attempts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->date('challenge_date');
            $table->timestamp('started_at');
            $table->timestamp('submitted_at')->nullable();
            $table->unsignedTinyInteger('correct')->nullable();
            $table->unsignedTinyInteger('total')->nullable();
            $table->unsignedInteger('duration_ms')->nullable();
            $table->unsignedSmallInteger('iq_harian')->nullable();
            $table->json('answers')->nullable(); // jawaban mentah, untuk pembahasan
            $table->timestamps();

            // Menutup celah mengulang tantangan di hari yang sama.
            $table->unique(['user_id', 'challenge_date'], 'uniq_user_day');

            // Peringkat: benar terbanyak dulu, lalu tercepat. Penentu seri
            // WAJIB ada — dengan 5 soal skornya cuma punya 6 nilai mungkin,
            // tanpa durasi ratusan orang akan seri di angka yang sama.
            $table->index(['challenge_date', 'correct', 'duration_ms'], 'rank_idx');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('daily_attempts');
        Schema::dropIfExists('daily_sets');
        Schema::dropIfExists('question_bank');
    }
};
