<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Nama tampilan untuk papan peringkat.
 *
 * SENGAJA nullable dan TIDAK diisi otomatis dari `name`:
 * kolom `name` berisi nama lengkap asli dari akun Google, dan user 2.2.1
 * sudah login di bawah kebijakan privasi yang tidak pernah menyebut nama
 * mereka akan ditampilkan ke user lain.
 *
 * NULL = user belum ikut papan peringkat (opt-in, mati secara default).
 * MySQL mengizinkan banyak baris NULL pada indeks unique, jadi user yang
 * tidak ikut tidak saling bentrok.
 *
 * Aman dijalankan saat aplikasi live: hanya menambah kolom nullable,
 * tidak menyentuh kolom lama, dan kode lama mengabaikannya.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('display_name', 24)->nullable()->unique()->after('name');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropUnique(['display_name']);
            $table->dropColumn('display_name');
        });
    }
};
