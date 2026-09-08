<?php

namespace App\Http\Controllers;

use App\Models\DailyAttempt;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

/**
 * Papan peringkat.
 *
 * Aturan privasi yang tidak boleh dilanggar:
 *
 * `users.name` berisi NAMA LENGKAP ASLI dari akun Google. Kolom itu TIDAK
 * BOLEH muncul di papan peringkat dalam bentuk apa pun. Yang dipakai hanya
 * `display_name`, nama yang dipilih sendiri oleh user.
 *
 * `display_name` bernilai NULL berarti user belum ikut papan peringkat.
 * Ini disengaja: user versi 2.2.1 login di bawah kebijakan privasi yang
 * tidak pernah menyebut nama mereka akan ditampilkan ke user lain, jadi
 * ikut serta harus lewat persetujuan aktif, bukan default.
 */
class LeaderboardController extends Controller
{
    private const TZ = 'Asia/Jakarta';

    private const TOP_DAILY = 20;

    private function today(): string
    {
        return Carbon::now(self::TZ)->toDateString();
    }

    // =====================================================================
    // GET /api/leaderboard/daily
    // =====================================================================
    public function daily(Request $request): JsonResponse
    {
        $user = $request->user();
        // Tanggal SELALU dari server. Kalau client boleh menentukan tanggal,
        // papan peringkat bisa dilihat/dimanipulasi lintas hari.
        $date = $this->today();

        // Hanya peserta yang sudah SELESAI dan sudah punya nama tampilan.
        $top = DailyAttempt::query()
            ->join('users', 'users.id', '=', 'daily_attempts.user_id')
            ->where('daily_attempts.challenge_date', $date)
            ->whereNotNull('daily_attempts.submitted_at')
            ->whereNotNull('users.display_name')
            ->orderByDesc('daily_attempts.correct')
            ->orderBy('daily_attempts.duration_ms')
            ->limit(self::TOP_DAILY)
            ->get([
                'users.display_name',
                'daily_attempts.correct',
                'daily_attempts.total',
                'daily_attempts.duration_ms',
                'daily_attempts.iq_harian',
                'daily_attempts.user_id',
            ]);

        $mine = DailyAttempt::query()
            ->where('user_id', $user->id)
            ->where('challenge_date', $date)
            ->whereNotNull('submitted_at')
            ->first();

        return response()->json([
            'status' => 'ok',
            'challenge_date' => $date,
            'participants' => DailyAttempt::participantsOn($date),
            'display_name' => $user->display_name,
            'ikut_papan' => $user->display_name !== null,
            'top' => $top->values()->map(fn ($r, $i) => [
                'rank' => $i + 1,
                'display_name' => $r->display_name,
                'correct' => $r->correct,
                'total' => $r->total,
                'duration_ms' => $r->duration_ms,
                'iq_harian' => $r->iq_harian,
                'saya' => (int) $r->user_id === (int) $user->id,
            ])->all(),
            // Selalu sertakan peringkat sendiri walau di urutan 300.
            // Tanpa ini hampir semua user melihat papan yang tidak ada
            // dirinya dan langsung kehilangan minat.
            'me' => $mine === null ? null : [
                'rank' => $mine->rank(),
                'correct' => $mine->correct,
                'total' => $mine->total,
                'duration_ms' => $mine->duration_ms,
                'iq_harian' => $mine->iq_harian,
            ],
        ]);
    }

    // =====================================================================
    // POST /api/leaderboard/display-name
    // =====================================================================
    public function setDisplayName(Request $request): JsonResponse
    {
        $user = $request->user();
        $raw = (string) $request->input('display_name', '');

        // Buang karakter kendali dan spasi berlebih sebelum divalidasi.
        $name = trim(preg_replace('/[\p{C}]+/u', '', $raw) ?? '');
        $name = preg_replace('/\s{2,}/u', ' ', $name) ?? '';

        $v = validator(
            ['display_name' => $name],
            [
                'display_name' => [
                    'required', 'string', 'min:3', 'max:24',
                    'regex:/^[\p{L}\p{N} ._-]+$/u',
                    Rule::unique('users', 'display_name')->ignore($user->id),
                ],
            ],
            [
                'display_name.unique' => 'Nama itu sudah dipakai orang lain. Coba nama lain.',
                'display_name.regex' => 'Hanya huruf, angka, spasi, titik, garis bawah, dan strip.',
                'display_name.min' => 'Nama tampilan minimal 3 karakter.',
                'display_name.max' => 'Nama tampilan maksimal 24 karakter.',
            ]
        );

        if ($v->fails()) {
            return response()->json([
                'status' => 'tidak_valid',
                'message' => $v->errors()->first('display_name'),
            ], 422);
        }

        // Update SATU kolom saja. Sengaja tidak memakai save() pada model
        // yang sudah dimuat, supaya tidak ada kolom lain yang ikut tertulis.
        DB::table('users')->where('id', $user->id)->update(['display_name' => $name]);

        return response()->json([
            'status' => 'ok',
            'display_name' => $name,
        ]);
    }
}
