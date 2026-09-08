<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;

/**
 * Skor IQ terhitung, dipakai papan peringkat Reguler dan PRO.
 *
 * SATU-SATUNYA tempat rumus IQ hidup di sisi server. Rumusnya sama dengan
 * final_result_screen.dart supaya angka di aplikasi dan di papan peringkat
 * tidak pernah berbeda.
 */
class UserIqScore extends Model
{
    protected $table = 'user_iq_scores';

    protected $primaryKey = 'user_id';

    public $incrementing = false;

    public const UPDATED_AT = 'updated_at';

    public const CREATED_AT = null;

    protected $fillable = ['user_id', 'iq_reguler', 'iq_pro'];

    /** Kata kunci penanda tes kognitif, sama persis dengan sisi Flutter. */
    private const KATA_KOGNITIF = ['Verbal', 'Deret', 'Logis', 'Spasial', 'Klasifikasi'];

    private const NAMA_IQ_PRO = 'Tes IQ Komprehensif (PRO)';

    /**
     * Apakah nama tes termasuk kognitif GRATIS.
     *
     * Penanda '(PRO)' sengaja dikecualikan. Rumus lama tidak melakukannya,
     * sehingga hasil tes PRO ikut tercampur ke skor "IQ Reguler" — artinya
     * user yang membeli PRO diperingkat pada dasar yang berbeda dari user
     * gratis. Untuk papan peringkat itu tidak setara.
     *
     * Diukur di produksi sebelum diubah: 6 user skornya bergeser (semuanya
     * NAIK, +2 sampai +25), dan 7 user kehilangan IQ Reguler karena hanya
     * mengerjakan tes PRO. Ketujuhnya tetap punya skor IQ PRO, jadi tidak
     * ada yang berakhir tanpa skor sama sekali.
     */
    public static function kognitifGratis(string $namaTes): bool
    {
        if (str_contains($namaTes, '(PRO)')) {
            return false;
        }

        foreach (self::KATA_KOGNITIF as $kata) {
            if (str_contains($namaTes, $kata)) {
                return true;
            }
        }

        return false;
    }

    /** Rumus sama dengan final_result_screen.dart: 70 + round(pct * 70). */
    public static function hitungIq(int $benar, int $total): ?int
    {
        if ($total < 1) {
            return null;
        }

        return 70 + (int) round(($benar / $total) * 70);
    }

    /**
     * Hitung ulang skor satu user dari test_results miliknya.
     *
     * Hanya MEMBACA test_results dan menulis ke user_iq_scores. Tidak ada
     * satu pun baris hasil tes yang tersentuh.
     */
    public static function recomputeFor(int $userId): self
    {
        $rows = DB::table('test_results')
            ->where('user_id', $userId)
            ->orderBy('id')
            ->get(['test_name', 'score', 'total_questions']);

        // Hasil TERBARU per nama tes menang, sama seperti di aplikasi
        // (id menaik, jadi yang belakangan menimpa yang duluan).
        $terbaru = [];
        foreach ($rows as $r) {
            $terbaru[$r->test_name] = $r;
        }

        $benar = 0;
        $total = 0;
        foreach ($terbaru as $nama => $r) {
            if (self::kognitifGratis($nama)) {
                $benar += (int) $r->score;
                $total += (int) $r->total_questions;
            }
        }

        $iqPro = isset($terbaru[self::NAMA_IQ_PRO])
            ? (int) $terbaru[self::NAMA_IQ_PRO]->score
            : null;

        // Jaga-jaga terhadap data lama yang di luar nalar, supaya tidak
        // ada baris mustahil yang menguasai papan peringkat.
        if ($iqPro !== null && ($iqPro < 40 || $iqPro > 200)) {
            $iqPro = null;
        }

        $skor = self::firstOrNew(['user_id' => $userId]);
        $skor->iq_reguler = self::hitungIq($benar, $total);
        $skor->iq_pro = $iqPro;
        $skor->save();

        return $skor;
    }
}
