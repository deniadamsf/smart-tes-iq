<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DailyWinner extends Model
{
    protected $table = 'daily_winners';

    protected $fillable = [
        'challenge_date',
        'user_id',
        'correct',
        'total',
        'duration_ms',
        'iq_harian',
    ];

    protected $casts = [
        'challenge_date' => 'date',
        'correct' => 'integer',
        'total' => 'integer',
        'duration_ms' => 'integer',
        'iq_harian' => 'integer',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
