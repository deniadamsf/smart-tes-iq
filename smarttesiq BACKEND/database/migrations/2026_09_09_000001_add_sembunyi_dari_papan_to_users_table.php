<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Saklar "sembunyikan saya dari papan peringkat".
 *
 * Sejak papan peringkat menampilkan semua peserta memakai nama akun Google
 * bila user belum memilih nama sendiri, harus ada jalan keluar yang tidak
 * mengharuskan user menghubungi admin. Kolom ini jalan keluarnya.
 *
 * Default false — perilaku user yang sudah ada tidak berubah sama sekali.
 * User yang menyalakannya hilang dari daftar papan DAN tidak ikut dihitung
 * sebagai peserta, sehingga peringkat orang lain tetap runut tanpa lompatan
 * nomor.
 *
 * Aman dijalankan saat aplikasi live: hanya menambah kolom boolean dengan
 * default, tidak menyentuh kolom lama, dan kode lama mengabaikannya.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->boolean('sembunyi_dari_papan')->default(false)->after('display_name');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('sembunyi_dari_papan');
        });
    }
};
