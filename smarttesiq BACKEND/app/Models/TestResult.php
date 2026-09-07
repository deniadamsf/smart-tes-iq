<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TestResult extends Model
{
    protected $table = 'test_results';
    
    // Membuka gembok agar Flutter bisa menyuntikkan data
    protected $fillable = [
        'user_id', 
        'test_name', 
        'score', 
        'total_questions', 
        'ai_analysis', 
        'client_created_at'
    ];
}