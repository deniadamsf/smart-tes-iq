<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Mengisi question_bank dari database/seeders/data/question_bank.json.
 *
 * File JSON-nya digenerate dari lib/data/*.dart oleh extract_questions.py
 * yang ada di folder yang sama. Jangan mengetik ulang soal di sini —
 * regenerate dari sumber Dart supaya aplikasi dan server tidak berbeda.
 *
 * AMAN DIJALANKAN ULANG: kalau tabel sudah terisi, seeder berhenti dan
 * tidak menggandakan apa pun. Jalankan dengan SEED_FORCE=1 untuk menimpa.
 */
class QuestionBankSeeder extends Seeder
{
    public function run(): void
    {
        $path = database_path('seeders/data/question_bank.json');

        if (! is_file($path)) {
            $this->command->error("Tidak ada: {$path}");

            return;
        }

        $existing = DB::table('question_bank')->count();
        $force = env('SEED_FORCE') === '1';

        if ($existing > 0 && ! $force) {
            $this->command->warn("question_bank sudah berisi {$existing} soal — dilewati.");
            $this->command->line('Pakai SEED_FORCE=1 untuk menimpa.');

            return;
        }

        $rows = json_decode(file_get_contents($path), true);

        if (! is_array($rows) || $rows === []) {
            $this->command->error('question_bank.json kosong atau tidak valid.');

            return;
        }

        $now = now();
        $payload = [];

        foreach ($rows as $r) {
            $answer = strtoupper(trim((string) ($r['answer'] ?? '')));
            $optionsId = $r['options_id'] ?? [];

            // Penjaga terakhir: kunci wajib satu huruf DAN harus menunjuk ke
            // opsi yang benar-benar ada. Soal yang gagal di sini lebih baik
            // tidak masuk daripada dinilai salah selamanya.
            if (strlen($answer) !== 1 || ! is_array($optionsId)) {
                continue;
            }
            if (ord($answer) - 65 >= count($optionsId)) {
                continue;
            }

            $payload[] = [
                'pool' => $r['pool'],
                'category' => $r['category'],
                'question_id' => $r['question_id'] ?? null,
                'question_en' => $r['question_en'] ?? null,
                'image_path' => $r['image_path'] ?? null,
                'options_id' => json_encode($optionsId, JSON_UNESCAPED_UNICODE),
                'options_en' => json_encode($r['options_en'] ?? $optionsId, JSON_UNESCAPED_UNICODE),
                'answer' => $answer,
                'use_count' => 0,
                'created_at' => $now,
                'updated_at' => $now,
            ];
        }

        DB::transaction(function () use ($payload, $force) {
            if ($force) {
                DB::table('question_bank')->delete();
            }
            foreach (array_chunk($payload, 100) as $chunk) {
                DB::table('question_bank')->insert($chunk);
            }
        });

        $skipped = count($rows) - count($payload);
        $this->command->info(sprintf('question_bank: %d soal dimasukkan.', count($payload)));

        if ($skipped > 0) {
            $this->command->warn("{$skipped} soal dilewati karena kunci jawaban tidak valid.");
        }
    }
}
