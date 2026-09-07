<?php

namespace App\Http\Controllers;

use App\Models\DailyAttempt;
use App\Models\DailySet;
use App\Models\QuestionBank;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Tantangan IQ Harian.
 *
 * Prinsip yang tidak boleh dilanggar:
 *
 * 1. KUNCI JAWABAN TIDAK PERNAH DIKIRIM KE HP. Penilaian dilakukan di sini.
 *    Kalau kunci ikut terkirim, papan peringkat bisa dipalsukan dan
 *    seluruh fiturnya kehilangan arti.
 *
 * 2. TANGGAL DAN DURASI DARI SERVER, bukan dari client. Mengubah jam HP
 *    tidak boleh berpengaruh ke streak maupun peringkat.
 *
 * 3. SET SOAL GLOBAL. Semua user mengerjakan 5 soal yang sama tiap hari —
 *    peringkat tidak adil kalau tiap orang dapat set acak sendiri.
 */
class DailyChallengeController extends Controller
{
    /** Zona waktu penentu pergantian hari. */
    private const TZ = 'Asia/Jakarta';

    private const FREE_PER_DAY = 4;

    private const PRO_PER_DAY = 1;

    /** Batas waktu pengerjaan; juga jadi batas atas durasi tercatat. */
    private const TIME_LIMIT_SEC = 300;

    private function today(): string
    {
        return Carbon::now(self::TZ)->toDateString();
    }

    // =====================================================================
    // POST /api/daily/start
    // =====================================================================
    public function start(Request $request): JsonResponse
    {
        $user = $request->user();
        $date = $this->today();
        $lang = $request->input('lang') === 'en' ? 'en' : 'id';

        $attempt = DailyAttempt::where('user_id', $user->id)
            ->where('challenge_date', $date)
            ->first();

        if ($attempt && $attempt->submitted_at) {
            return response()->json([
                'status' => 'sudah_selesai',
                'result' => $this->resultPayload($attempt),
            ], 409);
        }

        $set = $this->setForDate($date);
        $questions = $this->orderedQuestions($set);

        if ($questions->isEmpty()) {
            return response()->json([
                'status' => 'gagal',
                'message' => 'Bank soal belum terisi.',
            ], 503);
        }

        // Kalau attempt sudah ada tapi belum disubmit, JANGAN reset
        // started_at — kalau tidak, user bisa memperpanjang waktunya
        // berkali-kali dengan menutup lalu membuka lagi.
        if (! $attempt) {
            $attempt = DailyAttempt::create([
                'user_id' => $user->id,
                'challenge_date' => $date,
                'started_at' => Carbon::now(),
            ]);
        }

        $elapsed = Carbon::now()->diffInSeconds($attempt->started_at);

        return response()->json([
            'status' => 'ok',
            'challenge_date' => $date,
            'time_limit_sec' => self::TIME_LIMIT_SEC,
            'sisa_detik' => max(0, self::TIME_LIMIT_SEC - $elapsed),
            'questions' => $questions->values()
                ->map(fn ($q, $i) => $q->forClient($i + 1, $lang))
                ->all(),
        ]);
    }

    // =====================================================================
    // POST /api/daily/submit
    // =====================================================================
    public function submit(Request $request): JsonResponse
    {
        $user = $request->user();
        $date = $this->today();

        $attempt = DailyAttempt::where('user_id', $user->id)
            ->where('challenge_date', $date)
            ->first();

        if (! $attempt) {
            return response()->json([
                'status' => 'belum_mulai',
                'message' => 'Mulai tantangan hari ini terlebih dahulu.',
            ], 422);
        }

        if ($attempt->submitted_at) {
            return response()->json([
                'status' => 'sudah_selesai',
                'result' => $this->resultPayload($attempt),
            ], 409);
        }

        $set = $this->setForDate($date);
        $questions = $this->orderedQuestions($set);
        $given = (array) $request->input('answers', []);

        $correct = 0;
        $normalized = [];

        foreach ($questions->values() as $i => $q) {
            $letter = $this->toLetter($given[$i] ?? null);
            $normalized[] = $letter;

            if ($letter !== null && $letter === $q->answer) {
                $correct++;
            }
        }

        $total = $questions->count();

        // Durasi dihitung di sini, bukan dikirim client. Dibatasi supaya
        // user yang meninggalkan aplikasi semalaman tidak tercatat 8 jam.
        $durationMs = min(
            Carbon::now()->diffInMilliseconds($attempt->started_at),
            self::TIME_LIMIT_SEC * 1000
        );

        $attempt->update([
            'submitted_at' => Carbon::now(),
            'correct' => $correct,
            'total' => $total,
            'duration_ms' => $durationMs,
            'iq_harian' => $this->toIq($correct, $total),
            'answers' => $normalized,
        ]);

        return response()->json([
            'status' => 'ok',
            'result' => $this->resultPayload($attempt->refresh()),
        ]);
    }

    // =====================================================================
    // GET /api/daily/me
    // =====================================================================
    public function me(Request $request): JsonResponse
    {
        $user = $request->user();

        $history = DailyAttempt::where('user_id', $user->id)
            ->whereNotNull('submitted_at')
            ->orderByDesc('challenge_date')
            ->limit(30)
            ->get();

        return response()->json([
            'status' => 'ok',
            'streak' => $this->streak($history->pluck('challenge_date')),
            'sudah_main_hari_ini' => $history->contains(
                fn ($a) => $a->challenge_date->toDateString() === $this->today()
            ),
            'history' => $history->map(fn ($a) => [
                'challenge_date' => $a->challenge_date->toDateString(),
                'correct' => $a->correct,
                'total' => $a->total,
                'iq_harian' => $a->iq_harian,
                'duration_ms' => $a->duration_ms,
            ])->all(),
        ]);
    }

    // =====================================================================
    // Internal
    // =====================================================================

    /**
     * Ambil set soal hari ini, buat kalau belum ada.
     *
     * Pemilihan mengutamakan soal yang paling lama tidak dipakai, lalu
     * diacak dari kumpulan itu. Kalau semua sudah pernah dipakai, rotasi
     * berjalan sendiri karena yang tertua selalu naik lagi ke atas.
     */
    private function setForDate(string $date): DailySet
    {
        if ($set = DailySet::find($date)) {
            return $set;
        }

        $pick = function (string $pool, int $count, int $window): array {
            return QuestionBank::where('pool', $pool)
                ->orderByRaw('last_used_on IS NULL DESC')
                ->orderBy('last_used_on')
                ->orderBy('use_count')
                ->limit($window)
                ->pluck('id')
                ->shuffle()
                ->take($count)
                ->values()
                ->all();
        };

        $ids = array_merge(
            $pick('free', self::FREE_PER_DAY, 40),
            $pick('pro', self::PRO_PER_DAY, 20),
        );

        if ($ids === []) {
            return new DailySet(['challenge_date' => $date, 'question_ids' => []]);
        }

        shuffle($ids);

        try {
            $set = DB::transaction(function () use ($date, $ids) {
                $set = DailySet::create([
                    'challenge_date' => $date,
                    'question_ids' => $ids,
                ]);

                QuestionBank::whereIn('id', $ids)->update([
                    'last_used_on' => $date,
                    'use_count' => DB::raw('use_count + 1'),
                ]);

                return $set;
            });
        } catch (\Throwable $e) {
            // Dua permintaan pertama di hari yang sama bisa berlomba membuat
            // set. Yang kalah cukup memakai punya pemenang.
            $set = DailySet::find($date);

            if (! $set) {
                throw $e;
            }
        }

        return $set;
    }

    /** Soal dalam urutan yang sama persis dengan yang tersimpan di set. */
    private function orderedQuestions(DailySet $set)
    {
        $ids = $set->question_ids ?? [];

        if ($ids === []) {
            return collect();
        }

        $byId = QuestionBank::whereIn('id', $ids)->get()->keyBy('id');

        return collect($ids)
            ->map(fn ($id) => $byId->get($id))
            ->filter()
            ->values();
    }

    /**
     * Terima jawaban sebagai indeks (0,1,2...) maupun huruf ("B", "B. Gelap").
     * Client lama/baru boleh mengirim salah satunya.
     */
    private function toLetter($value): ?string
    {
        if ($value === null || $value === '') {
            return null;
        }

        if (is_int($value) || (is_string($value) && ctype_digit($value))) {
            $idx = (int) $value;

            return ($idx >= 0 && $idx < 26) ? chr(65 + $idx) : null;
        }

        $letter = strtoupper(substr(trim((string) $value), 0, 1));

        return ($letter >= 'A' && $letter <= 'Z') ? $letter : null;
    }

    /** Rumus sama dengan final_result_screen.dart agar angkanya konsisten. */
    private function toIq(int $correct, int $total): int
    {
        if ($total < 1) {
            return 70;
        }

        return 70 + (int) round(($correct / $total) * 70);
    }

    private function resultPayload(DailyAttempt $a): array
    {
        return [
            'challenge_date' => $a->challenge_date->toDateString(),
            'correct' => $a->correct,
            'total' => $a->total,
            'duration_ms' => $a->duration_ms,
            'iq_harian' => $a->iq_harian,
            'rank_today' => $this->rankOf($a),
            'participants' => $this->participants($a->challenge_date->toDateString()),
        ];
    }

    /** Peringkat: benar terbanyak dulu, lalu tercepat. */
    private function rankOf(DailyAttempt $a): int
    {
        return DailyAttempt::where('challenge_date', $a->challenge_date->toDateString())
            ->whereNotNull('submitted_at')
            ->where(function ($q) use ($a) {
                $q->where('correct', '>', $a->correct)
                    ->orWhere(function ($q2) use ($a) {
                        $q2->where('correct', $a->correct)
                            ->where('duration_ms', '<', $a->duration_ms);
                    });
            })
            ->count() + 1;
    }

    private function participants(string $date): int
    {
        return DailyAttempt::where('challenge_date', $date)
            ->whereNotNull('submitted_at')
            ->count();
    }

    /** Hari beruntun sampai hari ini (atau kemarin, kalau hari ini belum main). */
    private function streak($dates): int
    {
        $set = $dates->map(fn ($d) => $d->toDateString())->flip();
        $cursor = Carbon::now(self::TZ);

        if (! $set->has($cursor->toDateString())) {
            $cursor->subDay();
        }

        $streak = 0;

        while ($set->has($cursor->toDateString())) {
            $streak++;
            $cursor->subDay();
        }

        return $streak;
    }
}
