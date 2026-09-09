<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\HasApiTokens; // <--- MANTRA INI YANG MEMBUATNYA ERROR KEMARIN

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable; // <--- PASTIKAN INI ADA

    protected $fillable = [
        'name',
        'display_name',
        'sembunyi_dari_papan',
        'email',
        'password',
        'google_id',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'sembunyi_dari_papan' => 'boolean',
        ];
    }

    /**
     * Subquery id user yang bersedia tampil di papan peringkat.
     *
     * Dikembalikan sebagai query, bukan array id, supaya tetap satu
     * perjalanan ke database berapa pun jumlah usernya. Dipakai di semua
     * tempat yang menghitung peringkat, supaya daftar dan angka peserta
     * selalu memakai himpunan orang yang sama.
     */
    public static function idsTampil(): \Illuminate\Database\Query\Builder
    {
        return DB::table('users')->select('id')->where('sembunyi_dari_papan', false);
    }

    // Jembatan ke tabel Tes
    public function testResults()
    {
        return $this->hasMany(TestResult::class);
    }

    // Jembatan ke tabel Chat
    public function chatHistories()
    {
        return $this->hasMany(ChatHistory::class);
    }
}
