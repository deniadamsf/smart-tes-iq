<?php

namespace App\Http\Controllers;

use App\Models\DailyAttempt;
use App\Models\User;
use App\Models\UserIqScore;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

/**
 * Papan peringkat.
 *
 * Dua aturan yang menentukan bentuk seluruh kelas ini:
 *
 * 1. NAMA. Setiap peserta yang punya skor DIPAJANG. Yang dipakai adalah
 *    `display_name` pilihan user sendiri; kalau belum diisi, dipakai
 *    `users.name` (nama akun Google) sebagai nama sementara. Papan yang
 *    hampir kosong membuat user langsung kehilangan minat, dan nama
 *    pilihan sendiri tidak akan pernah terisi kalau papannya sepi sejak
 *    awal. Response menandai keadaan ini lewat `nama_otomatis`, supaya
 *    aplikasi bisa mengajak user mengganti namanya.
 *
 *    Konsekuensinya kebijakan privasi HARUS menyebut bahwa nama akun
 *    Google dipakai sampai user memilih nama sendiri. Jangan ubah
 *    perilaku di sini tanpa ikut memperbarui privacy.html dan
 *    `privacy_content` di assets/lang.
 *
 *    Karena tampil jadi perilaku bawaan, jalan keluarnya wajib ada di
 *    dalam aplikasi: kolom `users.sembunyi_dari_papan`. User yang
 *    menyalakannya hilang dari daftar DAN dari hitungan peserta, supaya
 *    nomor peringkat orang lain tidak melompat.
 *
 * 2. ANGKA IQ. Skor IQ hanya dikirim untuk BARIS MILIK USER SENDIRI.
 *    Baris orang lain tidak membawa angkanya sama sekali — bukan sekadar
 *    disembunyikan di UI, memang tidak ada di response, supaya tidak bisa
 *    dipanen lewat endpoint langsung. Urutan peringkat tetap memakai skor
 *    itu, hanya angkanya yang tidak dibagikan.
 */
class LeaderboardController extends Controller
{
    private const TZ = 'Asia/Jakarta';

    private const TOP_DAILY = 20;

    private const TOP_REGULER = 100;

    private const TOP_PRO = 50;

    /** Sama dengan batas kolom `users.display_name`. */
    private const MAKS_NAMA = 24;

    private function today(): string
    {
        return Carbon::now(self::TZ)->toDateString();
    }

    /**
     * Nama yang dipajang di papan.
     *
     * Nama pilihan user menang. Kalau kosong, nama akun Google dipakai apa
     * adanya seperti yang sudah user lihat di layar profil — hanya
     * dibersihkan dari karakter kendali dan dipotong ke panjang kolom,
     * supaya satu nama panjang tidak merusak tata letak baris.
     */
    private static function namaPapan(?string $pilihan, ?string $namaAkun): string
    {
        $nama = trim((string) $pilihan);
        if ($nama !== '') {
            return $nama;
        }

        $nama = preg_replace('/[\p{C}]+/u', '', (string) $namaAkun) ?? '';
        $nama = trim(preg_replace('/\s{2,}/u', ' ', $nama) ?? '');

        if ($nama === '') {
            return 'Peserta';
        }

        if (mb_strlen($nama) > self::MAKS_NAMA) {
            $nama = rtrim(mb_substr($nama, 0, self::MAKS_NAMA - 1)).'…';
        }

        return $nama;
    }

    /** True selama user belum memilih nama tampilan sendiri. */
    private static function pakaiNamaAkun(?string $displayName): bool
    {
        return trim((string) $displayName) === '';
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

        // Semua peserta yang sudah SELESAI dan bersedia tampil, sudah punya
        // nama pilihan sendiri atau belum.
        $top = DailyAttempt::query()
            ->join('users', 'users.id', '=', 'daily_attempts.user_id')
            ->where('daily_attempts.challenge_date', $date)
            ->whereNotNull('daily_attempts.submitted_at')
            ->where('users.sembunyi_dari_papan', false)
            ->orderByDesc('daily_attempts.correct')
            ->orderBy('daily_attempts.duration_ms')
            ->limit(self::TOP_DAILY)
            ->get([
                'users.display_name',
                'users.name as nama_akun',
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
            // Papan harian dinilai SERVER, jadi angkanya tidak bisa dipalsukan.
            'terverifikasi' => true,
            'challenge_date' => $date,
            'participants' => DailyAttempt::participantsOn($date),
            'display_name' => $user->display_name,
            'nama_tampil' => self::namaPapan($user->display_name, $user->name),
            'nama_otomatis' => self::pakaiNamaAkun($user->display_name),
            'sembunyi' => (bool) $user->sembunyi_dari_papan,
            'top' => $top->values()->map(function ($r, $i) use ($user) {
                $saya = (int) $r->user_id === (int) $user->id;

                return [
                    'rank' => $i + 1,
                    'display_name' => self::namaPapan($r->display_name, $r->nama_akun),
                    'correct' => $r->correct,
                    'total' => $r->total,
                    'duration_ms' => $r->duration_ms,
                    // Angka IQ hanya untuk pemiliknya. Lihat aturan 2 di atas.
                    'iq_harian' => $saya ? $r->iq_harian : null,
                    'saya' => $saya,
                ];
            })->all(),
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
                    'required', 'string', 'min:3', 'max:'.self::MAKS_NAMA,
                    'regex:/^[\p{L}\p{N} ._-]+$/u',
                    Rule::unique('users', 'display_name')->ignore($user->id),
                ],
            ],
            [
                'display_name.unique' => 'Nama itu sudah dipakai orang lain. Coba nama lain.',
                'display_name.regex' => 'Hanya huruf, angka, spasi, titik, garis bawah, dan strip.',
                'display_name.min' => 'Nama tampilan minimal 3 karakter.',
                'display_name.max' => 'Nama tampilan maksimal '.self::MAKS_NAMA.' karakter.',
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
            'nama_tampil' => $name,
            'nama_otomatis' => false,
        ]);
    }

    // =====================================================================
    // POST /api/leaderboard/sembunyi
    // =====================================================================

    /**
     * Nyalakan/matikan "sembunyikan saya dari papan peringkat".
     *
     * User diambil dari token, tidak pernah dari body — kalau tidak, siapa
     * pun bisa menyembunyikan lawannya dari papan.
     *
     * Nama tampilan sengaja TIDAK dihapus saat user menyembunyikan diri.
     * Kalau dihapus, nama pilihannya bisa direbut orang lain selama dia
     * bersembunyi, dan dia tidak bisa mendapatkannya kembali.
     */
    public function setSembunyi(Request $request): JsonResponse
    {
        $user = $request->user();

        $v = validator($request->all(), ['sembunyi' => ['required', 'boolean']]);

        if ($v->fails()) {
            return response()->json([
                'status' => 'tidak_valid',
                'message' => 'Nilai sembunyi harus true atau false.',
            ], 422);
        }

        $sembunyi = $request->boolean('sembunyi');

        DB::table('users')->where('id', $user->id)->update(['sembunyi_dari_papan' => $sembunyi]);

        return response()->json([
            'status' => 'ok',
            'sembunyi' => $sembunyi,
        ]);
    }

    // =====================================================================
    // GET /api/leaderboard/reguler  |  GET /api/leaderboard/pro
    // =====================================================================

    public function reguler(Request $request): JsonResponse
    {
        return $this->papanIq($request, 'iq_reguler', self::TOP_REGULER);
    }

    public function pro(Request $request): JsonResponse
    {
        return $this->papanIq($request, 'iq_pro', self::TOP_PRO);
    }

    /**
     * Papan peringkat berbasis skor IQ yang sudah dihitung di muka.
     *
     * PERINGATAN KEJUJURAN: berbeda dengan papan harian, skor di sini
     * dihitung di HP lalu dikirim lewat /sync. Validasi hanya bisa menolak
     * angka yang mustahil, bukan angka masuk akal yang dipalsukan. Karena
     * itu 'terverifikasi' bernilai false di sini dan true di papan harian --
     * aplikasi menampilkan bedanya supaya user tidak salah menyangka.
     */
    private function papanIq(Request $request, string $kolom, int $limit): JsonResponse
    {
        $user = $request->user();

        $top = UserIqScore::query()
            ->join('users', 'users.id', '=', 'user_iq_scores.user_id')
            ->whereNotNull("user_iq_scores.{$kolom}")
            ->where('users.sembunyi_dari_papan', false)
            ->orderByDesc("user_iq_scores.{$kolom}")
            // Penentu seri stabil, supaya urutan tidak berubah-ubah antar
            // permintaan ketika skornya sama persis.
            ->orderBy('user_iq_scores.user_id')
            ->limit($limit)
            ->get([
                'users.display_name',
                'users.name as nama_akun',
                "user_iq_scores.{$kolom} as iq",
                'user_iq_scores.user_id',
            ]);

        $milikSaya = UserIqScore::query()
            ->where('user_id', $user->id)
            ->value($kolom);

        return response()->json([
            'status' => 'ok',
            'papan' => $kolom,
            'terverifikasi' => false,
            'participants' => UserIqScore::query()
                ->whereNotNull($kolom)
                ->whereIn('user_id', User::idsTampil())
                ->count(),
            'display_name' => $user->display_name,
            'nama_tampil' => self::namaPapan($user->display_name, $user->name),
            'nama_otomatis' => self::pakaiNamaAkun($user->display_name),
            'sembunyi' => (bool) $user->sembunyi_dari_papan,
            'top' => $top->values()->map(function ($r, $i) use ($user) {
                $saya = (int) $r->user_id === (int) $user->id;

                return [
                    'rank' => $i + 1,
                    'display_name' => self::namaPapan($r->display_name, $r->nama_akun),
                    // Angka IQ hanya untuk pemiliknya. Lihat aturan 2 di atas.
                    'iq' => $saya ? (int) $r->iq : null,
                    'saya' => $saya,
                ];
            })->all(),
            'me' => $milikSaya === null ? null : [
                // Skor yang sama berbagi peringkat yang sama. Peserta yang
                // menyembunyikan diri tidak ikut dihitung, sama seperti di
                // daftar, supaya nomornya cocok.
                'rank' => UserIqScore::query()
                    ->where($kolom, '>', $milikSaya)
                    ->whereIn('user_id', User::idsTampil())
                    ->count() + 1,
                'iq' => (int) $milikSaya,
            ],
        ]);
    }
}
