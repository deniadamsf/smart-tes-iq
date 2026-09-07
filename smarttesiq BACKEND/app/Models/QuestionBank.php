<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class QuestionBank extends Model
{
    protected $table = 'question_bank';

    protected $fillable = [
        'pool', 'category', 'question_id', 'question_en',
        'image_path', 'options_id', 'options_en', 'answer',
        'last_used_on', 'use_count',
    ];

    protected $casts = [
        'options_id' => 'array',
        'options_en' => 'array',
        'last_used_on' => 'date',
    ];

    // Bentuk yang boleh dikirim ke HP. Perhatikan: TIDAK ADA 'answer'.
    // Kunci jawaban tidak pernah meninggalkan server — itu satu-satunya
    // alasan papan peringkat harian bisa dipercaya.
    public function forClient(int $no, string $lang = 'id'): array
    {
        $en = $lang === 'en';

        return [
            'no' => $no,
            'category' => $this->category,
            'question' => $en ? $this->question_en : $this->question_id,
            'options' => $en ? $this->options_en : $this->options_id,
            'image' => $this->image_path,
        ];
    }
}
