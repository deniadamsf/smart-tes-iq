<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DailyAttempt extends Model
{
    protected $fillable = [
        'user_id', 'challenge_date', 'started_at', 'submitted_at',
        'correct', 'total', 'duration_ms', 'iq_harian', 'answers',
    ];

    protected $casts = [
        'challenge_date' => 'date',
        'started_at' => 'datetime',
        'submitted_at' => 'datetime',
        'answers' => 'array',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Peringkat hari itu: benar terbanyak dulu, lalu tercepat.
     *
     * Penentu seri WAJIB ada — dengan 5 soal, skornya cuma punya 6 nilai
     * mungkin, jadi tanpa durasi ratusan orang akan seri di angka yang sama.
     *
     * Ditaruh di model, bukan di controller, supaya papan peringkat dan
     * layar hasil memakai rumus yang SAMA PERSIS. Dua salinan rumus adalah
     * cara paling mudah bikin angka di dua layar berbeda.
     */
    public function rank(): int
    {
        if ($this->submitted_at === null) {
            return 0;
        }

        return static::query()
            ->where('challenge_date', $this->challenge_date->toDateString())
            ->whereNotNull('submitted_at')
            ->where(function ($q) {
                $q->where('correct', '>', $this->correct)
                    ->orWhere(function ($q2) {
                        $q2->where('correct', $this->correct)
                            ->where('duration_ms', '<', $this->duration_ms);
                    });
            })
            ->count() + 1;
    }

    /**
     * Jumlah peserta yang SUDAH menyelesaikan tantangan pada tanggal itu.
     *
     * Menghitung semua peserta, termasuk yang belum mengisi nama tampilan
     * dan karena itu tidak muncul di papan peringkat. "Peringkat 3 dari 7"
     * harus jujur menyebut seluruh peserta, bukan hanya yang terpampang.
     */
    public static function participantsOn(string $date): int
    {
        return static::query()
            ->where('challenge_date', $date)
            ->whereNotNull('submitted_at')
            ->count();
    }
}
