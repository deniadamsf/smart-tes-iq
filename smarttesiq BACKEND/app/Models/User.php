<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens; // <--- MANTRA INI YANG MEMBUATNYA ERROR KEMARIN

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable; // <--- PASTIKAN INI ADA

    protected $fillable = [
        'name',
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
        ];
    }

    // Jembatan ke tabel Tes
    public function testResults() {
        return $this->hasMany(TestResult::class);
    }

    // Jembatan ke tabel Chat
    public function chatHistories() {
        return $this->hasMany(ChatHistory::class);
    }
}