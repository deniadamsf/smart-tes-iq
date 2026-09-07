<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DailySet extends Model
{
    protected $table = 'daily_sets';

    protected $primaryKey = 'challenge_date';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = ['challenge_date', 'question_ids'];

    protected $casts = ['question_ids' => 'array'];
}
