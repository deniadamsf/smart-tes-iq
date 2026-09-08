<?php

namespace App\Console\Commands;

use App\Models\UserIqScore;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * Mengisi user_iq_scores untuk seluruh user yang sudah ada.
 *
 * Tanpa ini, papan peringkat Reguler dan PRO kosong sampai tiap user
 * kebetulan melakukan /sync.
 *
 * HANYA MEMBACA test_results. Satu-satunya tabel yang ditulis adalah
 * user_iq_scores. Aman dijalankan berulang kali.
 */
class BackfillIqScores extends Command
{
    protected $signature = 'iq:backfill {--dry : Hitung dan laporkan saja, tanpa menulis}';

    protected $description = 'Hitung ulang user_iq_scores dari test_results untuk semua user';

    public function handle(): int
    {
        $kering = (bool) $this->option('dry');

        $userIds = DB::table('test_results')
            ->distinct()
            ->orderBy('user_id')
            ->pluck('user_id');

        if ($userIds->isEmpty()) {
            $this->warn('Tidak ada hasil tes sama sekali.');

            return self::SUCCESS;
        }

        $this->info(($kering ? '[UJI KERING] ' : '') . "Memproses {$userIds->count()} user...");

        $adaReguler = 0;
        $adaPro = 0;
        $keduanyaKosong = 0;

        $bar = $this->output->createProgressBar($userIds->count());
        $bar->start();

        foreach ($userIds as $uid) {
            if ($kering) {
                // Hitung tanpa menyimpan, supaya bisa dilihat dulu hasilnya.
                $rows = DB::table('test_results')->where('user_id', $uid)
                    ->orderBy('id')->get(['test_name', 'score', 'total_questions']);
                $terbaru = [];
                foreach ($rows as $r) {
                    $terbaru[$r->test_name] = $r;
                }
                $b = 0;
                $t = 0;
                foreach ($terbaru as $nama => $r) {
                    if (UserIqScore::kognitifGratis($nama)) {
                        $b += (int) $r->score;
                        $t += (int) $r->total_questions;
                    }
                }
                $reg = UserIqScore::hitungIq($b, $t);
                $pro = isset($terbaru['Tes IQ Komprehensif (PRO)'])
                    ? (int) $terbaru['Tes IQ Komprehensif (PRO)']->score : null;
            } else {
                $skor = UserIqScore::recomputeFor((int) $uid);
                $reg = $skor->iq_reguler;
                $pro = $skor->iq_pro;
            }

            if ($reg !== null) {
                $adaReguler++;
            }
            if ($pro !== null) {
                $adaPro++;
            }
            if ($reg === null && $pro === null) {
                $keduanyaKosong++;
            }

            $bar->advance();
        }

        $bar->finish();
        $this->newLine(2);

        $this->line("  punya IQ Reguler : {$adaReguler}");
        $this->line("  punya IQ PRO     : {$adaPro}");
        $this->line("  tidak punya skor : {$keduanyaKosong}");

        if ($kering) {
            $this->warn('Uji kering — tidak ada yang ditulis.');
        } else {
            $this->info('Selesai. user_iq_scores diperbarui.');
        }

        return self::SUCCESS;
    }
}
