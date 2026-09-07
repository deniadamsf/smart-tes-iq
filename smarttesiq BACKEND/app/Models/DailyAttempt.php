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
}
