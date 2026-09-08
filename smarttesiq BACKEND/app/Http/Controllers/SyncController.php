<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\TestResult;
use App\Models\UserIqScore;
use App\Models\ChatHistory;
use Illuminate\Support\Facades\Log;

class SyncController extends Controller
{
    private const KOLOM_KREDIT = ['wartegg_credits', 'eq_sq_credits', 'kredit_iq_pro'];

    /**
     * Batas mutlak. Satu pembelian memberi +10 kredit
     * (pro_iq_dashboard_screen.dart:108); nilai tertinggi yang benar-benar
     * ada di produksi saat batas ini dipasang adalah 9. Tidak ada pemakaian
     * wajar yang mendekati 500.
     */
    private const KREDIT_MAKS = 500;

    /**
     * Kenaikan maksimum dalam satu kali sync. Tiga kali pembelian berturut
     * saat offline (+30) sudah tertampung; di atas itu tidak masuk akal.
     */
    private const KENAIKAN_MAKS_PER_SYNC = 30;

    /** Batas kewarasan untuk penghitung pemakaian; tidak dibatasi per sync. */
    private const PEMAKAIAN_MAKS = 100000;

    // MENERIMA DATA DARI HP FLUTTER
    public function syncData(Request $request)
    {
        try {
            $user = $request->user();

            // --- LOGIKA KOIN HIBRIDA ---
            // Kredit hidup di SharedPreferences perangkat dan server tidak
            // pernah memverifikasi pembelian ke Google. Mengambil nilai
            // tertinggi adalah satu-satunya jalan pembelian sah sampai ke
            // server sekaligus cara memulihkan kredit saat ganti HP, jadi
            // perilaku itu DIPERTAHANKAN -- tapi sekarang dibatasi.
            foreach (self::KOLOM_KREDIT as $kolom) {
                // Kolom lama = TOTAL PERNAH DIBERIKAN (naik saja).
                if ($request->has($kolom)) {
                    $user->{$kolom} = $this->kreditAman($user, $kolom, $request->input($kolom));
                }

                // Angka pemakaian kumulatif dari client versi baru. Client
                // 2.2.1 tidak mengirimnya, jadi nilainya tetap 0 dan
                // perilakunya persis seperti sebelum perbaikan ini.
                $terpakai = $request->input('kredit_terpakai.'.$kolom);
                if ($terpakai !== null) {
                    $user->{$kolom.'_terpakai'} = $this->kreditAman(
                        $user, $kolom.'_terpakai', $terpakai, batasi: false
                    );
                }
            }
            $user->save();
            // ------------------------------------

            // 1. Simpan Data Tes
            if ($request->has('tests')) {
                foreach ($request->tests as $test) {
                    $name  = trim((string) ($test['test_name'] ?? ''));
                    $score = (int) ($test['score'] ?? -1);
                    $total = (int) ($test['total_questions'] ?? 0);

                    // Lewati baris yang mustahil. Tanpa ini, siapa pun bisa
                    // mengirim score 9999 dan menguasai papan peringkat.
                    //
                    // Sengaja 'continue', BUKAN throw/validate(): kalau satu
                    // baris rusak menggagalkan seluruh request, user kehilangan
                    // cadangan SELURUH riwayatnya, bukan cuma baris itu.
                    //
                    // Sengaja TANPA whitelist nama tes: kalau jenis tes baru
                    // ditambahkan di APK dan lupa didaftarkan di sini, hasilnya
                    // akan hilang diam-diam. Validasi angka sudah cukup.
                    if ($name === '' || mb_strlen($name) > 100) {
                        continue;
                    }
                    if ($score < 0 || $total < 1 || $total > 200 || $score > $total) {
                        continue;
                    }

                    $user->testResults()->updateOrCreate(
                        ['client_created_at' => $test['created_at'] ?? (string) time()],
                        [
                            'test_name' => $name,
                            'score' => $score,
                            'total_questions' => $total,
                            'ai_analysis' => $test['ai_analysis'] ?? null,
                        ]
                    );
                }
            }

            // Perbarui skor IQ terhitung untuk papan peringkat.
            // HANYA MEMBACA test_results dan menulis ke user_iq_scores --
            // tidak ada baris hasil tes yang tersentuh. Dibungkus try/catch
            // supaya kegagalan di sini tidak pernah menggagalkan backup data
            // user, yang jauh lebih penting daripada papan peringkat.
            try {
                UserIqScore::recomputeFor($user->id);
            } catch (\Throwable $e) {
                Log::warning('Gagal hitung ulang skor IQ: ' . $e->getMessage());
            }

            // 2. Simpan Data Chat
            if ($request->has('chats')) {
                foreach ($request->chats as $chat) {
                    $user->chatHistories()->updateOrCreate(
                        ['client_created_at' => $chat['timestamp'] ?? $chat['created_at'] ?? (string) time()],
                        [
                            'sender' => $chat['sender'],
                            'message' => $chat['message'],
                        ]
                    );
                }
            }

            return response()->json(['message' => 'Backup Data Sukses!'], 200);

        } catch (\Exception $e) {
            Log::error("Error Sinkronisasi Flutter: " . $e->getMessage());
            return response()->json(['error' => 'Gagal menyimpan: ' . $e->getMessage()], 500);
        }
    }

    // MENGIRIM DATA KE HP BARU SAAT LOGIN
    public function getUserData(Request $request)
    {
        $user = $request->user();

        $tests = $user->testResults()->orderBy('id', 'asc')->get()->map(function($t) {
            return [
                'test_name' => $t->test_name,
                'score' => $t->score,
                'total_questions' => $t->total_questions,
                'ai_analysis' => $t->ai_analysis,
            ];
        });

        $chats = $user->chatHistories()->orderBy('id', 'asc')->get()->map(function($c) {
            return [
                'sender' => $c->sender,
                'message' => $c->message,
            ];
        });

        return response()->json([
            'tests' => $tests,
            'chats' => $chats,
            // --- KOIN ---
            // Yang dikirim adalah SALDO (diberikan - terpakai), bukan total
            // pernah diberikan. Sebelum perbaikan ini yang dikirim adalah
            // nilai tertinggi yang pernah dimiliki, sehingga user bisa
            // memakai habis kreditnya lalu memulihkannya penuh lewat tombol
            // sinkronisasi di layar Profil, berulang kali.
            //
            // Bentuk ketiga kunci ini TIDAK BERUBAH, jadi client 2.2.1 tetap
            // membacanya seperti biasa.
            'wartegg_credits' => $this->saldo($user, 'wartegg_credits'),
            'eq_sq_credits' => $this->saldo($user, 'eq_sq_credits'),
            'kredit_iq_pro' => $this->saldo($user, 'kredit_iq_pro'),

            // Rincian untuk client versi baru, supaya penghitung
            // pemakaiannya ikut pulih saat pasang ulang. Kunci tambahan,
            // client lama mengabaikannya.
            'kredit_diberikan' => [
                'wartegg_credits' => (int) $user->wartegg_credits,
                'eq_sq_credits' => (int) $user->eq_sq_credits,
                'kredit_iq_pro' => (int) $user->kredit_iq_pro,
            ],
            'kredit_terpakai' => [
                'wartegg_credits' => (int) $user->wartegg_credits_terpakai,
                'eq_sq_credits' => (int) $user->eq_sq_credits_terpakai,
                'kredit_iq_pro' => (int) $user->kredit_iq_pro_terpakai,
            ],
        ], 200);
    }
    
    // FUNGSI BARU: MENGHAPUS CHAT DARI DATABASE SERVER
    public function clearChats(Request $request)
    {
        try {
            $user = $request->user();
            $user->chatHistories()->delete(); // Menghapus semua chat milik user ini
            return response()->json(['message' => 'Riwayat chat server berhasil dibersihkan!'], 200);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Gagal menghapus: ' . $e->getMessage()], 500);
        }
    }

    /**
     * Batasi kenaikan kredit yang dikirim client.
     *
     * MASALAHNYA: server tidak memverifikasi bukti pembelian ke Google,
     * jadi nilai kredit sepenuhnya berasal dari client. Sebelum ini satu
     * permintaan HTTP berisi kredit_iq_pro: 9999 langsung diterima apa
     * adanya -- pembelian dalam aplikasi bisa dilewati sepenuhnya.
     *
     * INI MITIGASI, BUKAN PERBAIKAN TUNTAS. Selama bukti pembelian tidak
     * diverifikasi ke Google Play Developer API, penyerang masih bisa
     * menaikkan kredit sedikit demi sedikit lewat banyak permintaan.
     * Yang berubah: dari sekali jalan tak terbatas menjadi lambat,
     * terbatas, dan tercatat di log sehingga bisa terdeteksi.
     *
     * Kredit TIDAK PERNAH diturunkan di sini, sama seperti perilaku lama --
     * menurunkannya akan merusak pemulihan kredit saat user ganti HP.
     */
    private function kreditAman($user, string $kolom, $dikirim, bool $batasi = true): int
    {
        $sekarang = (int) ($user->{$kolom} ?? 0);

        if (! is_numeric($dikirim)) {
            return $sekarang;
        }

        $diminta = (int) $dikirim;

        // Turun atau sama: pertahankan nilai server (perilaku lama).
        if ($diminta <= $sekarang) {
            return $sekarang;
        }

        // Pembatasan HANYA untuk kredit yang diberikan, karena di situlah
        // uang bisa hilang. Untuk penghitung PEMAKAIAN pembatasan justru
        // berbahaya: pemakaian yang tidak tercatat berarti kredit yang tidak
        // terpotong -- persis kebocoran yang sedang kita tutup. Lagi pula
        // tidak ada insentif memalsukan pemakaian ke atas, karena itu
        // mengurangi saldo sendiri.
        $batas = $batasi
            ? min($sekarang + self::KENAIKAN_MAKS_PER_SYNC, self::KREDIT_MAKS)
            : self::PEMAKAIAN_MAKS;

        $baru = min($diminta, $batas);

        if ($diminta > $baru) {
            Log::warning('Kenaikan kredit dipotong batas', [
                'user_id' => $user->id,
                'kolom' => $kolom,
                'sekarang' => $sekarang,
                'diminta' => $diminta,
                'diberikan' => $baru,
            ]);
        } else {
            // Dicatat supaya pola pembelian yang tidak wajar bisa ditelusuri.
            Log::info('Kredit naik', [
                'user_id' => $user->id,
                'kolom' => $kolom,
                'dari' => $sekarang,
                'ke' => $baru,
            ]);
        }

        return $baru;
    }

    /** Saldo = total pernah diberikan dikurangi total terpakai, minimum 0. */
    private function saldo($user, string $kolom): int
    {
        $diberikan = (int) ($user->{$kolom} ?? 0);
        $terpakai = (int) ($user->{$kolom.'_terpakai'} ?? 0);

        return max(0, $diberikan - $terpakai);
    }
}
