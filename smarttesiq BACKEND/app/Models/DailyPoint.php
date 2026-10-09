<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DailyPoint extends Model
{
    use HasFactory;

    protected $table = 'daily_points';

    protected $fillable = [
        'challenge_date',
        'user_id',
        'rank',
        'points',
        'correct',
        'total',
        'duration_ms',
    ];

    protected $casts = [
        'challenge_date' => 'date',
        'rank' => 'integer',
        'points' => 'integer',
        'correct' => 'integer',
        'total' => 'integer',
        'duration_ms' => 'integer',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
