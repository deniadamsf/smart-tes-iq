<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Pencatat kredit yang SUDAH TERPAKAI.
 *
 * Sebelum ini server hanya menyimpan kredit tertinggi yang pernah dimiliki
 * (karena memakai max() dan tidak pernah turun), lalu mengembalikannya
 * sebagai saldo lewat /user-data. Akibatnya siapa pun bisa memakai habis
 * kreditnya, menekan tombol sinkronisasi di layar Profil, dan kreditnya
 * kembali penuh — berulang kali, tanpa membongkar apa pun.
 *
 * Dengan kolom ini: saldo = diberikan - terpakai. Kolom lama tetap berperan
 * sebagai "total pernah diberikan", jadi tidak ada nilai yang perlu diubah.
 *
 * Default 0 berarti saat migrasi dijalankan, saldo setiap user sama persis
 * dengan nilai yang mereka lihat sekarang. Tidak ada yang kehilangan kredit.
 *
 * Client 2.2.1 yang beredar tidak mengirim angka pemakaian, jadi bagi mereka
 * kolom ini tetap 0 dan perilakunya tidak berubah. Perbaikan baru berlaku
 * setelah user memasang versi baru.
 */
return new class extends Migration
{
    private const KOLOM = ['wartegg_credits', 'eq_sq_credits', 'kredit_iq_pro'];

    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            foreach (self::KOLOM as $k) {
                $table->unsignedInteger($k.'_terpakai')->default(0)->after($k);
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            foreach (self::KOLOM as $k) {
                $table->dropColumn($k.'_terpakai');
            }
        });
    }
};
